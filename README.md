# MuscleGrowth

Roblox project organized for Rojo. Files under `src` mirror Roblox services so
scripts can be copied from Studio into the same service path locally.

## Player data

Player progress uses Roblox DataStore SchemaVersion 1. Live servers use
`MuscleGrowth_PlayerProgress_v1`; Studio uses the isolated
`MuscleGrowth_PlayerProgress_v1_Studio` store.

To test persistence in Studio, publish the experience and enable **Studio Access
to API Services** in Game Settings. If DataStore loading is unavailable, the
server rejects the player instead of creating default data that could overwrite
an existing save.

Studio sessions may immediately take over a stale lock in the isolated Studio
store, so stopping and restarting Play mode does not require waiting for the
production lease timeout. Live servers always enforce the full session lease.
