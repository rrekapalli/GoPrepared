"""Build knowledge graph and journey templates from the curated catalog."""

from __future__ import annotations

from goprepared_content.data.knowledge_catalog import (
    EDUCATION_TOPICS,
    HEALTH_TOPICS,
    SPORTS_ACTIVITIES,
    TRAVEL_DESTINATIONS,
)
from goprepared_content.schemas.ai import (
    CardDetail,
    CardSection,
    ChecklistItem,
    JourneyClassification,
    KnowledgeEdge,
    KnowledgeNode,
    NodeType,
    PreparationCard,
    RelationshipType,
)


def _node(node_type: NodeType, name: str, description: str, **metadata) -> KnowledgeNode:
    return KnowledgeNode(
        nodeType=node_type,
        name=name,
        description=description,
        metadata=metadata,
    )


def generate_knowledge() -> dict:
    nodes: list[KnowledgeNode] = []
    edges: list[KnowledgeEdge] = []

    # Journey type hubs
    type_defs = [
        ("Travel", "International and domestic trip preparation"),
        ("Sports", "Athletic events and fitness goals"),
        ("Health", "Medical procedures, surgery, and diagnostics"),
        ("Education", "Exams, certifications, and academic milestones"),
        ("Career", "Professional transitions and licensing"),
        ("Finance", "Personal finance and investing preparation"),
    ]
    for name, desc in type_defs:
        nodes.append(_node(NodeType.JOURNEY_TYPE, name, desc, category=name))

    # Subtypes
    subtypes = [
        ("Travel", "Vacation", "Leisure and holiday travel"),
        ("Travel", "Business Travel", "Work-related trips and conferences"),
        ("Sports", "Marathon", "Long-distance running events"),
        ("Sports", "10K Run", "Short road races and fun runs"),
        ("Health", "Medical Procedure", "Outpatient and inpatient procedures"),
        ("Health", "Surgery", "Operative care and recovery"),
        ("Health", "Diagnostic Test", "Imaging and screening exams"),
        ("Education", "Exam", "Standardized and professional exams"),
        ("Education", "Certification", "Industry credentials and licenses"),
    ]
    for parent, name, desc in subtypes:
        nodes.append(_node(NodeType.JOURNEY_SUBTYPE, name, desc, category=parent))
        edges.append(
            KnowledgeEdge(
                sourceName=parent,
                targetName=name,
                relationshipType=RelationshipType.HAS_SUBTYPE,
                sourceType=NodeType.JOURNEY_TYPE,
                targetType=NodeType.JOURNEY_SUBTYPE,
            )
        )

    # Travel destinations
    for dest in TRAVEL_DESTINATIONS:
        nodes.append(
            _node(
                NodeType.LOCATION,
                dest["name"],
                dest["description"],
                category="Travel",
                country=dest["country"],
                overview=dest["overview"],
                bestSeason=dest["bestSeason"],
                prepDays=dest["prepDays"],
                topics=dest["topics"],
            )
        )
        edges.append(
            KnowledgeEdge(
                sourceName="Vacation",
                targetName=dest["name"],
                relationshipType=RelationshipType.LOCATED_IN,
                sourceType=NodeType.JOURNEY_SUBTYPE,
                targetType=NodeType.LOCATION,
            )
        )

    # Sports activities
    for sport in SPORTS_ACTIVITIES:
        nodes.append(
            _node(
                NodeType.ACTIVITY,
                sport["name"],
                sport["description"],
                category="Sports",
                overview=sport["overview"],
                prepWeeks=sport["prepWeeks"],
                topics=sport["topics"],
                subtype=sport["subtype"],
            )
        )
        edges.append(
            KnowledgeEdge(
                sourceName="Sports",
                targetName=sport["name"],
                relationshipType=RelationshipType.HAS_ACTIVITY,
                sourceType=NodeType.JOURNEY_TYPE,
                targetType=NodeType.ACTIVITY,
            )
        )
        edges.append(
            KnowledgeEdge(
                sourceName=sport["subtype"],
                targetName=sport["name"],
                relationshipType=RelationshipType.RELATED_TO,
                sourceType=NodeType.JOURNEY_SUBTYPE,
                targetType=NodeType.ACTIVITY,
            )
        )

    # Health topics
    for topic in HEALTH_TOPICS:
        nodes.append(
            _node(
                NodeType.TOPIC,
                topic["name"],
                topic["description"],
                category="Health",
                overview=topic["overview"],
                prepDays=topic["prepDays"],
                topics=topic["topics"],
                subtype=topic["subtype"],
            )
        )
        edges.append(
            KnowledgeEdge(
                sourceName=topic["subtype"],
                targetName=topic["name"],
                relationshipType=RelationshipType.REQUIRES,
                sourceType=NodeType.JOURNEY_SUBTYPE,
                targetType=NodeType.TOPIC,
            )
        )

    # Education topics
    for topic in EDUCATION_TOPICS:
        nodes.append(
            _node(
                NodeType.TOPIC,
                topic["name"],
                topic["description"],
                category="Education",
                overview=topic["overview"],
                prepWeeks=topic["prepWeeks"],
                topics=topic["topics"],
                subtype=topic["subtype"],
            )
        )
        edges.append(
            KnowledgeEdge(
                sourceName=topic["subtype"],
                targetName=topic["name"],
                relationshipType=RelationshipType.REQUIRES,
                sourceType=NodeType.JOURNEY_SUBTYPE,
                targetType=NodeType.TOPIC,
            )
        )

    # Cross-cutting topics
    cross_topics = [
        ("Travel", "Visa", "Entry visas, e-visas, and passport validity"),
        ("Travel", "Travel Insurance", "Medical evacuation and trip cancellation cover"),
        ("Finance", "Emergency Fund", "3–6 months expenses in liquid savings"),
        ("Finance", "Tax Filing", "Annual income tax preparation and deductions"),
        ("Career", "Job Interview", "Behavioral and technical interview preparation"),
        ("Career", "Resume Refresh", "ATS-friendly resume and LinkedIn alignment"),
    ]
    for parent, name, desc in cross_topics:
        nodes.append(_node(NodeType.TOPIC, name, desc, category=parent))
        edges.append(
            KnowledgeEdge(
                sourceName=parent,
                targetName=name,
                relationshipType=RelationshipType.REQUIRES,
                sourceType=NodeType.JOURNEY_TYPE,
                targetType=NodeType.TOPIC,
            )
        )

    return {
        "nodes": [n.model_dump() for n in nodes],
        "edges": [e.model_dump() for e in edges],
    }


def _slug(text: str) -> str:
    return (
        text.lower()
        .replace(" & ", "-")
        .replace(" ", "-")
        .replace("'", "")
        .replace(",", "")
    )


def _travel_template(dest: dict) -> dict:
    name = dest["name"]
    country = dest["country"]
    key = f"travel-{_slug(name)}"
    classification = JourneyClassification(
        journeyType="Travel",
        journeySubtype="Vacation",
        activity="Vacation",
        location=name,
        title=f"Vacation to {name}",
        confidence=0.92,
    )
    cards = [
        PreparationCard(
            title="Preparation Checklist",
            summary=f"Packing, documents, and bookings for {name}, {country}.",
            category="Checklist",
            icon="checklist",
            displayOrder=0,
        ),
        PreparationCard(
            title="Travel Info",
            summary=f"Local customs, transport, and essentials for {name}.",
            category="Travel Info",
            icon="info",
            displayOrder=1,
            detail=CardDetail(
                destinationLabel=f"{name}, {country}",
                dos=[f"Research {dest['bestSeason']} weather before packing", "Save embassy/consulate contacts offline"],
                donts=["Don't carry all cash in one place", "Don't ignore local dress codes at religious sites"],
                weather=f"Best season: {dest['bestSeason']}.",
                sections=[
                    CardSection(title="Overview", body=dest["overview"]),
                    CardSection(title="Key topics", body=", ".join(dest["topics"])),
                ],
            ),
        ),
        PreparationCard(
            title="Documents & Visa",
            summary="Passport validity, visas, and travel insurance requirements.",
            category="Documents",
            icon="document",
            displayOrder=2,
        ),
        PreparationCard(
            title="Packing Guide",
            summary=f"Season-appropriate clothing and gear for {name}.",
            category="Packing",
            icon="packing",
            displayOrder=3,
        ),
        PreparationCard(
            title="Safety Tips",
            summary="Health, scams, and emergency contacts.",
            category="Safety",
            icon="safety",
            displayOrder=4,
        ),
    ]
    checklist = [
        ChecklistItem(title="Verify passport expiry (6+ months)", category="Documents", displayOrder=0),
        ChecklistItem(title="Book flights and accommodation", category="Booking", displayOrder=1),
        ChecklistItem(title="Purchase travel insurance", category="Documents", displayOrder=2),
        ChecklistItem(title=f"Research {name} transport options", category="Planning", displayOrder=3),
    ]
    return {
        "templateKey": key,
        "classification": classification.model_dump(),
        "cards": [c.model_dump(exclude_none=True) for c in cards],
        "checklist": [c.model_dump() for c in checklist],
    }


def _sports_template(sport: dict) -> dict:
    name = sport["name"]
    key = f"sports-{_slug(name)}"
    classification = JourneyClassification(
        journeyType="Sports",
        journeySubtype=sport["subtype"],
        activity=name,
        location="",
        title=f"Preparing for {name}",
        confidence=0.9,
    )
    cards = [
        PreparationCard(
            title="Training Plan",
            summary=sport["overview"][:120] + "...",
            category="Training",
            icon="running",
            displayOrder=0,
            detail=CardDetail(
                sections=[
                    CardSection(title="Overview", body=sport["overview"]),
                    CardSection(title="Focus areas", body=", ".join(sport["topics"])),
                ]
            ),
        ),
        PreparationCard(
            title="Race Day Checklist",
            summary="Gear, nutrition, and warm-up essentials.",
            category="Checklist",
            icon="checklist",
            displayOrder=1,
        ),
        PreparationCard(
            title="Nutrition & Hydration",
            summary="Fuel strategy before and during the event.",
            category="Health",
            icon="nutrition",
            displayOrder=2,
        ),
        PreparationCard(
            title="Recovery Plan",
            summary="Post-event rest, stretching, and injury prevention.",
            category="Recovery",
            icon="recovery",
            displayOrder=3,
        ),
    ]
    return {
        "templateKey": key,
        "classification": classification.model_dump(),
        "cards": [c.model_dump(exclude_none=True) for c in cards],
    }


def _health_template(topic: dict) -> dict:
    name = topic["name"]
    key = f"health-{_slug(name)}"
    classification = JourneyClassification(
        journeyType="Health",
        journeySubtype=topic["subtype"],
        activity=name,
        location="",
        title=f"Preparing for {name}",
        confidence=0.93,
    )
    cards = [
        PreparationCard(
            title="Pre-Procedure Instructions",
            summary=topic["overview"][:140] + "...",
            category="Health",
            icon="medical",
            displayOrder=0,
            detail=CardDetail(
                sections=[
                    CardSection(title="Overview", body=topic["overview"]),
                    CardSection(title="Key preparations", body=", ".join(topic["topics"])),
                ]
            ),
        ),
        PreparationCard(
            title="Medication Review",
            summary="Blood thinners, fasting, and prescription adjustments.",
            category="Documents",
            icon="document",
            displayOrder=1,
        ),
        PreparationCard(
            title="Recovery Plan",
            summary="Post-procedure care, restrictions, and follow-up.",
            category="Recovery",
            icon="recovery",
            displayOrder=2,
        ),
    ]
    return {
        "templateKey": key,
        "classification": classification.model_dump(),
        "cards": [c.model_dump(exclude_none=True) for c in cards],
    }


def _education_template(topic: dict) -> dict:
    name = topic["name"]
    key = f"education-{_slug(name)}"
    classification = JourneyClassification(
        journeyType="Education",
        journeySubtype=topic["subtype"],
        activity=name,
        location="",
        title=f"Preparing for {name}",
        confidence=0.91,
    )
    cards = [
        PreparationCard(
            title="Study Schedule",
            summary=topic["overview"][:140] + "...",
            category="Education",
            icon="school",
            displayOrder=0,
            detail=CardDetail(
                sections=[
                    CardSection(title="Overview", body=topic["overview"]),
                    CardSection(title="Study focus", body=", ".join(topic["topics"])),
                ]
            ),
        ),
        PreparationCard(
            title="Resources & Materials",
            summary="Books, practice exams, and official guides.",
            category="Documents",
            icon="document",
            displayOrder=1,
        ),
        PreparationCard(
            title="Test Day Logistics",
            summary="ID requirements, timing, and what to bring.",
            category="Checklist",
            icon="checklist",
            displayOrder=2,
        ),
    ]
    return {
        "templateKey": key,
        "classification": classification.model_dump(),
        "cards": [c.model_dump(exclude_none=True) for c in cards],
    }


def generate_all_templates() -> list[dict]:
    templates = []
    templates.extend(_travel_template(d) for d in TRAVEL_DESTINATIONS)
    templates.extend(_sports_template(s) for s in SPORTS_ACTIVITIES)
    templates.extend(_health_template(h) for h in HEALTH_TOPICS)
    templates.extend(_education_template(e) for e in EDUCATION_TOPICS)
    return templates


def generate_categories() -> list[dict]:
    return [
        {"name": "Travel", "icon": "airplane", "journeyCount": len(TRAVEL_DESTINATIONS) * 40},
        {"name": "Sports", "icon": "soccer", "journeyCount": len(SPORTS_ACTIVITIES) * 35},
        {"name": "Education", "icon": "graduation", "journeyCount": len(EDUCATION_TOPICS) * 30},
        {"name": "Health", "icon": "heart", "journeyCount": len(HEALTH_TOPICS) * 28},
        {"name": "Career", "icon": "briefcase", "journeyCount": 42},
        {"name": "Finance", "icon": "bank", "journeyCount": 38},
    ]


def generate_trending() -> list[dict]:
    return [
        {"rank": 1, "title": "Marathon Training", "preparingCount": 8400},
        {"rank": 2, "title": "Vacation to Tokyo", "preparingCount": 7200},
        {"rank": 3, "title": "GRE Exam", "preparingCount": 6100},
        {"rank": 4, "title": "Colonoscopy Prep", "preparingCount": 5400},
        {"rank": 5, "title": "Vacation to Paris", "preparingCount": 5100},
    ]
