import '../../data/models/ai_models.dart';

/// Client-side scoring aligned with API CommunityJourneyMatcher.
int communityInsightScore(CommunityInsightModel insight, JourneyModel journey) {
  final journeyTokens = _journeyTokens(journey);
  final insightTokens = _insightTokens(insight);
  if (journeyTokens.isEmpty || insightTokens.isEmpty) return 0;

  var overlap = 0;
  for (final j in journeyTokens) {
    for (final i in insightTokens) {
      if (_tokensMatch(j, i)) overlap++;
    }
  }
  if (overlap == 0) return 0;

  var score = overlap * 15;
  final location = _token(journey.location);
  if (location.isNotEmpty && insightTokens.contains(location)) score += 35;

  final subtype = _token(journey.journeySubtype);
  final activity = _token(journey.activity);
  if ((subtype.isNotEmpty && insightTokens.contains(subtype)) ||
      (activity.isNotEmpty && insightTokens.contains(activity))) {
    score += 25;
  }

  final type = _token(journey.journeyType);
  if (type.isNotEmpty && insightTokens.contains(type)) score += 15;

  return score > 95 ? 95 : score;
}

List<CommunityInsightModel> filterInsightsForJourney(
  List<CommunityInsightModel> insights,
  JourneyModel journey,
) {
  final scored = insights
      .map((i) => MapEntry(i, communityInsightScore(i, journey)))
      .where((e) => e.value > 0)
      .toList()
    ..sort((a, b) {
      final byScore = b.value.compareTo(a.value);
      if (byScore != 0) return byScore;
      return b.key.votes.compareTo(a.key.votes);
    });
  return scored.map((e) => e.key).toList();
}

String journeyCommunityContext(JourneyModel journey) {
  final parts = <String>[
    if (journey.journeyType != null && journey.journeyType!.isNotEmpty) journey.journeyType!,
    if (journey.journeySubtype != null && journey.journeySubtype!.isNotEmpty) journey.journeySubtype!,
    if (journey.activity != null && journey.activity!.isNotEmpty) journey.activity!,
    if (journey.location != null && journey.location!.isNotEmpty) journey.location!,
  ];
  if (parts.isEmpty) return journey.title;
  return parts.join('|').toUpperCase();
}

Set<String> _journeyTokens(JourneyModel journey) {
  final tokens = <String>{};
  _addTokens(tokens, journey.title);
  _addTokens(tokens, journey.originalQuery);
  _addTokens(tokens, journey.journeyType);
  _addTokens(tokens, journey.journeySubtype);
  _addTokens(tokens, journey.activity);
  _addTokens(tokens, journey.location);
  return tokens.where(_isSignificant).toSet();
}

Set<String> _insightTokens(CommunityInsightModel insight) {
  final tokens = <String>{};
  _addTokens(tokens, insight.journeyContext);
  _addTokens(tokens, insight.title);
  return tokens.where(_isSignificant).toSet();
}

void _addTokens(Set<String> tokens, String? raw) {
  if (raw == null || raw.trim().isEmpty) return;
  for (final part in raw.toLowerCase().split(RegExp(r'[|\s,/\-—]+'))) {
    final t = part.trim();
    if (t.isNotEmpty) tokens.add(t);
  }
}

String _token(String? raw) => raw?.trim().toLowerCase() ?? '';

bool _tokensMatch(String a, String b) {
  if (a == b) return true;
  if (a.length >= 4 && b.length >= 4 && (a.contains(b) || b.contains(a))) return true;
  return false;
}

bool _isSignificant(String token) {
  if (token.length < 2) return false;
  const stop = {'the', 'and', 'for', 'your', 'with', 'from', 'that', 'this', 'day', 'pre', 'prep'};
  return !stop.contains(token);
}
