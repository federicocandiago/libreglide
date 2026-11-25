import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/dock.dart';

void main() {
  group('readDockSlots', () {
    test('nothing stored: four free slots', () {
      expect(readDockSlots(null), ['', '', '', '']);
    });

    test(
      'the earlier format (filled from the left) reads as the same dock',
      () {
        expect(readDockSlots(['a', 'b']), ['a', 'b', '', '']);
      },
    );

    test('free slots in the middle are kept', () {
      expect(readDockSlots(['', 'b', '', 'd']), ['', 'b', '', 'd']);
    });

    test('extra entries and repeated apps are dropped', () {
      expect(readDockSlots(['a', 'a', 'c', 'd', 'e']), ['a', '', 'c', 'd']);
    });
  });

  group('placeInDock', () {
    test('fills exactly the slot of the "+"', () {
      expect(placeInDock(['a', '', '', ''], 3, 'x'), ['a', '', '', 'x']);
    });

    test('replaces the app in that slot', () {
      expect(placeInDock(['a', 'b', '', ''], 1, 'x'), ['a', 'x', '', '']);
    });

    test('an app already in the dock leaves its old slot', () {
      expect(placeInDock(['a', 'b', '', ''], 3, 'a'), ['', 'b', '', 'a']);
    });

    test('a slot out of range changes nothing', () {
      final slots = ['a', '', '', ''];
      expect(placeInDock(slots, 4, 'x'), slots);
      expect(placeInDock(slots, -1, 'x'), slots);
    });
  });

  group('removeFromDock', () {
    test('frees only its own slot, the others do not shift', () {
      expect(removeFromDock(['a', 'b', 'c', 'd'], 'c'), ['a', 'b', '', 'd']);
    });

    test('the freed slot can be filled again', () {
      final slots = removeFromDock(['a', 'b', 'c', 'd'], 'd');
      expect(placeInDock(slots, 3, 'd'), ['a', 'b', 'c', 'd']);
    });

    test('an app not in the dock changes nothing', () {
      expect(removeFromDock(['a', '', '', ''], 'x'), ['a', '', '', '']);
    });
  });

  group('moveInDock', () {
    test('onto a free slot', () {
      expect(moveInDock(['a', 'b', '', ''], 'a', 3), ['', 'b', '', 'a']);
    });

    test('onto another app: the two swap', () {
      expect(moveInDock(['a', 'b', 'c', ''], 'a', 2), ['c', 'b', 'a', '']);
    });

    test('an app not in the dock changes nothing', () {
      expect(moveInDock(['a', '', '', ''], 'x', 2), ['a', '', '', '']);
    });
  });
}
