import 'package:flutter_test/flutter_test.dart';
import 'package:libreglide/core/categories.dart';

void main() {
  test('the user overrides everything', () {
    final r = categorize(
      packageName: 'com.whatsapp',
      label: 'WhatsApp',
      isSystem: false,
      manifestCategory: 4,
      userOverride: AppCategory.work,
    );
    expect(r.category, AppCategory.work);
    expect(r.source, CategorySource.user);
  });

  test('the dictionary beats the manifest', () {
    final r = categorize(
      packageName: 'com.whatsapp',
      label: 'WhatsApp',
      isSystem: false,
      manifestCategory: 4, // social in the manifest
    );
    expect(r.category, AppCategory.messaging);
    expect(r.source, CategorySource.dictionary);
  });

  test('manifest if the package is not in the dictionary', () {
    final r = categorize(
      packageName: 'com.example.unknown',
      label: 'Qualcosa',
      isSystem: false,
      manifestCategory: 1,
    );
    expect(r.category, AppCategory.music);
    expect(r.source, CategorySource.manifest);
  });

  test('name heuristic', () {
    final r = categorize(
      packageName: 'it.esempio.mybank',
      label: 'La mia banca',
      isSystem: false,
    );
    expect(r.category, AppCategory.finance);
    expect(r.source, CategorySource.heuristic);
  });

  test('ambiguous words do not trigger wrong categories', () {
    // "schedule" contains "edu", "weather" contains "eat", "business" contains "bus"
    expect(
      categorize(
        packageName: 'com.x.schedule',
        label: 'Schedule',
        isSystem: false,
      ).category,
      isNot(AppCategory.education),
    );
    expect(
      categorize(
        packageName: 'com.x.business',
        label: 'Business',
        isSystem: false,
      ).category,
      isNot(AppCategory.maps),
    );
    expect(
      categorize(
        packageName: 'com.x.weather',
        label: 'Weather',
        isSystem: false,
      ).category,
      AppCategory.tools,
    );
  });

  test('fallback: system or other', () {
    expect(
      categorize(
        packageName: 'com.oem.zzz',
        label: 'Zzz',
        isSystem: true,
      ).category,
      AppCategory.system,
    );
    expect(
      categorize(
        packageName: 'com.foo.zzz',
        label: 'Zzz',
        isSystem: false,
      ).category,
      AppCategory.other,
    );
  });
}
