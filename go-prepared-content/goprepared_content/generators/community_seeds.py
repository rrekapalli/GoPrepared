from goprepared_content.schemas.ai import CommunityInsight, InsightType, Severity


def generate_community() -> list[dict]:
    insights = [
        CommunityInsight(
            insightType=InsightType.TIP,
            title="Local SIM cards are 50% cheaper outside the airport",
            content="Buy a local SIM card from a convenience store in the city rather than at arrivals.",
            journeyContext="BALI VACATION",
        ),
        CommunityInsight(
            insightType=InsightType.WARNING,
            title="Temple dress codes",
            content="Sarongs are required at Uluwatu and other major temples. Rent on-site costs 3x more.",
            journeyContext="BALI VACATION",
            severity=Severity.SEVERE,
        ),
        CommunityInsight(
            insightType=InsightType.EXPERIENCE,
            title="Sunrise trek at Mount Batur",
            content="Book the day before — morning slots fill quickly during peak season.",
            journeyContext="BALI VACATION",
        ),
    ]
    return [i.model_dump() for i in insights]
