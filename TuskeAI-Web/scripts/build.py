#!/usr/bin/env python3
from pathlib import Path
import shutil
import sys

STATIC_WORKER = """export default {
  async fetch(request, env) {
    if (!env || !env.ASSETS) {
      return new Response("Static assets binding is unavailable", { status: 500 });
    }

    const response = await env.ASSETS.fetch(request);
    if (response.status !== 404 || request.method !== "GET") {
      return response;
    }

    const url = new URL(request.url);
    url.pathname = "/index.html";
    return env.ASSETS.fetch(new Request(url, request));
  },
};
"""

root = Path(__file__).resolve().parents[1]
dist = root / "dist"
required = [
    root / "index.html",
    root / "styles.css",
    root / "script.js",
    root / "assets/tuske-hero.png",
    root / "assets/tuske-workshop.png",
    root / "assets/tuske-monogram.png",
    root / "assets/tuske-demo.m4v",
    root / "assets/tuske-touch.jpeg",
    root / "assets/tuske-road.jpeg",
    root / "assets/tuske-plan.jpeg",
    root / "assets/tuske-server.png",
]
missing = [str(path.relative_to(root)) for path in required if not path.exists()]
if missing:
    print("Missing required files: " + ", ".join(missing), file=sys.stderr)
    sys.exit(1)

if dist.exists():
    shutil.rmtree(dist)
dist.mkdir()
for name in ["index.html", "styles.css", "script.js"]:
    shutil.copy2(root / name, dist / name)
shutil.copytree(root / "assets", dist / "assets", ignore=shutil.ignore_patterns("tuske-demo.mov"))
server_dir = dist / "server"
server_dir.mkdir()
(server_dir / "index.js").write_text(STATIC_WORKER, encoding="utf-8")

html = (dist / "index.html").read_text(encoding="utf-8")
for needle in ['href="styles.css"', 'src="script.js"', 'assets/tuske-hero.png', 'assets/tuske-monogram.png', 'assets/tuske-demo.m4v']:
    if needle not in html:
        print(f"Build validation failed: {needle} not referenced", file=sys.stderr)
        sys.exit(1)
print(f"Built static site: {dist}")
