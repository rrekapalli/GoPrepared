from goprepared_content.generators.journey_templates import generate_all
from goprepared_content.generators.knowledge_seed import generate_knowledge


def test_journey_templates_have_cards():
    templates = generate_all()
    assert len(templates) >= 90
    for t in templates:
        assert "classification" in t
        assert len(t["cards"]) >= 2


def test_knowledge_graph_size():
    graph = generate_knowledge()
    assert len(graph["nodes"]) >= 100
    assert len(graph["edges"]) >= 100
