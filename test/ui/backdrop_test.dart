import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/ui/backdrop.dart';

void main() {
  const home = 1;

  group('pageBackdropLevel', () {
    test('sharp at Home, one level per page of distance', () {
      expect(pageBackdropLevel(1, home), 0);
      expect(pageBackdropLevel(0, home), 1); // Space
      expect(pageBackdropLevel(2, home), 1); // Collections
      expect(pageBackdropLevel(3, home), 2); // A-Z
    });

    test('eased within a step: slow at the ends, half-way in the middle', () {
      expect(pageBackdropLevel(1.5, home), closeTo(0.5, 1e-9));
      expect(pageBackdropLevel(1.1, home), lessThan(0.1));
      expect(pageBackdropLevel(2.9, home), greaterThan(1.9));
    });

    test('symmetric and continuous', () {
      expect(pageBackdropLevel(0.7, home), pageBackdropLevel(1.3, home));
      expect(pageBackdropLevel(2.0001, home), closeTo(1, 1e-3));
      expect(pageBackdropLevel(1.9999, home), closeTo(1, 1e-3));
    });
  });

  group('backdropLevel', () {
    test('no route: the page level', () {
      expect(backdropLevel(1.2, 0), 1.2);
    });

    test('route fully open: the highest level, from any page', () {
      expect(backdropLevel(0, 1), maxBackdropLevel);
      expect(backdropLevel(2, 1), maxBackdropLevel);
    });

    test('half open: half-way to the highest level', () {
      expect(backdropLevel(1, 0.5), 2);
    });
  });

  test('motion notifies only on changes', () {
    final m = BackdropMotion();
    var n = 0;
    m.addListener(() => n++);
    m.page = 1;
    m.page = 1;
    m.away = 0.5;
    expect(n, 2);
    expect(m.level, 2);
  });
}
