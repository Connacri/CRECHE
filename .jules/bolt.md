## 2025-05-31 - [BackdropFilter and RepaintBoundary Anti-pattern]
**Learning:** `BackdropFilter` only applies its filter to the content painted *within the same layer*. Wrapping a widget that uses `BackdropFilter` in a `RepaintBoundary` creates a new layer, isolating the filter from the background content it is intended to blur. This effectively disables the "glass" effect.
**Action:** Avoid wrapping `BackdropFilter` in a `RepaintBoundary` unless the background content to be blurred is also included within that same boundary.
