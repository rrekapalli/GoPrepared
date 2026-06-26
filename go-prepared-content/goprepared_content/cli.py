import json
from datetime import datetime, timezone
from pathlib import Path

import typer
from rich import print

from goprepared_content.config import OUTPUT_DIR
from goprepared_content.generators.community_seeds import generate_community
from goprepared_content.generators.journey_templates import generate_all as generate_journeys
from goprepared_content.generators.knowledge_seed import (
    generate_categories,
    generate_knowledge,
    generate_trending,
)

app = typer.Typer(help="GoPrepared offline static content generator")


def _write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


@app.command()
def all() -> None:
    """Generate all static content seeds."""
    journeys = generate_journeys()
    for j in journeys:
        _write_json(OUTPUT_DIR / "journey-templates" / f"{j['templateKey']}.json", j)

    _write_json(OUTPUT_DIR / "knowledge" / "graph.json", generate_knowledge())
    _write_json(OUTPUT_DIR / "categories" / "catalog.json", generate_categories())
    _write_json(OUTPUT_DIR / "knowledge" / "trending.json", generate_trending())
    _write_json(OUTPUT_DIR / "community" / "featured.json", generate_community())

    manifest = {
        "version": "1.0.0",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "journeyTemplates": len(journeys),
    }
    _write_json(OUTPUT_DIR / "manifest.json", manifest)
    print(f"[green]Generated content in {OUTPUT_DIR}[/green]")


@app.command()
def validate() -> None:
    """Validate output files exist."""
    required = [
        OUTPUT_DIR / "manifest.json",
        OUTPUT_DIR / "journey-templates" / "travel-paris.json",
        OUTPUT_DIR / "knowledge" / "graph.json",
    ]
    missing = [p for p in required if not p.exists()]
    if missing:
        raise typer.Exit(code=1)
    print("[green]All required output files present.[/green]")


if __name__ == "__main__":
    app()
