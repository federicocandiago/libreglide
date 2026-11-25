/// Home dock: a fixed row of [dockSlotCount] slots, each one free or holding
/// one app (spec-viste-app §0).
///
/// Every slot stands on its own: the "+" of a slot fills that very slot,
/// removing an app frees only its own slot, and the other apps never shift.
///
/// Stored as a list of app ids, one per slot from the left, with '' for a
/// free slot. A plain list of ids filled from the left (the earlier format)
/// reads as the same dock, so no migration is needed.
library;

const dockSlotCount = 4;

/// Marks a free slot in the stored list.
const freeDockSlot = '';

/// The slots in [stored]: exactly [dockSlotCount] entries, each app at most
/// once (a repeated app keeps only its leftmost slot).
List<String> readDockSlots(List<String>? stored) {
  final out = List.filled(dockSlotCount, freeDockSlot);
  final seen = <String>{};
  for (final (i, id)
      in (stored ?? const <String>[]).take(dockSlotCount).indexed) {
    if (id.isNotEmpty && seen.add(id)) out[i] = id;
  }
  return out;
}

/// [slots] with [appId] in [slot], replacing whatever was there. If the app
/// was already in another slot, that slot becomes free.
List<String> placeInDock(List<String> slots, int slot, String appId) {
  if (appId.isEmpty || slot < 0 || slot >= slots.length) return slots;
  return [
    for (final (i, id) in slots.indexed)
      i == slot ? appId : (id == appId ? freeDockSlot : id),
  ];
}

/// [slots] without [appId]: only its own slot becomes free.
List<String> removeFromDock(List<String> slots, String appId) => [
  for (final id in slots) id == appId ? freeDockSlot : id,
];

/// [slots] with [appId] moved to [slot] (drag and drop): the app that was
/// there, if any, takes the slot [appId] left.
List<String> moveInDock(List<String> slots, String appId, int slot) {
  final from = appId.isEmpty ? -1 : slots.indexOf(appId);
  if (from < 0 || slot < 0 || slot >= slots.length || from == slot) {
    return slots;
  }
  final out = [...slots];
  out[from] = slots[slot];
  out[slot] = appId;
  return out;
}
