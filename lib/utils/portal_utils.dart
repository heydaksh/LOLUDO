// ==============================
// PORTAL UTILITIES
// Helper functions to determine which board tiles are off-limits
// for portal placement (safe zones, start tiles, home entry tiles).
// ==============================

/// Returns true if [index] (0–51 on the main path) is a restricted tile
/// where portals must NOT be placed.
///
/// Restricted categories:
///   • Star/safe tiles  — [8, 13, 21, 26, 34, 39, 47, 52] (standard safe zones + extras)
///   • Starting tiles   — [1, 14, 27, 40]  (each color's entry square)
///   • Winning tiles    — [51, 12, 25, 38] (home-stretch entries)
bool isRestrictedTile(int index) {
  const starTiles = [8, 13, 21, 26, 34, 39, 47];
  const startingTiles = [1, 14, 27, 40];
  const winningTiles = [51, 12, 25, 38];

  if (starTiles.contains(index)) return true;
  if (startingTiles.contains(index)) return true;
  if (winningTiles.contains(index)) return true;

  return false;
}

/// Returns true if [index] represents a home-stretch / colored arm tile
/// (step >= 100 convention used internally — safety check for future use).
bool isHomePath(int index) {
  return index >= 100;
}
