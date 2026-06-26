import 'package:go_prepared_app/data/api/api_client.dart';
import 'package:go_prepared_app/data/api/api_result.dart';
import 'package:go_prepared_app/data/models/ticket.dart';

abstract class TicketsApi {
  Future<ApiResult<TicketListResponse>> getTickets({
    int page = 1,
    int pageSize = 20,
  });

  Future<ApiResult<Ticket>> getTicket(String ticketId);

  Future<ApiResult<Ticket>> createTicket({
    required String subject,
    required String description,
    String? category,
    String? priority,
  });

  Future<ApiResult<TicketCommentListResponse>> getComments(String ticketId);

  Future<ApiResult<TicketComment>> createComment({
    required String ticketId,
    required String body,
  });

  Future<ApiResult<Ticket>> updateStatus({
    required String ticketId,
    required String status,
  });
}

class TicketsApiImpl implements TicketsApi {
  TicketsApiImpl(this.client);

  final ApiClient client;

  @override
  Future<ApiResult<TicketListResponse>> getTickets({
    int page = 1,
    int pageSize = 20,
  }) {
    return client
        .get(
          '/api/v1/tickets',
          queryParameters: {
            'page': page.toString(),
            'pageSize': pageSize.toString(),
          },
        )
        .decodeJson(
          (json) => TicketListResponse.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<Ticket>> getTicket(String ticketId) {
    return client
        .get('/api/v1/tickets/$ticketId')
        .decodeJson((json) => Ticket.fromJson(json as Map<String, dynamic>))
        .send();
  }

  @override
  Future<ApiResult<Ticket>> createTicket({
    required String subject,
    required String description,
    String? category,
    String? priority,
  }) {
    return client
        .post('/api/v1/tickets')
        .encodeJson((_) => {
              'subject': subject,
              'description': description,
              if (category != null) 'category': category,
              if (priority != null) 'priority': priority,
            })
        .decodeJson((json) => Ticket.fromJson(json as Map<String, dynamic>))
        .send();
  }

  @override
  Future<ApiResult<TicketCommentListResponse>> getComments(String ticketId) {
    return client
        .get('/api/v1/tickets/$ticketId/comments')
        .decodeJson(
          (json) => TicketCommentListResponse.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .send();
  }

  @override
  Future<ApiResult<TicketComment>> createComment({
    required String ticketId,
    required String body,
  }) {
    return client
        .post('/api/v1/tickets/$ticketId/comments')
        .encodeJson((_) => {'body': body})
        .decodeJson(
          (json) => TicketComment.fromJson(json as Map<String, dynamic>),
        )
        .send();
  }

  @override
  Future<ApiResult<Ticket>> updateStatus({
    required String ticketId,
    required String status,
  }) {
    return client
        .patch('/api/v1/tickets/$ticketId')
        .encodeJson((_) => {'status': status})
        .decodeJson((json) => Ticket.fromJson(json as Map<String, dynamic>))
        .send();
  }
}
