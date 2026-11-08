import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/ui/gestures.dart';
import 'package:libreglide/ui/widgets/swipe_to_close.dart';

void main() {
  Future<(ScrollController, List<int>)> pump(
    WidgetTester tester,
    SwipeDirection direction,
  ) async {
    final scroll = ScrollController();
    final closed = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SwipeToClose(
          direction: direction,
          scroll: scroll,
          onClose: () => closed.add(1),
          child: ListView(
            controller: scroll,
            children: [
              for (var i = 0; i < 60; i++)
                SizedBox(height: 50, child: Text('row $i')),
            ],
          ),
        ),
      ),
    );
    return (scroll, closed);
  }

  testWidgets('swipe down at the top of the list closes', (tester) async {
    final (_, closed) = await pump(tester, SwipeDirection.down);
    await tester.fling(find.text('row 2'), const Offset(0, 300), 1500);
    await tester.pumpAndSettle();
    expect(closed, [1]);
  });

  testWidgets('swipe down in the middle of the list only scrolls', (
    tester,
  ) async {
    final (scroll, closed) = await pump(tester, SwipeDirection.down);
    scroll.jumpTo(600);
    await tester.pump();
    await tester.fling(find.text('row 14'), const Offset(0, 300), 1500);
    await tester.pumpAndSettle();
    expect(closed, isEmpty);
  });

  testWidgets('swipe up closes only at the bottom of the list', (tester) async {
    final (scroll, closed) = await pump(tester, SwipeDirection.up);
    await tester.fling(find.text('row 5'), const Offset(0, -300), 1500);
    await tester.pumpAndSettle();
    expect(closed, isEmpty);
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();
    await tester.fling(find.text('row 55'), const Offset(0, -300), 1500);
    await tester.pumpAndSettle();
    expect(closed, [1]);
  });

  testWidgets('the wrong direction never closes', (tester) async {
    final (_, closed) = await pump(tester, SwipeDirection.down);
    await tester.fling(find.text('row 5'), const Offset(0, -300), 1500);
    await tester.pumpAndSettle();
    expect(closed, isEmpty);
  });
}
