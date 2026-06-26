from goprepared_content.schemas.ai import (
    JourneyClassification,
    PreparationCard,
    CardDetail,
    CurrencyInfo,
    EmergencyContact,
)


def bali_vacation_template() -> dict:
    classification = JourneyClassification(
        journeyType="Travel",
        journeySubtype="Vacation",
        activity="Vacation",
        location="Bali",
        title="Vacation to Bali",
        confidence=0.95,
    )
    cards = [
        PreparationCard(
            title="Preparation Checklist",
            summary="Essential items for tropical humidity, beach days, and temple visits.",
            category="Checklist",
            icon="checklist",
            displayOrder=0,
        ),
        PreparationCard(
            title="Travel Info",
            summary="Local customs, currency, weather, and emergency contacts for Bali.",
            category="Travel",
            icon="info",
            displayOrder=1,
            detail=CardDetail(
                destinationLabel="Bali, Indonesia",
                dos=["Dress modestly at temples", "Use both hands for giving/receiving"],
                donts=["Don't touch people's heads", "Don't use your left hand for eating"],
                currency=CurrencyInfo(
                    name="Indonesian Rupiah",
                    code="IDR",
                    exchangeRateNote="1 USD ≈ 15,500 IDR",
                ),
                weather="Tropical climate. High 80s°F (27-32°C). Humid.",
                emergencyContacts=[
                    EmergencyContact(label="Police", number="110"),
                    EmergencyContact(label="Ambulance", number="118"),
                ],
            ),
        ),
        PreparationCard(
            title="Visa Requirements",
            summary="Entry requirements and visa-on-arrival details for Indonesia.",
            category="Documents",
            icon="visa",
            displayOrder=2,
        ),
        PreparationCard(
            title="Weather Insights",
            summary="Seasonal patterns and packing guidance for tropical humidity.",
            category="Weather",
            icon="weather",
            displayOrder=3,
        ),
        PreparationCard(
            title="Packing",
            summary="Clothing and gear for beaches, temples, and jungle excursions.",
            category="Packing",
            icon="packing",
            displayOrder=4,
        ),
        PreparationCard(
            title="Safety Tips",
            summary="Health, transport, and personal safety recommendations.",
            category="Safety",
            icon="safety",
            displayOrder=5,
        ),
        PreparationCard(
            title="Transportation",
            summary="Getting around Bali — taxis, scooters, and airport transfers.",
            category="Transport",
            icon="transport",
            displayOrder=6,
        ),
        PreparationCard(
            title="Temple Etiquette",
            summary="Dress codes, offerings, and respectful behavior at sacred sites.",
            category="Culture",
            icon="temple",
            displayOrder=7,
        ),
    ]
    return {
        "templateKey": "bali-vacation",
        "classification": classification.model_dump(),
        "cards": [c.model_dump() for c in cards],
    }


def vizag_10k_template() -> dict:
    classification = JourneyClassification(
        journeyType="Sports",
        journeySubtype="10K Run",
        activity="Running",
        location="Vizag",
        title="Vizag 10K Run",
    )
    cards = [
        PreparationCard(
            title="Training Plan",
            summary="8-week build-up schedule for a coastal 10K race.",
            category="Training",
            icon="running",
            displayOrder=0,
        ),
        PreparationCard(
            title="Race Day Checklist",
            summary="Bib, timing chip, hydration, and warm-up essentials.",
            category="Checklist",
            icon="checklist",
            displayOrder=1,
        ),
        PreparationCard(
            title="Nutrition",
            summary="Pre-race meals and hydration strategy for humid conditions.",
            category="Health",
            icon="nutrition",
            displayOrder=2,
        ),
    ]
    return {
        "templateKey": "vizag-10k",
        "classification": classification.model_dump(),
        "cards": [c.model_dump() for c in cards],
    }


def angiogram_template() -> dict:
    classification = JourneyClassification(
        journeyType="Health",
        journeySubtype="Medical Procedure",
        activity="Angiogram",
        location="",
        title="Going for an Angiogram",
    )
    cards = [
        PreparationCard(
            title="Pre-Procedure Instructions",
            summary="Fasting, medication adjustments, and what to bring.",
            category="Health",
            icon="medical",
            displayOrder=0,
        ),
        PreparationCard(
            title="Recovery Plan",
            summary="Post-procedure care, activity restrictions, and follow-up.",
            category="Recovery",
            icon="recovery",
            displayOrder=1,
        ),
    ]
    return {
        "templateKey": "angiogram",
        "classification": classification.model_dump(),
        "cards": [c.model_dump() for c in cards],
    }


def generate_all() -> list[dict]:
    return [bali_vacation_template(), vizag_10k_template(), angiogram_template()]
