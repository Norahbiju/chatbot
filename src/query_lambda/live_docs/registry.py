import json
from typing import Any, Dict, List


def load_registry(ssm_client: Any, parameter_name: str) -> Dict[str, Any]:
    if not parameter_name:
        return {"version": 1, "sources": []}
    response = ssm_client.get_parameter(Name=parameter_name, WithDecryption=True)
    value = response.get("Parameter", {}).get("Value", "{}")
    registry = json.loads(value)
    if not isinstance(registry, dict):
        raise ValueError("Live documentation registry must be a JSON object.")
    sources = registry.get("sources", [])
    if not isinstance(sources, list):
        raise ValueError("Live documentation registry sources must be a list.")
    return registry


def enabled_sources(registry: Dict[str, Any]) -> List[Dict[str, Any]]:
    sources = []
    for source in registry.get("sources", []):
        if isinstance(source, dict) and source.get("enabled") is True:
            sources.append(source)
    return sources
