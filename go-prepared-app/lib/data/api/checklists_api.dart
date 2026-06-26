import 'package:go_prepared_app/data/api/api_client.dart';
import 'package:go_prepared_app/data/api/api_result.dart';
import 'package:go_prepared_app/data/models/checklist.dart';

abstract class ChecklistsApi {
  Future<ApiResult<ChecklistListResponse>> getChecklists({
    required String journeyId,
    int page = 1,
    int pageSize = 20,
  });

  Future<ApiResult<Checklist>> getChecklist({
    required String journeyId,
    required String checklistId,
  });

  Future<ApiResult<Checklist>> createChecklist({
    required String journeyId,
    required String title,
    String? description,
  });

  Future<ApiResult<ChecklistItem>> createItem({
    required String journeyId,
    required String checklistId,
    required String title,
    int? position,
  });

  Future<ApiResult<ChecklistItem>> updateItem({
    required String journeyId,
    required String checklistId,
    required String itemId,
    String? title,
    bool? completed,
    int? position,
  });

  Future<ApiResult<bool>> deleteItem({
    required String journeyId,
    required String checklistId,
    required String itemId,
  });
}

class ChecklistsApiImpl implements ChecklistsApi {
  ChecklistsApiImpl(this.client);

  final ApiClient client;

  @override
  Future<ApiResult<ChecklistListResponse>> getChecklists({
    required String journeyId,
    int page = 1,
    int pageSize = 20,
  }) {
    return client
        .get(
          '/api/v1/journeys/$journeyId/checklists',
          queryParameters: {
            'page': page.toString(),
            'pageSize': pageSize.toString(),
          },
        )
        .decodeJson(
          (json) => ChecklistListResponse.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<Checklist>> getChecklist({
    required String journeyId,
    required String checklistId,
  }) {
    return client
        .get('/api/v1/journeys/$journeyId/checklists/$checklistId')
        .decodeJson((json) => Checklist.fromJson(json as Map<String, dynamic>))
        .send();
  }

  @override
  Future<ApiResult<Checklist>> createChecklist({
    required String journeyId,
    required String title,
    String? description,
  }) {
    return client
        .post('/api/v1/journeys/$journeyId/checklists')
        .encodeJson((_) => {
              'title': title,
              if (description != null) 'description': description,
            })
        .decodeJson((json) => Checklist.fromJson(json as Map<String, dynamic>))
        .send();
  }

  @override
  Future<ApiResult<ChecklistItem>> createItem({
    required String journeyId,
    required String checklistId,
    required String title,
    int? position,
  }) {
    return client
        .post('/api/v1/journeys/$journeyId/checklists/$checklistId/items')
        .encodeJson((_) => {
              'title': title,
              if (position != null) 'position': position,
            })
        .decodeJson(
          (json) => ChecklistItem.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<ChecklistItem>> updateItem({
    required String journeyId,
    required String checklistId,
    required String itemId,
    String? title,
    bool? completed,
    int? position,
  }) {
    return client
        .put('/api/v1/journeys/$journeyId/checklists/$checklistId/items/$itemId')
        .encodeJson((_) => {
              if (title != null) 'title': title,
              if (completed != null) 'completed': completed,
              if (position != null) 'position': position,
            })
        .decodeJson(
          (json) => ChecklistItem.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<bool>> deleteItem({
    required String journeyId,
    required String checklistId,
    required String itemId,
  }) {
    return client
        .delete(
          '/api/v1/journeys/$journeyId/checklists/$checklistId/items/$itemId',
        )
        .send();
  }
}
