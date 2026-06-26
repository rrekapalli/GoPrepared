-- Journey-scoped community insights (sports / vizag / health); idempotent by title.
INSERT INTO community_insights (insight_type, title, content, journey_context, votes, status, created_at)
SELECT 'TIP', 'Start hydrating 48h before a coastal race',
       'Humid air at Vizag and other coastal courses increases sweat loss. Begin electrolyte drinks two days before race day.',
       'SPORTS|10K RUN|VIZAG', 52, 'ACTIVE', NOW()
WHERE NOT EXISTS (SELECT 1 FROM community_insights WHERE title = 'Start hydrating 48h before a coastal race');

INSERT INTO community_insights (insight_type, title, content, journey_context, votes, status, created_at)
SELECT 'WARNING', 'Arrive early for bib pickup',
       'Expo queues are long the morning before local 10K events. Pick up bib and timing chip the prior evening when possible.',
       'SPORTS|10K RUN|VIZAG', 38, 'ACTIVE', NOW()
WHERE NOT EXISTS (SELECT 1 FROM community_insights WHERE title = 'Arrive early for bib pickup');

INSERT INTO community_insights (insight_type, title, content, journey_context, votes, status, created_at)
SELECT 'EXPERIENCE', 'Pace the first 2 km conservatively',
       'Coastal courses often feel flat but humidity spikes heart rate early. Hold back until km 3, then build.',
       'SPORTS|10K RUN|VIZAG', 41, 'ACTIVE', NOW()
WHERE NOT EXISTS (SELECT 1 FROM community_insights WHERE title = 'Pace the first 2 km conservatively');

INSERT INTO community_insights (insight_type, title, content, journey_context, votes, status, created_at)
SELECT 'TIP', 'Generic sports event warm-up',
       'Dynamic stretches plus 5 minutes of easy jogging 30 minutes before start helps for any 10K or half marathon.',
       'SPORTS|10K RUN', 29, 'ACTIVE', NOW()
WHERE NOT EXISTS (SELECT 1 FROM community_insights WHERE title = 'Generic sports event warm-up');

INSERT INTO community_insights (insight_type, title, content, journey_context, votes, status, created_at)
SELECT 'TIP', 'Fast before your procedure window',
       'Confirm nil-by-mouth time with your care team. Clear fluids may be allowed until 2 hours before for some angiograms.',
       'HEALTH|MEDICAL PROCEDURE|ANGIOGRAM', 33, 'ACTIVE', NOW()
WHERE NOT EXISTS (SELECT 1 FROM community_insights WHERE title = 'Fast before your procedure window');
