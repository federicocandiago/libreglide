import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/ui/gestures.dart';

void main() {
  test('a quick flick counts', () {
    expect(isVerticalSwipe(-800, -20, SwipeDirection.up), isTrue);
    expect(isVerticalSwipe(800, 20, SwipeDirection.down), isTrue);
  });

  test('a slow but long swipe counts', () {
    expect(isVerticalSwipe(-100, -200, SwipeDirection.up), isTrue);
    expect(isVerticalSwipe(0, 150, SwipeDirection.down), isTrue);
  });

  test('short, slow or thrown back swipes do not', () {
    expect(isVerticalSwipe(-100, -30, SwipeDirection.up), isFalse);
    expect(isVerticalSwipe(600, -200, SwipeDirection.up), isFalse);
    expect(isVerticalSwipe(-800, -200, SwipeDirection.down), isFalse);
  });
}
