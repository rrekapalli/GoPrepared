from goprepared_content.schemas.ai import (
    KnowledgeNode,
    KnowledgeEdge,
    NodeType,
    RelationshipType,
)


def generate_knowledge() -> dict:
    nodes = [
        KnowledgeNode(nodeType=NodeType.JOURNEY_TYPE, name="Travel", description="Travel preparations"),
        KnowledgeNode(nodeType=NodeType.JOURNEY_SUBTYPE, name="Vacation", description="Leisure travel"),
        KnowledgeNode(nodeType=NodeType.LOCATION, name="Bali", description="Indonesia island destination"),
        KnowledgeNode(nodeType=NodeType.TOPIC, name="Visa", description="Entry and visa requirements"),
        KnowledgeNode(nodeType=NodeType.JOURNEY_TYPE, name="Sports", description="Athletic events"),
        KnowledgeNode(nodeType=NodeType.JOURNEY_SUBTYPE, name="Marathon", description="Long-distance running"),
        KnowledgeNode(nodeType=NodeType.JOURNEY_TYPE, name="Health", description="Medical and wellness"),
        KnowledgeNode(nodeType=NodeType.JOURNEY_TYPE, name="Education", description="Exams and learning"),
        KnowledgeNode(nodeType=NodeType.JOURNEY_TYPE, name="Career", description="Professional milestones"),
        KnowledgeNode(nodeType=NodeType.JOURNEY_TYPE, name="Finance", description="Financial preparation"),
    ]
    edges = [
        KnowledgeEdge(sourceName="Travel", targetName="Vacation", relationshipType=RelationshipType.HAS_SUBTYPE),
        KnowledgeEdge(sourceName="Vacation", targetName="Bali", relationshipType=RelationshipType.LOCATED_IN),
        KnowledgeEdge(sourceName="Bali", targetName="Visa", relationshipType=RelationshipType.REQUIRES),
        KnowledgeEdge(sourceName="Sports", targetName="Marathon", relationshipType=RelationshipType.HAS_SUBTYPE),
    ]
    return {
        "nodes": [n.model_dump() for n in nodes],
        "edges": [e.model_dump() for e in edges],
    }


def generate_categories() -> list[dict]:
    return [
        {"name": "Travel", "icon": "airplane", "journeyCount": 128},
        {"name": "Sports", "icon": "soccer", "journeyCount": 64},
        {"name": "Education", "icon": "graduation", "journeyCount": 96},
        {"name": "Career", "icon": "briefcase", "journeyCount": 42},
        {"name": "Finance", "icon": "bank", "journeyCount": 38},
        {"name": "Health", "icon": "heart", "journeyCount": 55},
    ]


def generate_trending() -> list[dict]:
    return [
        {"rank": 1, "title": "Marathon Training", "preparingCount": 8400},
        {"rank": 2, "title": "Schengen Visa", "preparingCount": 6200},
        {"rank": 3, "title": "Stock Market Basics", "preparingCount": 5100},
    ]
