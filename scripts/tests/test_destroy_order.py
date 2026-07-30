import os
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/check_destroy_order.sh"


@unittest.skipIf(os.name == "nt", "requires bash")
class DestroyOrderTests(unittest.TestCase):
    def test_destroy_confirmation_valid(self):
        result = subprocess.run(
            ["bash", str(SCRIPT), "DESTROY"],
            env={**os.environ, "CHECK_STATE": "false"},
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0)

    def test_destroy_confirmation_invalid(self):
        result = subprocess.run(
            ["bash", str(SCRIPT), "destroy"],
            env={**os.environ, "CHECK_STATE": "false"},
            text=True,
            capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
