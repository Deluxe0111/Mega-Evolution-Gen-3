-- Initial, editable battle placement for ALL 98 EBDX Mega forms.
-- Generated from the common alpha envelope of each whole animation in
-- assets/runtime/mega_atlas_index.json. NEVER re-centre individual frames:
-- their authored hover/bounce/movement stays relative to the shared origin.
-- All scales deliberately start at 1.0 (user preference).
-- feet = visible animation-union bottom (+ small source-padding allowance
-- for deliberately airborne forms). back baseline 57; front baseline 62.
-- dx/dy are game pixels; positive dy moves a sprite DOWN.
-- Tune a form's values here after testing FireRed/Emerald with G9/HD.
-- back_shiny/front_shiny appear only if shiny source frame geometry differs.
return {
  mega_venusaur = {
    back = { scale = 1, feet = 100, baseline = 57, dx = -15, dy = 26 }, -- alpha bottom 100 (frame 121px)
    front = { scale = 1, feet = 98, baseline = 62, dx = 2, dy = 0 }, -- alpha bottom 98 (frame 117px)
  },
  mega_charizard_x = {
    back = { scale = 1, feet = 119, baseline = 57, dx = -12, dy = 39 }, -- 3px of original airborne clearance
    front = { scale = 1, feet = 119, baseline = 62, dx = 0, dy = 5 }, -- 3px of original airborne clearance
  },
  mega_charizard_y = {
    back = { scale = 1, feet = 130, baseline = 57, dx = -25, dy = 51 }, -- alpha bottom 130 (frame 130px)
    front = { scale = 1, feet = 139, baseline = 62, dx = 4, dy = 20 }, -- 3px of original airborne clearance
  },
  mega_blastoise = {
    back = { scale = 1, feet = 122, baseline = 57, dx = 5, dy = 24 }, -- alpha bottom 122 (frame 122px)
    front = { scale = 1, feet = 117, baseline = 62, dx = -10, dy = 2 }, -- alpha bottom 117 (frame 117px)
  },
  mega_beedrill = {
    back = { scale = 1, feet = 102, baseline = 57, dx = -12, dy = 36 }, -- 3px of original airborne clearance
    front = { scale = 1, feet = 102, baseline = 62, dx = 0, dy = 7 }, -- alpha bottom 102 (frame 102px)
  },
  mega_pidgeot = {
    back = { scale = 1, feet = 145, baseline = 57, dx = -13, dy = 53 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 134, baseline = 62, dx = 0, dy = 0 }, -- 4px of original airborne clearance
  },
  mega_alakazam = {
    back = { scale = 1, feet = 109, baseline = 57, dx = -15, dy = 31 }, -- alpha bottom 109 (frame 109px)
    front = { scale = 1, feet = 109, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 109 (frame 109px)
  },
  mega_slowbro = {
    back = { scale = 1, feet = 97, baseline = 57, dx = -9, dy = 39 }, -- alpha bottom 97 (frame 98px)
    front = { scale = 1, feet = 94, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 94 (frame 95px)
  },
  mega_gengar = {
    back = { scale = 1, feet = 89, baseline = 57, dx = -10, dy = 32 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 84, baseline = 62, dx = 0, dy = 0 }, -- 4px of original airborne clearance
  },
  mega_kangaskhan = {
    back = { scale = 1, feet = 80, baseline = 57, dx = -15, dy = 27 }, -- alpha bottom 80 (frame 86px)
    front = { scale = 1, feet = 84, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 84 (frame 94px)
  },
  mega_pinsir = {
    back = { scale = 1, feet = 94, baseline = 57, dx = -11, dy = 41 }, -- 2px of original airborne clearance
    front = { scale = 1, feet = 108, baseline = 62, dx = 0, dy = 0 }, -- 3px of original airborne clearance
  },
  mega_gyarados = {
    back = { scale = 1, feet = 141, baseline = 57, dx = -22, dy = 57 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 150, baseline = 62, dx = -16, dy = 22 }, -- 4px of original airborne clearance
  },
  mega_aerodactyl = {
    back = { scale = 1, feet = 122, baseline = 57, dx = -11, dy = 65 }, -- 6px of original airborne clearance
    front = { scale = 1, feet = 116, baseline = 62, dx = 0, dy = 21 }, -- 6px of original airborne clearance
  },
  mega_mewtwo_x = {
    back = { scale = 1, feet = 86, baseline = 57, dx = -13, dy = 29 }, -- 4px lower (Mewtwo X playtest)
    front = { scale = 1, feet = 71, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 71 (frame 71px)
  },
  mega_mewtwo_y = {
    back = { scale = 1, feet = 139, baseline = 57, dx = -9, dy = 61 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 128, baseline = 62, dx = 1, dy = 17 }, -- 3px of original airborne clearance
  },
  mega_ampharos = {
    back = { scale = 1, feet = 77, baseline = 57, dx = -21, dy = 30 }, -- alpha bottom 77 (frame 77px)
    front = { scale = 1, feet = 79, baseline = 62, dx = 0, dy = 3 }, -- alpha bottom 79 (frame 79px)
  },
  mega_steelix = {
    back = { scale = 1, feet = 127, baseline = 57, dx = -20, dy = 62 }, -- alpha bottom 127 (frame 127px)
    front = { scale = 1, feet = 134, baseline = 62, dx = 0, dy = 43 }, -- alpha bottom 134 (frame 139px)
  },
  mega_scizor = {
    back = { scale = 1, feet = 102, baseline = 57, dx = -5, dy = 30 }, -- alpha bottom 102 (frame 102px)
    front = { scale = 1, feet = 104, baseline = 62, dx = -1, dy = 9 }, -- alpha bottom 104 (frame 104px)
  },
  mega_heracross = {
    back = { scale = 1, feet = 94, baseline = 57, dx = -4, dy = 25 }, -- alpha bottom 94 (frame 99px)
    front = { scale = 1, feet = 104, baseline = 62, dx = -3, dy = 6 }, -- alpha bottom 104 (frame 116px)
  },
  mega_houndoom = {
    back = { scale = 1, feet = 87, baseline = 57, dx = -23, dy = 34 }, -- alpha bottom 87 (frame 87px)
    front = { scale = 1, feet = 87, baseline = 62, dx = 2, dy = 1 }, -- alpha bottom 87 (frame 89px)
  },
  mega_tyranitar = {
    back = { scale = 1, feet = 125, baseline = 57, dx = -9, dy = 54 }, -- alpha bottom 125 (frame 134px)
    front = { scale = 1, feet = 100, baseline = 62, dx = 2, dy = 17 }, -- alpha bottom 100 (frame 122px)
  },
  mega_sceptile = {
    back = { scale = 1, feet = 115, baseline = 57, dx = 0, dy = 31 }, -- alpha bottom 115 (frame 147px)
    front = { scale = 1, feet = 115, baseline = 62, dx = -9, dy = 6 }, -- alpha bottom 115 (frame 147px)
  },
  mega_blaziken = {
    back = { scale = 1, feet = 106, baseline = 57, dx = -13, dy = 35 }, -- alpha bottom 106 (frame 111px)
    front = { scale = 1, feet = 114, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 114 (frame 125px)
  },
  mega_swampert = {
    back = { scale = 1, feet = 91, baseline = 57, dx = -6, dy = 32 }, -- alpha bottom 91 (frame 105px)
    front = { scale = 1, feet = 91, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 91 (frame 106px)
  },
  mega_gardevoir = {
    back = { scale = 1, feet = 86, baseline = 57, dx = -25, dy = 32 }, -- alpha bottom 86 (frame 88px)
    front = { scale = 1, feet = 91, baseline = 62, dx = 15, dy = 10 }, -- alpha bottom 91 (frame 97px)
  },
  mega_sableye = {
    back = { scale = 1, feet = 75, baseline = 57, dx = -20, dy = 24 }, -- alpha bottom 75 (frame 79px)
    front = { scale = 1, feet = 78, baseline = 62, dx = 1, dy = 4 }, -- alpha bottom 78 (frame 85px)
  },
  mega_mawile = {
    back = { scale = 1, feet = 102, baseline = 57, dx = -7, dy = 28 }, -- alpha bottom 102 (frame 102px)
    front = { scale = 1, feet = 101, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 101 (frame 101px)
  },
  mega_aggron = {
    back = { scale = 1, feet = 100, baseline = 57, dx = -12, dy = 29 }, -- alpha bottom 100 (frame 113px)
    front = { scale = 1, feet = 107, baseline = 62, dx = -1, dy = 5 }, -- alpha bottom 107 (frame 125px)
  },
  mega_medicham = {
    back = { scale = 1, feet = 93, baseline = 57, dx = -13, dy = 27 }, -- alpha bottom 93 (frame 101px)
    front = { scale = 1, feet = 91, baseline = 62, dx = 0, dy = 1 }, -- alpha bottom 91 (frame 95px)
  },
  mega_manectric = {
    back = { scale = 1, feet = 100, baseline = 57, dx = -18, dy = 26 }, -- alpha bottom 100 (frame 102px)
    front = { scale = 1, feet = 98, baseline = 62, dx = 1, dy = 5 }, -- alpha bottom 98 (frame 108px)
  },
  mega_sharpedo = {
    back = { scale = 1, feet = 108, baseline = 57, dx = -15, dy = 36 }, -- 3px of original airborne clearance
    front = { scale = 1, feet = 105, baseline = 62, dx = 0, dy = 2 }, -- 3px of original airborne clearance
  },
  mega_camerupt = {
    back = { scale = 1, feet = 126, baseline = 57, dx = -11, dy = 24 }, -- alpha bottom 126 (frame 126px)
    front = { scale = 1, feet = 129, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 129 (frame 129px)
  },
  mega_altaria = {
    back = { scale = 1, feet = 141, baseline = 57, dx = -7, dy = 87 }, -- alpha bottom 141 (frame 141px)
    front = { scale = 1, feet = 142, baseline = 62, dx = 0, dy = 53 }, -- alpha bottom 142 (frame 142px)
  },
  mega_banette = {
    back = { scale = 1, feet = 92, baseline = 57, dx = -13, dy = 26 }, -- alpha bottom 92 (frame 99px)
    front = { scale = 1, feet = 90, baseline = 62, dx = 0, dy = 3 }, -- alpha bottom 90 (frame 92px)
  },
  mega_absol = {
    back = { scale = 1, feet = 89, baseline = 57, dx = -5, dy = 30 }, -- alpha bottom 89 (frame 98px)
    front = { scale = 1, feet = 76, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 76 (frame 77px)
  },
  mega_glalie = {
    back = { scale = 1, feet = 116, baseline = 57, dx = -8, dy = 33 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 115, baseline = 62, dx = 0, dy = 0 }, -- 4px of original airborne clearance
  },
  mega_salamence = {
    back = { scale = 1, feet = 113, baseline = 57, dx = 0, dy = 43 }, -- 5px of original airborne clearance
    front = { scale = 1, feet = 112, baseline = 62, dx = -6, dy = 16 }, -- 5px of original airborne clearance
  },
  mega_metagross = {
    back = { scale = 1, feet = 117, baseline = 57, dx = -7, dy = 40 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 115, baseline = 62, dx = 0, dy = 16 }, -- 2px of original airborne clearance
  },
  mega_latias = {
    back = { scale = 1, feet = 121, baseline = 57, dx = -5, dy = 47 }, -- 6px of original airborne clearance
    front = { scale = 1, feet = 121, baseline = 62, dx = 3, dy = 16 }, -- 6px of original airborne clearance
  },
  mega_latios = {
    back = { scale = 1, feet = 145, baseline = 57, dx = -14, dy = 64 }, -- 6px of original airborne clearance
    front = { scale = 1, feet = 136, baseline = 62, dx = 2, dy = 21 }, -- 6px of original airborne clearance
  },
  mega_rayquaza = {
    back = { scale = 1, feet = 153, baseline = 57, dx = -28, dy = 60 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 147, baseline = 62, dx = 16, dy = 36 }, -- 4px of original airborne clearance
  },
  mega_lopunny = {
    back = { scale = 1, feet = 88, baseline = 57, dx = -14, dy = 34 }, -- alpha bottom 88 (frame 100px)
    front = { scale = 1, feet = 83, baseline = 62, dx = 0, dy = 1 }, -- alpha bottom 83 (frame 92px)
  },
  mega_garchomp = {
    back = { scale = 1, feet = 109, baseline = 57, dx = -12, dy = 34 }, -- alpha bottom 109 (frame 123px)
    front = { scale = 1, feet = 105, baseline = 62, dx = 1, dy = 8 }, -- alpha bottom 105 (frame 120px)
  },
  mega_lucario = {
    back = { scale = 1, feet = 77, baseline = 57, dx = -9, dy = 26 }, -- alpha bottom 77 (frame 77px)
    front = { scale = 1, feet = 76, baseline = 62, dx = -1, dy = 2 }, -- alpha bottom 76 (frame 76px)
  },
  mega_abomasnow = {
    back = { scale = 1, feet = 106, baseline = 57, dx = -19, dy = 29 }, -- alpha bottom 106 (frame 117px)
    front = { scale = 1, feet = 104, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 104 (frame 113px)
  },
  mega_gallade = {
    back = { scale = 1, feet = 88, baseline = 57, dx = -12, dy = 26 }, -- alpha bottom 88 (frame 98px)
    front = { scale = 1, feet = 92, baseline = 62, dx = 0, dy = 2 }, -- alpha bottom 92 (frame 105px)
  },
  mega_audino = {
    back = { scale = 1, feet = 63, baseline = 57, dx = -11, dy = 22 }, -- alpha bottom 63 (frame 63px)
    front = { scale = 1, feet = 63, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 63 (frame 63px)
  },
  mega_diancie = {
    back = { scale = 1, feet = 134, baseline = 57, dx = -7, dy = 60 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 135, baseline = 62, dx = -2, dy = 35 }, -- 4px of original airborne clearance
  },
  mega_raichu_x = {
    back = { scale = 1, feet = 111, baseline = 57, dx = -18, dy = 42 }, -- alpha bottom 111 (frame 121px)
    front = { scale = 1, feet = 102, baseline = 62, dx = 5, dy = 3 }, -- alpha bottom 102 (frame 130px)
  },
  mega_raichu_y = {
    back = { scale = 1, feet = 89, baseline = 57, dx = -26, dy = 22 }, -- alpha bottom 89 (frame 95px)
    front = { scale = 1, feet = 102, baseline = 62, dx = 7, dy = 2 }, -- alpha bottom 102 (frame 114px)
  },
  mega_clefable = {
    back = { scale = 1, feet = 100, baseline = 57, dx = -6, dy = 21 }, -- alpha bottom 100 (frame 121px)
    front = { scale = 1, feet = 102, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 102 (frame 126px)
  },
  mega_victreebel = {
    back = { scale = 1, feet = 127, baseline = 57, dx = -12, dy = 28 }, -- alpha bottom 127 (frame 127px)
    front = { scale = 1, feet = 138, baseline = 62, dx = 3, dy = 8 }, -- alpha bottom 138 (frame 138px)
  },
  mega_starmie = {
    back = { scale = 1, feet = 83, baseline = 57, dx = -13, dy = 29 }, -- 1px of original airborne clearance
    front = { scale = 1, feet = 84, baseline = 62, dx = -1, dy = 3 }, -- 1px of original airborne clearance
  },
  mega_dragonite = {
    back = { scale = 1, feet = 151, baseline = 57, dx = -19, dy = 53 }, -- alpha bottom 151 (frame 151px)
    front = { scale = 1, feet = 146, baseline = 62, dx = -2, dy = 21 }, -- alpha bottom 146 (frame 146px)
  },
  mega_meganium = {
    back = { scale = 1, feet = 89, baseline = 57, dx = -17, dy = 31 }, -- alpha bottom 89 (frame 89px)
    front = { scale = 1, feet = 97, baseline = 62, dx = -5, dy = 12 }, -- alpha bottom 97 (frame 97px)
  },
  mega_feraligatr = {
    back = { scale = 1, feet = 107, baseline = 57, dx = -15, dy = 36 }, -- alpha bottom 107 (frame 107px)
    front = { scale = 1, feet = 115, baseline = 62, dx = -2, dy = 4 }, -- alpha bottom 115 (frame 115px)
  },
  mega_skarmory = {
    back = { scale = 1, feet = 107, baseline = 57, dx = -24, dy = 44 }, -- alpha bottom 107 (frame 107px)
    front = { scale = 1, feet = 103, baseline = 62, dx = 1, dy = 16 }, -- alpha bottom 103 (frame 103px)
  },
  mega_chimecho = {
    back = { scale = 1, feet = 114, baseline = 57, dx = -24, dy = 43 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 111, baseline = 62, dx = -1, dy = 15 }, -- 4px of original airborne clearance
  },
  mega_absol_z = {
    back = { scale = 1, feet = 92, baseline = 57, dx = -14, dy = 35 }, -- alpha bottom 92 (frame 96px)
    front = { scale = 1, feet = 86, baseline = 62, dx = -3, dy = 3 }, -- alpha bottom 86 (frame 96px)
  },
  mega_staraptor = {
    back = { scale = 1, feet = 132, baseline = 57, dx = -8, dy = 50 }, -- 3px of original airborne clearance
    front = { scale = 1, feet = 147, baseline = 62, dx = 0, dy = 22 }, -- 3px of original airborne clearance
  },
  mega_garchomp_z = {
    back = { scale = 1, feet = 135, baseline = 57, dx = -9, dy = 55 }, -- alpha bottom 135 (frame 159px)
    front = { scale = 1, feet = 130, baseline = 62, dx = 4, dy = 27 }, -- alpha bottom 130 (frame 138px)
  },
  mega_lucario_z = {
    back = { scale = 1, feet = 78, baseline = 57, dx = -21, dy = 27 }, -- alpha bottom 78 (frame 82px)
    front = { scale = 1, feet = 84, baseline = 62, dx = 2, dy = 5 }, -- alpha bottom 84 (frame 88px)
  },
  mega_froslass = {
    back = { scale = 1, feet = 111, baseline = 57, dx = -19, dy = 48 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 107, baseline = 62, dx = 2, dy = 25 }, -- 3px of original airborne clearance
  },
  mega_heatran = {
    back = { scale = 1, feet = 130, baseline = 57, dx = -17, dy = 38 }, -- alpha bottom 130 (frame 134px)
    front = { scale = 1, feet = 139, baseline = 62, dx = -2, dy = 15 }, -- alpha bottom 139 (frame 153px)
  },
  mega_darkrai = {
    back = { scale = 1, feet = 123, baseline = 57, dx = -11, dy = 46 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 126, baseline = 62, dx = 0, dy = 9 }, -- 4px of original airborne clearance
  },
  mega_emboar = {
    back = { scale = 1, feet = 120, baseline = 57, dx = -31, dy = 35 }, -- alpha bottom 120 (frame 127px)
    front = { scale = 1, feet = 125, baseline = 62, dx = 12, dy = 5 }, -- alpha bottom 125 (frame 128px)
  },
  mega_excadrill = {
    back = { scale = 1, feet = 95, baseline = 57, dx = 0, dy = 31 }, -- alpha bottom 95 (frame 112px)
    front = { scale = 1, feet = 128, baseline = 62, dx = 0, dy = 2 }, -- alpha bottom 128 (frame 159px)
  },
  mega_scolipede = {
    back = { scale = 1, feet = 103, baseline = 57, dx = -9, dy = 31 }, -- alpha bottom 103 (frame 103px)
    front = { scale = 1, feet = 113, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 113 (frame 113px)
  },
  mega_scrafty = {
    back = { scale = 1, feet = 77, baseline = 57, dx = -20, dy = 24 }, -- alpha bottom 77 (frame 85px)
    front = { scale = 1, feet = 79, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 79 (frame 85px)
  },
  mega_eelektross = {
    back = { scale = 1, feet = 130, baseline = 57, dx = -28, dy = 36 }, -- alpha bottom 130 (frame 130px)
    front = { scale = 1, feet = 129, baseline = 62, dx = 15, dy = 11 }, -- 4px of original airborne clearance
  },
  mega_chandelure = {
    back = { scale = 1, feet = 124, baseline = 57, dx = -16, dy = 39 }, -- alpha bottom 124 (frame 124px)
    front = { scale = 1, feet = 124, baseline = 62, dx = -3, dy = 11 }, -- alpha bottom 124 (frame 124px)
  },
  mega_golurk = {
    back = { scale = 1, feet = 120, baseline = 57, dx = -12, dy = 39 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 115, baseline = 62, dx = 2, dy = 17 }, -- 4px of original airborne clearance
  },
  mega_chesnaught = {
    back = { scale = 1, feet = 159, baseline = 57, dx = -24, dy = 46 }, -- alpha bottom 159 (frame 159px)
    front = { scale = 1, feet = 151, baseline = 62, dx = -19, dy = 7 }, -- alpha bottom 151 (frame 162px)
  },
  mega_delphox = {
    back = { scale = 1, feet = 144, baseline = 57, dx = -26, dy = 57 }, -- alpha bottom 144 (frame 150px)
    front = { scale = 1, feet = 141, baseline = 62, dx = 3, dy = 35 }, -- alpha bottom 141 (frame 149px)
  },
  mega_greninja = {
    back = { scale = 1, feet = 117, baseline = 57, dx = -14, dy = 46 }, -- alpha bottom 117 (frame 117px)
    front = { scale = 1, feet = 116, baseline = 62, dx = -2, dy = 21 }, -- alpha bottom 116 (frame 116px)
  },
  mega_pyroar = {
    back = { scale = 1, feet = 101, baseline = 57, dx = -20, dy = 35 }, -- alpha bottom 101 (frame 101px)
    front = { scale = 1, feet = 100, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 100 (frame 100px)
    front_shiny = { scale = 1, feet = 92, baseline = 62, dx = 0, dy = 0 }, -- distinct shiny source frame
  },
  mega_floette = {
    back = { scale = 1, feet = 139, baseline = 57, dx = -12, dy = 27 }, -- alpha bottom 139 (frame 139px)
    front = { scale = 1, feet = 139, baseline = 62, dx = -1, dy = 5 }, -- alpha bottom 139 (frame 139px)
  },
  mega_meowstic = {
    back = { scale = 1, feet = 102, baseline = 57, dx = -14, dy = 40 }, -- alpha bottom 102 (frame 102px)
    front = { scale = 1, feet = 101, baseline = 62, dx = 4, dy = 18 }, -- alpha bottom 101 (frame 101px)
  },
  mega_meowstic_form_3 = {
    back = { scale = 1, feet = 96, baseline = 57, dx = -9, dy = 33 }, -- alpha bottom 96 (frame 96px)
    front = { scale = 1, feet = 101, baseline = 62, dx = 1, dy = 10 }, -- alpha bottom 101 (frame 102px)
  },
  mega_malamar = {
    back = { scale = 1, feet = 140, baseline = 57, dx = -9, dy = 63 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 139, baseline = 62, dx = 0, dy = 33 }, -- 4px of original airborne clearance
  },
  mega_barbaracle = {
    back = { scale = 1, feet = 97, baseline = 57, dx = -15, dy = 36 }, -- alpha bottom 97 (frame 97px)
    front = { scale = 1, feet = 97, baseline = 62, dx = -1, dy = 5 }, -- alpha bottom 97 (frame 97px)
  },
  mega_dragalge = {
    back = { scale = 1, feet = 134, baseline = 57, dx = -17, dy = 45 }, -- 4px of original airborne clearance
    front = { scale = 1, feet = 146, baseline = 62, dx = 0, dy = 11 }, -- 4px of original airborne clearance
  },
  mega_hawlucha = {
    back = { scale = 1, feet = 106, baseline = 57, dx = -13, dy = 37 }, -- alpha bottom 106 (frame 107px)
    front = { scale = 1, feet = 91, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 91 (frame 107px)
  },
  mega_zygarde = {
    back = { scale = 1, feet = 113, baseline = 57, dx = -22, dy = 37 }, -- alpha bottom 113 (frame 113px)
    front = { scale = 1, feet = 124, baseline = 62, dx = 0, dy = 23 }, -- alpha bottom 124 (frame 124px)
  },
  mega_zygarde_form_5 = {
    back = { scale = 1, feet = 113, baseline = 57, dx = -22, dy = 37 }, -- alpha bottom 113 (frame 113px)
    back_shiny = { scale = 1, feet = 124, baseline = 57, dx = 0, dy = 0 }, -- distinct shiny source frame
    front = { scale = 1, feet = 124, baseline = 62, dx = 0, dy = 23 }, -- alpha bottom 124 (frame 124px)
  },
  mega_crabominable = {
    back = { scale = 1, feet = 116, baseline = 57, dx = -13, dy = 42 }, -- alpha bottom 116 (frame 122px)
    front = { scale = 1, feet = 129, baseline = 62, dx = 0, dy = 6 }, -- alpha bottom 129 (frame 144px)
  },
  mega_golisopod = {
    back = { scale = 1, feet = 100, baseline = 57, dx = -19, dy = 36 }, -- alpha bottom 100 (frame 102px)
    front = { scale = 1, feet = 100, baseline = 62, dx = 1, dy = 3 }, -- alpha bottom 100 (frame 102px)
  },
  mega_drampa = {
    back = { scale = 1, feet = 125, baseline = 57, dx = -10, dy = 44 }, -- alpha bottom 125 (frame 125px)
    front = { scale = 1, feet = 117, baseline = 62, dx = 0, dy = 14 }, -- alpha bottom 117 (frame 117px)
  },
  mega_magearna = {
    back = { scale = 1, feet = 97, baseline = 57, dx = -10, dy = 33 }, -- alpha bottom 97 (frame 105px)
    front = { scale = 1, feet = 98, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 98 (frame 108px)
  },
  mega_magearna_original_color = {
    back = { scale = 1, feet = 97, baseline = 57, dx = -10, dy = 33 }, -- alpha bottom 97 (frame 105px)
    front = { scale = 1, feet = 98, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 98 (frame 108px)
  },
  mega_zeraora = {
    back = { scale = 1, feet = 130, baseline = 57, dx = -7, dy = 30 }, -- alpha bottom 130 (frame 130px)
    front = { scale = 1, feet = 127, baseline = 62, dx = 0, dy = 1 }, -- alpha bottom 127 (frame 137px)
  },
  mega_falinks = {
    back = { scale = 1, feet = 105, baseline = 57, dx = -10, dy = 27 }, -- alpha bottom 105 (frame 119px)
    front = { scale = 1, feet = 108, baseline = 62, dx = 0, dy = 0 }, -- alpha bottom 108 (frame 125px)
  },
  mega_scovillain = {
    back = { scale = 1, feet = 84, baseline = 57, dx = -8, dy = 24 }, -- alpha bottom 84 (frame 89px)
    front = { scale = 1, feet = 85, baseline = 62, dx = -1, dy = 3 }, -- alpha bottom 85 (frame 85px)
  },
  mega_glimmora = {
    back = { scale = 1, feet = 133, baseline = 57, dx = -11, dy = 58 }, -- alpha bottom 133 (frame 133px)
    front = { scale = 1, feet = 118, baseline = 62, dx = -2, dy = 18 }, -- alpha bottom 118 (frame 118px)
  },
  mega_tatsugiri_curly = {
    back = { scale = 1, feet = 98, baseline = 57, dx = -20, dy = 30 }, -- alpha bottom 98 (frame 119px)
    front = { scale = 1, feet = 118, baseline = 62, dx = 0, dy = 18 }, -- alpha bottom 118 (frame 129px)
  },
  mega_tatsugiri_droopy = {
    back = { scale = 1, feet = 91, baseline = 57, dx = -20, dy = 30 }, -- alpha bottom 91 (frame 111px)
    front = { scale = 1, feet = 112, baseline = 62, dx = 0, dy = 18 }, -- alpha bottom 112 (frame 122px)
  },
  mega_tatsugiri_stretchy = {
    back = { scale = 1, feet = 93, baseline = 57, dx = -20, dy = 30 }, -- alpha bottom 93 (frame 112px)
    front = { scale = 1, feet = 110, baseline = 62, dx = 0, dy = 18 }, -- alpha bottom 110 (frame 115px)
  },
  mega_baxcalibur = {
    back = { scale = 1, feet = 128, baseline = 57, dx = -20, dy = 30 }, -- alpha bottom 128 (frame 134px)
    front = { scale = 1, feet = 125, baseline = 62, dx = 0, dy = 4 }, -- alpha bottom 125 (frame 132px)
  },
}
