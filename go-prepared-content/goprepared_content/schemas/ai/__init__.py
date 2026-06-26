"""Pydantic models aligned with contracts/ai/*.schema.json"""

from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field


class JourneyClassification(BaseModel):
    journeyType: str
    journeySubtype: str
    activity: str
    location: str = ""
    title: str
    confidence: Optional[float] = None


class EmergencyContact(BaseModel):
    label: str
    number: str


class CurrencyInfo(BaseModel):
    name: str = ""
    code: str = ""
    exchangeRateNote: str = ""


class CardSection(BaseModel):
    title: str
    body: str


class CardDetail(BaseModel):
    heroImageUrl: Optional[str] = None
    destinationLabel: Optional[str] = None
    dos: list[str] = Field(default_factory=list)
    donts: list[str] = Field(default_factory=list)
    currency: Optional[CurrencyInfo] = None
    weather: Optional[str] = None
    emergencyContacts: list[EmergencyContact] = Field(default_factory=list)
    sections: list[CardSection] = Field(default_factory=list)


class PreparationCard(BaseModel):
    title: str
    summary: str
    category: str
    icon: str
    displayOrder: int
    detail: Optional[CardDetail] = None


class ChecklistItem(BaseModel):
    title: str
    description: str = ""
    category: str
    displayOrder: int
    completed: bool = False


class NodeType(str, Enum):
    JOURNEY_TYPE = "JOURNEY_TYPE"
    JOURNEY_SUBTYPE = "JOURNEY_SUBTYPE"
    ACTIVITY = "ACTIVITY"
    LOCATION = "LOCATION"
    TOPIC = "TOPIC"


class KnowledgeNode(BaseModel):
    nodeType: NodeType
    name: str
    description: str = ""
    metadata: dict[str, Any] = Field(default_factory=dict)


class RelationshipType(str, Enum):
    HAS_SUBTYPE = "HAS_SUBTYPE"
    HAS_ACTIVITY = "HAS_ACTIVITY"
    LOCATED_IN = "LOCATED_IN"
    RELATED_TO = "RELATED_TO"
    REQUIRES = "REQUIRES"


class KnowledgeEdge(BaseModel):
    sourceName: str
    targetName: str
    relationshipType: RelationshipType
    sourceType: Optional[NodeType] = None
    targetType: Optional[NodeType] = None


class InsightType(str, Enum):
    TIP = "TIP"
    WARNING = "WARNING"
    EXPERIENCE = "EXPERIENCE"
    UPDATE = "UPDATE"


class Severity(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    SEVERE = "SEVERE"


class CommunityInsight(BaseModel):
    insightType: InsightType
    title: str
    content: str
    journeyContext: Optional[str] = None
    severity: Optional[Severity] = None
