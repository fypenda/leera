import 'package:english_practice/core/common/widgets/edge_swipe_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<int> swipe(
    WidgetTester tester, {
    required Offset from,
    required Offset by,
  }) async {
    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: EdgeSwipeBack(
          onBack: () => backs++,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );
    await tester.dragFrom(from, by);
    await tester.pumpAndSettle();
    return backs;
  }

  testWidgets('a swipe from the left edge to the right goes back', (
    tester,
  ) async {
    expect(
      await swipe(tester, from: const Offset(4, 300), by: const Offset(200, 0)),
      1,
    );
  });

  testWidgets('a short swipe, or one away from the edge, does not', (
    tester,
  ) async {
    expect(
      await swipe(tester, from: const Offset(4, 300), by: const Offset(30, 0)),
      0,
    );
    expect(
      await swipe(
        tester,
        from: const Offset(200, 300),
        by: const Offset(200, 0),
      ),
      0,
    );
    expect(
      await swipe(tester, from: const Offset(4, 300), by: const Offset(-50, 0)),
      0,
    );
  });
}
