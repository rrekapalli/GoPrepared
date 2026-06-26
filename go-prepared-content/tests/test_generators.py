from goprepared_content.generators.journey_templates import generate_all


def test_journey_templates_have_cards():
    templates = generate_all()
    assert len(templates) >= 3
    for t in templates:
        assert "classification" in t
        assert len(t["cards"]) >= 2
