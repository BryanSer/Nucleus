# Nucleus - Classic Era (Vanilla)

Port in preparation. TOC: `Nucleus_Vanilla.toc` (Interface 11508, 11509), saved variables
`NucleusDB_Vanilla`.

Differences to Retail / Forever that shape this build:
- Auras are read with the old index API (`UnitBuff` / `UnitDebuff`), no aura containers, no
  `auraInstanceID`, no secret values.
- No ping system, no heal / absorb prediction (no shield or heal bars).
- Spells have ranks: track by spell name, or by every rank's id.
- Debuffs run through the normal Debuffs row; no raid-debuff indicator and no raid-debuff lists.
