-- Approved trainer Mega choices from 2026-10-31 user selection.
-- Identified by ROM-derived (name, class) with exact trainer ID cross-check.
-- Exact Emerald IDs / party fingerprints below come from the imported ROM audit.
-- Replacements are authorised ONLY for those fingerprint-matched encounters.
-- Wally stays audit-only until his imported-ROM IDs are identified.
-- Kanto/Hoenn battles are edition-specific.
return {
  firered={
    {key="brock",name="BROCK",classes={"LEADER"},slug="mega_aerodactyl"},
    {key="misty",name="MISTY",classes={"LEADER"},slug="mega_starmie"},
    {key="surge",name="LT. SURGE",classes={"LEADER"},slug="mega_raichu_x"},
    {key="erika",name="ERIKA",classes={"LEADER"},slug="mega_victreebel"},
    {key="koga",name="KOGA",classes={"LEADER"},slug="mega_beedrill"},
    {key="sabrina",name="SABRINA",classes={"LEADER"},slug="mega_alakazam"},
    {key="blaine",name="BLAINE",classes={"LEADER"},slug="mega_pyroar"},
    {key="giovanni_gym",name="GIOVANNI",classes={"LEADER"},slug="mega_kangaskhan"},
    {key="lorelei",name="LORELEI",classes={"ELITE FOUR"},slug="mega_slowbro"},
    {key="bruno",name="BRUNO",classes={"ELITE FOUR"},slug="mega_steelix"},
    {key="agatha",name="AGATHA",classes={"ELITE FOUR"},slug="mega_gengar"},
    {key="lance",name="LANCE",classes={"ELITE FOUR"},slug="mega_dragonite"},
    {key="rival_champion",name="*",classes={"CHAMPION"},slug="starter_x",noAdd=true,
      requireNamed=true,minPartySize=6,requiresStarter=true},
    {key="giovanni_rocket",name="GIOVANNI",classes={"BOSS","ROCKET BOSS"},
      slug="mega_mewtwo_y",games={"firered"},
      -- Verified from the user's imported FireRed ROM trainer audit:
      -- #348: Rocket Hideout, ace Kangaskhan Lv.29 — NO Mega.
      -- #349: Silph Co., ace Nidoqueen Lv.41 — add Mega Mewtwo Y.
      onlyTrainerIds={firered={349}},noMegaTrainerIds={firered={348}}}
  },
  hoenn={
    {key="roxanne",name="ROXANNE",classes={"LEADER"},slug="mega_glimmora",emeraldBattles={
      [773]={mode="replace",slot=2,expected="AERODACTYL:47|GOLEM:47|OMASTAR:47|KABUTOPS:50|STEELIX:50|NOSEPASS:52"},
    }},
    {key="brawly",name="BRAWLY",classes={"LEADER"},slug="mega_medicham"},
    {key="wattson",name="WATTSON",classes={"LEADER"},slug="mega_manectric"},
    {key="flannery",name="FLANNERY",classes={"LEADER"},slug="mega_camerupt"},
    {key="norman",name="NORMAN",classes={"LEADER"},slug="mega_kangaskhan"},
    {key="winona",name="WINONA",classes={"LEADER"},slug="mega_altaria"},
    {key="tate_liza",name="TATE&LIZA",classes={"LEADER"},slug="mega_meowstic",double=true,
      aliases={"TATE & LIZA","TATE","LIZA"},
      emeraldBattles={
        [271]={mode="add",expected="CLAYDOL:41|XATU:41|LUNATONE:42|SOLROCK:42"},
        [794]={mode="add",expected="SLOWPOKE:48|CLAYDOL:49|XATU:49|LUNATONE:50|SOLROCK:50"},
        [795]={mode="replace",slot=1,expected="DROWZEE:53|SLOWPOKE:53|CLAYDOL:54|XATU:54|LUNATONE:55|SOLROCK:55"},
        [796]={mode="replace",slot=1,expected="HYPNO:58|CLAYDOL:59|SLOWPOKE:58|XATU:59|LUNATONE:60|SOLROCK:60"},
        [797]={mode="replace",slot=1,expected="HYPNO:63|CLAYDOL:64|SLOWKING:63|XATU:64|LUNATONE:65|SOLROCK:65"},
      }},
    {key="wallace_gym",name="WALLACE",classes={"LEADER"},slug="mega_gyarados",games={"ruby","sapphire"}},
    {key="juan",name="JUAN",classes={"LEADER"},slug="mega_tatsugiri_curly",games={"emerald"},
      emeraldBattles={
        [800]={mode="replace",slot=5,expected="LAPRAS:56|WHISCASH:58|POLIWHIRL:56|WALREIN:58|CRAWDAUNT:58|KINGDRA:61"},
        [801]={mode="replace",slot=5,expected="LAPRAS:61|WHISCASH:63|POLITOED:61|WALREIN:63|CRAWDAUNT:63|KINGDRA:66"},
      }},
    {key="sidney",name="SIDNEY",classes={"ELITE FOUR"},slug="mega_absol"},
    {key="phoebe",name="PHOEBE",classes={"ELITE FOUR"},slug="mega_banette"},
    {key="glacia",name="GLACIA",classes={"ELITE FOUR"},slug="mega_glalie"},
    {key="drake",name="DRAKE",classes={"ELITE FOUR"},slug="mega_salamence"},
    {key="steven",name="STEVEN",classes={"CHAMPION"},slug="mega_metagross",games={"ruby","sapphire"}},
    {key="wallace_champion",name="WALLACE",classes={"CHAMPION"},slug="mega_gyarados",games={"emerald"}},
    {key="maxie",name="MAXIE",classes={"MAGMA LEADER","MAGMALEADER"},slug="mega_houndoom"},
    {key="archie",name="ARCHIE",classes={"AQUA LEADER","AQUALEADER"},slug="mega_sharpedo"},
    {key="wally",name="WALLY",classes={"POKEMON TRAINER","POKéMON TRAINER","PKMN TRAINER","POKEMONTRAINER","POKMONTRAINER"},slug="mega_gardevoir",auditOnly=true,
      -- Verified against Gen1Recomp Emerald constants, not yet the user ROM.
      candidateTrainerIds={emerald={519,656,657,658,659,660}}}
  }
}