# Searching with exactly specified features is a magnitude faster than with
# regex's positive lookbehind.
df <- df %>%
    mutate(animacy = str_extract(feats, pattern = "Anim|Inan"),
           word_case = str_extract(feats, pattern = "Acc|Dat|Gen|Ins|Loc|Nom|Voc"),
           number = str_extract(feats, pattern = "Dual|Plur|Sing"),
           gender = str_extract(feats, pattern = "Fem,Masc|Fem,Neut|Fem|Masc|Neut"),
           person = str_extract(feats, pattern = "1|2|3"),
           verb_tense = str_extract(feats, pattern = "Fut|Past|Pres"),
           verb_form = str_extract(feats, pattern = "Conv|Fin|Inf|Part"),
           voice = str_extract(feats, pattern = "Act|Pass"),
           name_type = str_extract(feats, pattern = "Com|Geo|Giv|Nat|Oth|Pro|Sur"),
           mood = str_extract(feats, pattern = "Cnd|Imp|Ind"),
           pron_type = str_extract(feats, pattern = "Dem|Emp|Ind|Int|Neg|Prs|Rel|Tot")
           )






