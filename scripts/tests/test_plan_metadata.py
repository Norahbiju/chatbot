import json
import subprocess
import sys
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CREATE = ROOT / "scripts/create_plan_metadata.py"
VERIFY = ROOT / "scripts/verify_plan_metadata.py"


class MetadataTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        self.plan = self.dir / "tfplan"
        self.lock = self.dir / ".terraform.lock.hcl"
        self.meta = self.dir / "metadata.json"
        self.plan.write_text("plan", encoding="utf-8")
        self.lock.write_text("lock", encoding="utf-8")

    def tearDown(self):
        self.tmp.cleanup()

    def create(self, **overrides):
        args = {
            "--output": str(self.meta),
            "--plan-file": str(self.plan),
            "--lockfile": str(self.lock),
            "--applyable": "true",
            "--event": "workflow_dispatch",
            "--action": "plan",
            "--repository": "owner/repo",
            "--workflow-file": ".github/workflows/terraform-dispatch.yml",
            "--workflow-run-id": "123",
            "--stack": "infra",
            "--environment": "dev",
            "--commit-sha": "abc",
            "--head-branch": "main",
            "--default-branch": "main",
            "--terraform-version": "1.15.1",
            "--state-key": "bedrock-rag/dev/terraform.tfstate",
        }
        args.update(overrides)
        flat = []
        for key, value in args.items():
            flat.extend([key, value])
        subprocess.run([sys.executable, str(CREATE), *flat], check=True)

    def verify(self, **overrides):
        args = {
            "--metadata": str(self.meta),
            "--plan-file": str(self.plan),
            "--lockfile": str(self.lock),
            "--repository": "owner/repo",
            "--workflow-file": ".github/workflows/terraform-dispatch.yml",
            "--workflow-run-id": "123",
            "--stack": "infra",
            "--environment": "dev",
            "--state-key": "bedrock-rag/dev/terraform.tfstate",
            "--default-branch": "main",
        }
        args.update(overrides)
        flat = []
        for key, value in args.items():
            flat.extend([key, value])
        return subprocess.run([sys.executable, str(VERIFY), *flat], text=True, capture_output=True)

    def test_valid_infra_metadata(self):
        self.create()
        self.assertEqual(self.verify().returncode, 0)

    def test_wrong_stack(self):
        self.create()
        self.assertNotEqual(self.verify(**{"--stack": "other"}).returncode, 0)

    def test_wrong_environment(self):
        self.create()
        self.assertNotEqual(self.verify(**{"--environment": "prod"}).returncode, 0)

    def test_wrong_run_id(self):
        self.create()
        self.assertNotEqual(self.verify(**{"--workflow-run-id": "999"}).returncode, 0)

    def test_wrong_repository(self):
        self.create()
        self.assertNotEqual(self.verify(**{"--repository": "other/repo"}).returncode, 0)

    def test_wrong_plan_sha(self):
        self.create()
        self.plan.write_text("changed", encoding="utf-8")
        self.assertNotEqual(self.verify().returncode, 0)

    def test_expired_artifact(self):
        self.create()
        data = json.loads(self.meta.read_text(encoding="utf-8"))
        data["expiresAt"] = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat().replace("+00:00", "Z")
        self.meta.write_text(json.dumps(data), encoding="utf-8")
        self.assertNotEqual(self.verify().returncode, 0)

    def test_non_applyable_artifact(self):
        self.create(**{"--applyable": "false"})
        self.assertNotEqual(self.verify().returncode, 0)

    def test_pull_request_artifact(self):
        self.create(**{"--event": "pull_request"})
        self.assertNotEqual(self.verify().returncode, 0)

    def test_incorrect_lockfile_digest(self):
        self.create()
        self.lock.write_text("changed", encoding="utf-8")
        self.assertNotEqual(self.verify().returncode, 0)


if __name__ == "__main__":
    unittest.main()
