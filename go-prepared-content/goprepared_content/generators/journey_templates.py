from goprepared_content.generators.knowledge_seed import generate_all_templates


def generate_all() -> list[dict]:
    """All journey content templates derived from the knowledge catalog."""
    return generate_all_templates()
