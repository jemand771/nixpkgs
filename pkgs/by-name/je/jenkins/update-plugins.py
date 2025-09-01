#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3Packages.requests
import json
from pathlib import Path
import re
from typing import Any

import requests

match = re.search('version = "(.+)";', (Path(__file__).parent / "package.nix").read_text().strip())
assert match
version = match.group(1)
assert version
url = f"https://archives.jenkins.io/update-center/dynamic-stable-{version}/update-center.actual.json"
r = requests.get(url)
r.raise_for_status()
plugins: dict[str, dict[str, Any]] = {
    value["name"]: dict(
        dependencies=[
            dep["name"] for dep in value["dependencies"]
        ],
        **{
            k: value[k]
            for k in ("url", "sha256", "version")
        },
    )
    for value
    in r.json()["plugins"].values()
}
(Path(__file__).parent / "plugins.json").write_text(json.dumps(plugins, indent=2))
