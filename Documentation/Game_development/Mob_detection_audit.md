# Mob detection audit

The current mob detection system is implemented in `Scripts/Mob/Detection.gd` and relies on periodic raycasts to find targets.

## Shortcomings
- **Line-of-sight only** – `sightRange` is used for raycast checks, but `senseRange` and `hearingRange` are defined yet unused.
- **Single player assumption** – `get_nodes_in_group("Players")` only considers the first player in the group, ignoring others.
- **Target manager dependency** – Detection halts until `target_manager` is discovered, causing mobs to idle if the manager is missing.
- **Repeated group lookups** – Each detection attempt queries node groups and performs raycasts, which may become expensive with many mobs.
- **No distance-based prioritization** – Closest target is selected after visibility checks, but distant targets are processed even when nearby options exist.
- **Fixed intervals** – Detection timer switches between 0.3s and 2s intervals, which may be inefficient for responsive behavior.

These issues highlight opportunities for optimizing detection through broader sensing, efficient target retrieval, and more adaptive timing.
