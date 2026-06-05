## 2025-05-31 - [BackdropFilter and RepaintBoundary Anti-pattern]
**Learning:** `BackdropFilter` only applies its filter to the content painted *within the same layer*. Wrapping a widget that uses `BackdropFilter` in a `RepaintBoundary` creates a new layer, isolating the filter from the background content it is intended to blur. This effectively disables the "glass" effect.
**Action:** Avoid wrapping `BackdropFilter` in a `RepaintBoundary` unless the background content to be blurred is also included within that same boundary.

## 2025-06-01 - [ListView.builder and CustomPainter Optimizations]
**Learning:** For long lists in Flutter, providing a `prototypeItem` to `ListView.builder` allows the framework to calculate scroll extent in O(1) time without laying out all children. For `CustomPainter`, implementing `shouldRepaint` with proper data equality checks (e.g., `listEquals`) significantly reduces GPU/CPU usage by skipping redundant paint calls.
**Action:** Always use `prototypeItem` for homogeneous lists and implement efficient `shouldRepaint` logic in `CustomPainter` subclasses.
