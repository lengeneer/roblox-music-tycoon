#!/usr/bin/env python3
"""Baut MusikTycoon.rbxlx aus den Skripten in src/.

Aufruf:  python3 build.py
Danach MusikTycoon.rbxlx in Roblox Studio öffnen (Datei > Öffnen).
"""
from pathlib import Path

ROOT = Path(__file__).parent
server = (ROOT / "src/server/MusikTycoonServer.server.lua").read_text(encoding="utf-8")
client = (ROOT / "src/client/MusikTycoonClient.client.lua").read_text(encoding="utf-8")

for name, src in (("Server", server), ("Client", client)):
    if "]]>" in src:
        raise SystemExit(f"{name}-Skript enthält ']]>' – das bricht CDATA.")


def script(cls, ref, name, src):
    return (
        f'<Item class="{cls}" referent="{ref}"><Properties>'
        f'<string name="Name">{name}</string>'
        f'<ProtectedString name="Source"><![CDATA[{src}]]></ProtectedString>'
        f"</Properties></Item>\n"
    )


xml = (
    '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
    'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n'
    '<Item class="Workspace" referent="RBX0"><Properties><string name="Name">Workspace</string></Properties></Item>\n'
    '<Item class="ServerScriptService" referent="RBX1"><Properties><string name="Name">ServerScriptService</string></Properties>\n'
    + script("Script", "RBX2", "MusikTycoonServer", server)
    + "</Item>\n"
    '<Item class="StarterPlayer" referent="RBX3"><Properties><string name="Name">StarterPlayer</string></Properties>\n'
    '<Item class="StarterPlayerScripts" referent="RBX4"><Properties><string name="Name">StarterPlayerScripts</string></Properties>\n'
    + script("LocalScript", "RBX5", "MusikTycoonClient", client)
    + "</Item></Item>\n"
    "</roblox>\n"
)

out = ROOT / "MusikTycoon.rbxlx"
out.write_text(xml, encoding="utf-8")
print(f"OK -> {out.name} ({len(xml) // 1024} KB)")
