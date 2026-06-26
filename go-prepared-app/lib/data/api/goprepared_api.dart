import 'package:go_prepared_app/data/api/ai_api.dart';
import 'package:go_prepared_app/data/api/api_client.dart';
import 'package:go_prepared_app/data/api/auth_api.dart';
import 'package:go_prepared_app/data/api/cards_api.dart';
import 'package:go_prepared_app/data/api/checklists_api.dart';
import 'package:go_prepared_app/data/api/community_api.dart';
import 'package:go_prepared_app/data/api/journeys_api.dart';
import 'package:go_prepared_app/data/api/knowledge_api.dart';
import 'package:go_prepared_app/data/api/tickets_api.dart';
import 'package:go_prepared_app/data/api/users_api.dart';

/// Facade for all GoPrepared REST endpoints.
class GoPreparedApi {
  GoPreparedApi({
    required String baseUrl,
    String? accessToken,
    ApiClient? client,
  }) : client = client ??
            ApiClient(
              baseUrl: baseUrl,
              accessToken: accessToken,
            ) {
    auth = AuthApiImpl(this.client);
    journeys = JourneysApiImpl(this.client);
    cards = CardsApiImpl(this.client);
    checklists = ChecklistsApiImpl(this.client);
    knowledge = KnowledgeApiImpl(this.client);
    ai = AiApiImpl(this.client);
    community = CommunityApiImpl(this.client);
    tickets = TicketsApiImpl(this.client);
    users = UsersApiImpl(this.client);
  }

  final ApiClient client;

  late final AuthApi auth;
  late final JourneysApi journeys;
  late final CardsApi cards;
  late final ChecklistsApi checklists;
  late final KnowledgeApi knowledge;
  late final AiApi ai;
  late final CommunityApi community;
  late final TicketsApi tickets;
  late final UsersApi users;

  void setAccessToken(String? token) => client.setAccessToken(token);
}
