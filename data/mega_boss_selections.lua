-- Approved trainer Mega choices from 2026-10-31 user selection.
-- Identified by ROM-derived (name, class) with exact trainer ID cross-check.
-- Do not make up numeric trainer IDs. No full-party replacements approved.
-- Kanto/Hoe nn battles are edition-specific.
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
    {key="rival_champion",name="*",classes={"CHAMPION"},slug="starter_x",noAdd=true},
    {key="giovanni_rocket",name="GIOVANNI",classes={"BOSS","ROCKET BOSS"},slug="mega_mewtwo_y"}
  },
  hoenn={
    {key="roxanne",name="ROXANNE",classes={"LEADER"},slug="mega_glimmora"},
    {key="brawly",name="BRAWLY",classes={"LEADER"},slug="mega_medicham"},
    {key="wattson",name="WATTSON",classes={"LEADER"},slug="mega_manectric"},
    {key="flannery",name="FLANNERY",classes={"LEADER"},slug="mega_camerupt"},
    {key="norman",name="NORMAN",classes={"LEADER"},slug="mega_kangaskhan"},
    {key="winona",name="WINONA",classes={"LEADER"},slug="mega_altaria"},
    {key="tate_liza",name="TATE&LIZA",classes={"LEADER"},slug="mega_meowstic",double=true,
      aliases={"TATE & LIZA","TATE","LIZA"}},
    {key="wallace_gym",name="WALLACE",classes={"LEADER"},slug="mega_gyarados",games={"ruby","sapphire"}},
    {key="juan",name="JUAN",classes={"LEADER"},slug="mega_tatsugiri_curly",games={"emerald"}},
    {key="sidney",name="SIDNEY",classes={"ELITE FOUR"},slug="mega_absol"},
    {key="phoebe",name="PHOEBE",classes={"ELITE FOUR"},slug="mega_banette"},
    {key="glacia",name="GLACIA",classes={"ELITE FOUR"},slug="mega_glalie"},
    {key="drake",name="DRAKE",classes={"ELITE FOUR"},slug="mega_salamence"},
    {key="steven",name="STEVEN",classes={"CHAMPION"},slug="mega_metagross",games={"ruby","sapphire"}},
    {key="wallace_champion",name="WALLACE",classes={"CHAMPION"},slug="mega_gyarados",games={"emerald"}},
    {key="maxie",name="MAXIE",classes={"MAGMA LEADER","MAGMALEADER"},slug="mega_houndoom"},
    {key="archie",name="ARCHIE",classes={"AQUA LEADER","AQUALEADER"},slug="mega_sharpedo"},
    {key="wally",name="WALLY",classes={"POKEMON TRAINER","PKMN TRAINER","POKEMONTRAINER"},slug="mega_gardevoir"}
  }
}