import '../models/ai_models.dart';
import '../../shared/widgets/community_journey_matcher.dart';

/// Sample journeys and cards for offline / API-unavailable demo (matches app mockups).
class DemoData {
  DemoData._();

  static bool isDemoJourney(int id) => id < 0;
  static bool isDemoCard(int id) => id < 0;

  static final sampleJourneys = [
    JourneyModel(
      id: -1,
      title: 'Bali Vacation',
      originalQuery: 'Packing list updated for tropical humidity and temple visits',
      status: 'ACTIVE',
      progressPercent: 40,
      createdAt: null,
      journeyType: 'Travel',
      journeySubtype: 'Vacation',
      location: 'Bali',
    ),
    JourneyModel(
      id: -2,
      title: 'Vizag 10K',
      originalQuery: 'Race day prep — hydration and pacing plan complete',
      status: 'ACTIVE',
      progressPercent: 100,
      journeyType: 'Sports',
      journeySubtype: 'Marathon',
      activity: '10K Run',
      location: 'Vizag',
    ),
    JourneyModel(
      id: -3,
      title: 'Angiogram',
      originalQuery: 'Pre-procedure fasting and medication checklist done',
      status: 'ACTIVE',
      progressPercent: 100,
      journeyType: 'Health',
      journeySubtype: 'Medical Procedure',
      location: 'Local hospital',
    ),
    JourneyModel(
      id: -4,
      title: 'GRE Exam',
      originalQuery: 'Study schedule and vocabulary drills in progress',
      status: 'DRAFT',
      progressPercent: 20,
      journeyType: 'Education',
      journeySubtype: 'Exam',
      location: 'Test center',
    ),
    JourneyModel(
      id: -5,
      title: 'First International Flight',
      originalQuery: 'Passport, visa, and airport navigation basics',
      status: 'DRAFT',
      progressPercent: 10,
      journeyType: 'Travel',
      journeySubtype: 'Business Travel',
      location: 'International',
    ),
  ];

  static DateTime get _baliDate => DateTime(2023, 10, 12);
  static DateTime get _vizagDate => DateTime(2023, 11, 5);
  static DateTime get _angiogramDate => DateTime(2024, 1, 18);
  static DateTime get _greDate => DateTime(2024, 3, 2);
  static DateTime get _flightDate => DateTime(2024, 5, 20);

  static List<JourneyModel> get journeysWithDates => [
        sampleJourneys[0].copyWith(createdAt: _baliDate),
        sampleJourneys[1].copyWith(createdAt: _vizagDate),
        sampleJourneys[2].copyWith(createdAt: _angiogramDate),
        sampleJourneys[3].copyWith(createdAt: _greDate),
        sampleJourneys[4].copyWith(createdAt: _flightDate),
      ];

  static final Map<String, dynamic> _baliTravelDetail = {
    'destinationLabel': 'Bali, Indonesia',
    'dos': [
      'Dress modestly at temples (sarong & sash)',
      'Use both hands when giving or receiving',
      'Drink bottled water and use sunscreen',
    ],
    'donts': [
      "Don't touch people's heads",
      "Don't use your left hand for eating",
      'Do not swim at unmarked beaches during monsoon',
    ],
    'currency': {
      'name': 'Indonesian Rupiah (IDR)',
      'code': 'IDR',
      'exchangeRateNote': '1 USD ≈ 15,500 IDR',
    },
    'weather': 'Tropical climate. High 80s°F (27–32°C). Humid.',
    'emergencyContacts': [
      {'label': 'Police', 'number': '110'},
      {'label': 'Ambulance', 'number': '118'},
    ],
  };

  static final List<CardModel> _baliCards = [
    CardModel(
      id: -101,
      title: 'Preparation Checklist',
      summary:
          'Essential items for tropical humidity, beach days, and temple visits. Includes custom packing list based on current weather.',
      category: 'Checklist',
      icon: 'checklist',
      displayOrder: 0,
      viewed: false,
    ),
    CardModel(
      id: -102,
      title: 'Travel Info',
      summary: 'Visa requirements, local customs, currency, and getting around Bali.',
      category: 'Travel Info',
      icon: 'info',
      displayOrder: 1,
      viewed: false,
      detail: _baliTravelDetail,
    ),
    CardModel(
      id: -103,
      title: 'Weather Insights',
      summary: 'Tropical climate patterns, monsoon timing, and what to pack for humidity.',
      category: 'Weather Insights',
      icon: 'weather',
      displayOrder: 2,
      viewed: false,
      detail: {
        'weather': 'Tropical climate. High 80s°F (27–32°C). Humid. Dry season Apr–Oct.',
      },
    ),
    CardModel(
      id: -104,
      title: 'Visa & Documents',
      summary: 'VOA eligibility, passport validity, and digital copies to carry.',
      category: 'Documents',
      icon: 'document',
      displayOrder: 3,
      viewed: false,
    ),
    CardModel(
      id: -105,
      title: 'Safety Tips',
      summary: 'Temple etiquette, scooter safety, and common tourist scams to avoid.',
      category: 'Safety',
      icon: 'safety',
      displayOrder: 4,
      viewed: false,
    ),
    CardModel(
      id: -106,
      title: 'Health & Vaccines',
      summary: 'Recommended vaccines, travel insurance, and clinic locations.',
      category: 'Health',
      icon: 'health',
      displayOrder: 5,
      viewed: false,
    ),
  ];

  static final List<CardModel> _vizagCards = [
    CardModel(
      id: -201,
      title: 'Race Day Plan',
      summary: 'Pacing strategy, hydration stations, and warm-up routine.',
      category: 'Sports',
      icon: 'run',
      displayOrder: 0,
      viewed: true,
    ),
    CardModel(
      id: -202,
      title: 'Training Checklist',
      summary: 'Final week taper, gear check, and carb loading schedule.',
      category: 'Checklist',
      icon: 'checklist',
      displayOrder: 1,
      viewed: true,
    ),
  ];

  static final List<CardModel> _healthCards = [
    CardModel(
      id: -301,
      title: 'Pre-Procedure Prep',
      summary: 'Fasting windows, medication adjustments, and what to bring.',
      category: 'Health',
      icon: 'health',
      displayOrder: 0,
      viewed: true,
    ),
  ];

  static final List<CardModel> _greCards = [
    CardModel(
      id: -401,
      title: 'Study Schedule',
      summary: '8-week plan covering quant, verbal, and mock tests.',
      category: 'Education',
      icon: 'school',
      displayOrder: 0,
      viewed: false,
    ),
    CardModel(
      id: -402,
      title: 'Test Day Logistics',
      summary: 'ID requirements, arrival time, and break strategy.',
      category: 'Documents',
      icon: 'document',
      displayOrder: 1,
      viewed: false,
    ),
  ];

  static final List<CardModel> _flightCards = [
    CardModel(
      id: -501,
      title: 'Airport Navigation',
      summary: 'Check-in, security, immigration, and layover tips.',
      category: 'Travel Info',
      icon: 'flight',
      displayOrder: 0,
      viewed: false,
    ),
  ];

  static final Map<int, List<CardModel>> _cardsByJourney = {
    -1: _baliCards,
    -2: _vizagCards,
    -3: _healthCards,
    -4: _greCards,
    -5: _flightCards,
  };

  static final Map<int, CardModel> _cardById = {
    for (final list in _cardsByJourney.values)
      for (final c in list) c.id: c,
  };

  static JourneyModel? journeyById(int id) {
    for (final j in journeysWithDates) {
      if (j.id == id) return j;
    }
    return null;
  }

  static List<CardModel> cardsForJourney(int journeyId) =>
      _cardsByJourney[journeyId] ?? [];

  static CardModel? cardById(int cardId) => _cardById[cardId];

  static final List<CommunityInsightModel> _allDemoInsights = [
    CommunityInsightModel(
      id: -1001,
      insightType: 'TIP',
      title: 'Local SIM cards are 50% cheaper outside the airport',
      content: 'Buy a local SIM card from a convenience store in the city rather than at arrivals.',
      journeyContext: 'TRAVEL|VACATION|BALI',
      votes: 126,
    ),
    CommunityInsightModel(
      id: -1002,
      insightType: 'WARNING',
      title: 'Temple dress codes',
      content: 'Sarongs are required at Uluwatu and other major temples. Rent on-site costs 3x more.',
      journeyContext: 'TRAVEL|VACATION|BALI',
      severity: 'SEVERE',
      votes: 98,
    ),
    CommunityInsightModel(
      id: -1003,
      insightType: 'EXPERIENCE',
      title: 'Sunrise trek at Mount Batur',
      content: 'Book the day before — morning slots fill quickly during peak season.',
      journeyContext: 'TRAVEL|VACATION|BALI',
      votes: 74,
    ),
    CommunityInsightModel(
      id: -1004,
      insightType: 'TIP',
      title: 'Start hydrating 48h before a coastal race',
      content: 'Humid air at Vizag and other coastal courses increases sweat loss. Begin electrolyte drinks two days before race day.',
      journeyContext: 'SPORTS|10K RUN|VIZAG',
      votes: 52,
    ),
    CommunityInsightModel(
      id: -1005,
      insightType: 'WARNING',
      title: 'Arrive early for bib pickup',
      content: 'Expo queues are long the morning before local 10K events. Pick up bib and timing chip the prior evening when possible.',
      journeyContext: 'SPORTS|10K RUN|VIZAG',
      votes: 38,
    ),
    CommunityInsightModel(
      id: -1006,
      insightType: 'EXPERIENCE',
      title: 'Pace the first 2 km conservatively',
      content: 'Coastal courses often feel flat but humidity spikes heart rate early. Hold back until km 3, then build.',
      journeyContext: 'SPORTS|10K RUN|VIZAG',
      votes: 41,
    ),
    CommunityInsightModel(
      id: -1007,
      insightType: 'TIP',
      title: 'Generic sports event warm-up',
      content: 'Dynamic stretches plus 5 minutes of easy jogging 30 minutes before start helps for any 10K or half marathon.',
      journeyContext: 'SPORTS|10K RUN',
      votes: 29,
    ),
    CommunityInsightModel(
      id: -1008,
      insightType: 'TIP',
      title: 'Fast before your procedure window',
      content: 'Confirm nil-by-mouth time with your care team. Clear fluids may be allowed until 2 hours before for some angiograms.',
      journeyContext: 'HEALTH|MEDICAL PROCEDURE|ANGIOGRAM',
      votes: 33,
    ),
  ];

  static List<CommunityInsightModel> communityInsightsFor(JourneyModel journey) =>
      filterInsightsForJourney(_allDemoInsights, journey);
}

extension JourneyModelCopy on JourneyModel {
  JourneyModel copyWith({
    int? id,
    String? title,
    String? originalQuery,
    String? status,
    int? progressPercent,
    DateTime? createdAt,
    String? journeyType,
    String? journeySubtype,
    String? activity,
    String? location,
  }) =>
      JourneyModel(
        id: id ?? this.id,
        title: title ?? this.title,
        originalQuery: originalQuery ?? this.originalQuery,
        status: status ?? this.status,
        progressPercent: progressPercent ?? this.progressPercent,
        createdAt: createdAt ?? this.createdAt,
        journeyType: journeyType ?? this.journeyType,
        journeySubtype: journeySubtype ?? this.journeySubtype,
        activity: activity ?? this.activity,
        location: location ?? this.location,
      );
}
