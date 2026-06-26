import 'package:go_prepared_app/data/api/api_client.dart';
import 'package:go_prepared_app/data/api/api_result.dart';
import 'package:go_prepared_app/data/models/journey.dart';

abstract class JourneysApi {
  Future<ApiResult<JourneyListResponse>> getJourneys({
    int page = 1,
    int pageSize = 20,
  });

  Future<ApiResult<Journey>> getJourney(String journeyId);

  Future<ApiResult<Journey>> createJourney({
    required String title,
    String? description,
    String? category,
    String? destination,
    String? startDate,
    String? endDate,
  });

  Future<ApiResult<Journey>> updateJourney({
    required String journeyId,
    String? title,
    String? description,
    String? category,
    String? destination,
    String? startDate,
    String? endDate,
    String? status,
  });

  Future<ApiResult<bool>> deleteJourney(String journeyId);
}

class JourneysApiImpl implements JourneysApi {
  JourneysApiImpl(this.client);

  final ApiClient client;

  @override
  Future<ApiResult<JourneyListResponse>> getJourneys({
    int page = 1,
    int pageSize = 20,
  }) {
    return client
        .get(
          '/api/v1/journeys',
          queryParameters: {
            'page': page.toString(),
            'pageSize': pageSize.toString(),
          },
        )
        .decodeJson(
          (json) => JourneyListResponse.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<Journey>> getJourney(String journeyId) {
    return client
        .get('/api/v1/journeys/$journeyId')
        .decodeJson((json) => Journey.fromJson(json as Map<String, dynamic>))
        .send();
  }

  @override
  Future<ApiResult<Journey>> createJourney({
    required String title,
    String? description,
    String? category,
    String? destination,
    String? startDate,
    String? endDate,
  }) {
    return client
        .post('/api/v1/journeys')
        .encodeJson((_) => {
              'title': title,
              if (description != null) 'description': description,
              if (category != null) 'category': category,
              if (destination != null) 'destination': destination,
              if (startDate != null) 'startDate': startDate,
              if (endDate != null) 'endDate': endDate,
            })
        .decodeJson((json) => Journey.fromJson(json as Map<String, dynamic>))
        .send();
  }

  @override
  Future<ApiResult<Journey>> updateJourney({
    required String journeyId,
    String? title,
    String? description,
    String? category,
    String? destination,
    String? startDate,
    String? endDate,
    String? status,
  }) {
    return client
        .put('/api/v1/journeys/$journeyId')
        .encodeJson((_) => {
              if (title != null) 'title': title,
              if (description != null) 'description': description,
              if (category != null) 'category': category,
              if (destination != null) 'destination': destination,
              if (startDate != null) 'startDate': startDate,
              if (endDate != null) 'endDate': endDate,
              if (status != null) 'status': status,
            })
        .decodeJson((json) => Journey.fromJson(json as Map<String, dynamic>))
        .send();
  }

  @override
  Future<ApiResult<bool>> deleteJourney(String journeyId) {
    return client.delete('/api/v1/journeys/$journeyId').send();
  }
}
