import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_prepared_app/main.dart';

void main() {
  testWidgets('App loads', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GoPreparedApp()));
    expect(find.text('GoPrepared'), findsWidgets);
  });
}
