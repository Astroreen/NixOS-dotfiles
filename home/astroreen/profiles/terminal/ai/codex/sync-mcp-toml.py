import json
import sys
from pathlib import Path
import tomlkit

cfg_path = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
payload_path = Path(sys.argv[3])

desired = json.loads(payload_path.read_text(encoding="utf-8"))
previous = (
    {
        line.strip()
        for line in manifest_path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    }
    if manifest_path.exists()
    else set()
)

doc = (
    tomlkit.parse(cfg_path.read_text(encoding="utf-8"))
    if cfg_path.exists()
    else tomlkit.document()
)
mcp_servers = doc.get("mcp_servers")
if mcp_servers is None:
    mcp_servers = tomlkit.table(is_super_table=True)
    doc["mcp_servers"] = mcp_servers

# Drop entries previously owned by Nix that are no longer enabled.
for old_name in sorted(previous - set(desired.keys())):
    if old_name in mcp_servers:
        del mcp_servers[old_name]

# Never overwrite pre-existing user-managed entries that Nix never owned.
is_inline = isinstance(mcp_servers, tomlkit.items.InlineTable)
make_tbl = tomlkit.inline_table if is_inline else tomlkit.table
managed_now: list[str] = []
for name in sorted(desired.keys()):
    if name in mcp_servers and name not in previous:
        continue
    spec = desired[name]
    tbl = make_tbl()
    if "url" in spec:
        tbl["url"] = spec["url"]
        if spec.get("http_headers"):
            hdrs = make_tbl()
            for hk, hv in sorted(spec["http_headers"].items()):
                hdrs[hk] = hv
            tbl["http_headers"] = hdrs
    else:
        tbl["command"] = spec["command"]
        if spec.get("args"):
            tbl["args"] = list(spec["args"])
        if spec.get("env"):
            env_tbl = make_tbl()
            for ek, ev in sorted(spec["env"].items()):
                env_tbl[ek] = ev
            tbl["env"] = env_tbl
    if "tool_timeout_sec" in spec:
        tbl["tool_timeout_sec"] = spec["tool_timeout_sec"]
    mcp_servers[name] = tbl
    managed_now.append(name)

if len(mcp_servers) == 0 and "mcp_servers" in doc:
    del doc["mcp_servers"]

tmp_path = cfg_path.with_suffix(".toml.tmp")
tmp_path.write_text(tomlkit.dumps(doc), encoding="utf-8")
tmp_path.replace(cfg_path)

manifest_tmp = manifest_path.with_suffix(".tmp")
manifest_tmp.write_text(
    "\n".join(managed_now) + ("\n" if managed_now else ""),
    encoding="utf-8",
)
manifest_tmp.replace(manifest_path)
