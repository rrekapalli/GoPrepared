import 'package:go_prepared_app/data/api/api_client.dart';
import 'package:go_prepared_app/data/api/api_result.dart';
import 'package:go_prepared_app/data/models/card.dart';

abstract class CardsApi {
  Future<ApiResult<CardListResponse>> getCards({
    required String journeyId,
    int page = 1,
    int pageSize = 50,
  });

  Future<ApiResult<PreparationCard>> getCard({
    required String journeyId,
    required String cardId,
  });

  Future<ApiResult<PreparationCard>> createCard({
    required String journeyId,
    required String title,
    String? summary,
    String? content,
    String? cardType,
    int? position,
  });

  Future<ApiResult<PreparationCard>> updateCard({
    required String journeyId,
    required String cardId,
    String? title,
    String? summary,
    String? content,
    String? cardType,
    int? position,
  });

  Future<ApiResult<bool>> deleteCard({
    required String journeyId,
    required String cardId,
  });
}

class CardsApiImpl implements CardsApi {
  CardsApiImpl(this.client);

  final ApiClient client;

  @override
  Future<ApiResult<CardListResponse>> getCards({
    required String journeyId,
    int page = 1,
    int pageSize = 50,
  }) {
    return client
        .get(
          '/api/v1/journeys/$journeyId/cards',
          queryParameters: {
            'page': page.toString(),
            'pageSize': pageSize.toString(),
          },
        )
        .decodeJson(
          (json) => CardListResponse.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<PreparationCard>> getCard({
    required String journeyId,
    required String cardId,
  }) {
    return client
        .get('/api/v1/journeys/$journeyId/cards/$cardId')
        .decodeJson(
          (json) => PreparationCard.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<PreparationCard>> createCard({
    required String journeyId,
    required String title,
    String? summary,
    String? content,
    String? cardType,
    int? position,
  }) {
    return client
        .post('/api/v1/journeys/$journeyId/cards')
        .encodeJson((_) => {
              'title': title,
              if (summary != null) 'summary': summary,
              if (content != null) 'content': content,
              if (cardType != null) 'cardType': cardType,
              if (position != null) 'position': position,
            })
        .decodeJson(
          (json) => PreparationCard.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<PreparationCard>> updateCard({
    required String journeyId,
    required String cardId,
    String? title,
    String? summary,
    String? content,
    String? cardType,
    int? position,
  }) {
    return client
        .put('/api/v1/journeys/$journeyId/cards/$cardId')
        .encodeJson((_) => {
              if (title != null) 'title': title,
              if (summary != null) 'summary': summary,
              if (content != null) 'content': content,
              if (cardType != null) 'cardType': cardType,
              if (position != null) 'position': position,
            })
        .decodeJson(
          (json) => PreparationCard.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<bool>> deleteCard({
    required String journeyId,
    required String cardId,
  }) {
    return client.delete('/api/v1/journeys/$journeyId/cards/$cardId').send();
  }
}
