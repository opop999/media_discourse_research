library(dplyr)
library(datapasta)
# Get tribble from existing dataset with datapasta::dpasta(df)
# Add entries interactively media_organizations_df <- edit(media_organizations_df)
# We can always format the spaces of the tribble by piping it to %>% datapasta::dpasta()

media_organizations_df <- tibble::tribble(
             ~media_name,    ~type,                             ~url,                    ~fb_page,         ~fb_ads_id,      ~twitter_acc,    ~instagram_acc, ~newton_id, ~classification,
             "ol_a2larm", "online",             "https://a2larm.cz/",                    "A2larm",  "623521487687579",          "A2larm",       "a2larm.cz",    "17564",            "am",
            "ol_novinky", "online",            "https://novinky.cz/",                "Novinky.cz",     "202451429883",       "novinkycz",      "novinky.cz",     "3040",    "mainstream",
       "ol_seznamzpravy", "online",       "https://seznamzpravy.cz/",              "SeznamZpravy", "1737035843238717",    "SeznamZpravy",    "seznamzpravy",     "6306",    "mainstream",
              "ol_idnes", "online",              "https://idnes.cz/",                  "iDNES.cz",     "100683176313",         "iDNEScz",         "idnescz",    "18736",    "mainstream",
           "ol_aktualne", "online",           "https://aktualne.cz/",               "Aktualne.cz",     "137301989386",      "Aktualnecz",     "aktualne.cz",     "1806",    "mainstream",
    "ol_nazory_aktualne", "online",    "https://nazory.aktualne.cz/",            "NazoryAktualne",  "256326307781927", "Nazory_Aktualne",                NA,     "3452",    "mainstream",
              "ol_denik", "online",              "https://denik.cz/",                  "denik.cz",     "206045673805",         "denikcz",        "denik.cz",     "3397",    "mainstream",
              "ol_blesk", "online",              "https://blesk.cz/",                  "blesk.cz",     "206407509818",        "Blesk24",        "blesk.cz",      "2193",    "mainstream",
             "ol_reflex", "online",             "https://reflex.cz/",                  "reflexcz",      "34825122262",       "Reflex_cz",       "reflex_cz",     "2194",    "mainstream",
               "ol_nova", "online",            "https://tn.nova.cz/",           "televizninoviny",     "142069753862", "televizninoviny", "televizninoviny",    "16962",    "mainstream",
               "ol_ct24", "online", "https://ct24.ceskatelevize.cz/",                   "CT24.cz",     "137067469008",        "CT24zive",        "ct24zive",   "142981",        "public",
          "ol_cnn_prima", "online",         "https://cnn.iprima.cz/",                  "cnnprima", "2214398435317853",        "CNNPrima",        "cnnprima",     "1184",    "mainstream",
             "ol_echo24", "online",             "https://echo24.cz/",               "denikecho24",  "751578688203935",        "echo24cz",                NA,      "234",            "am",
            "ol_forum24", "online",            "https://forum24.cz/",                "forum24.cz",  "694807680694998",        "FORUM_24",        "forum.24",    "17348",            "am",
    "ol_denikreferendum", "online",    "https://denikreferendum.cz/",               "Dreferendum",     "203833483473",     "Dreferendum",                NA,     "3649",            "am",
   "ol_parlamentnilisty", "online",   "https://parlamentnilisty.cz/",       "parlamentnilisty.cz",  "135144949863739",  "parlamentky_cz",                NA,     "3608",            "am",
               "ol_ac24", "online",               "https://ac24.cz/",                   "AC24.cz",  "176546515755264",          "AC24cz",         "ac24.cz",      "264",            "am",
       # "ol_svetkolemnas", "online",       "http://svetkolemnas.info",         "svetkolemnas.info",  "342117105834888",                NA,                NA,         NA,            "am", # not in Newton dataset
           "ol_irozhlas", "online",           "https://irozhlas.cz/",               "iROZHLAS.cz",     "123858471641",      "iROZHLAScz",      "irozhlascz",     "2234",        "public",
        "ol_ceskenoviny", "online",        "https://ceskenoviny.cz/",                    "CTK.cz",     "291919391972",  "ceskenoviny_cz", "czechnewsagency",     "4774",        "public",
            "ol_lidovky", "online",            "https://lidovky.cz/",                "lidovky.cz",      "88822578037",         "lidovky",         "lidovky",     "2842",    "mainstream",
            "ol_sputnik", "online",    "https://cz.sputniknews.com/",                "cz.sputnik",  "340208672684617",                NA,                NA,    "19952",            "am",
  "ol_hospodarskenoviny", "online",                 "https://hn.cz/",                "hospodarky",      "93433992603",      "hospodarky",      "hospodarky",     "1423",    "mainstream",
            "rad_impuls",  "radio",             "https://impuls.cz/",                  "raaaadio",     "167422257241",     "ImpulsRadio", "raaaadio_impuls",     "3021",    "mainstream",
          "tv_barrandov",     "TV",          "https://barrandov.tv/",               "tvbarrandov",      "86928477031",      "Tbarrandov",     "barrandovtv",      "185",            "am",
             "ol_blisty", "online",             "https://blisty.cz/",              "britskelisty",  "825350200914537",          "blisty",                NA,     "3224",            "am",
              "ol_tyden", "online",              "https://tyden.cz/",                     "tyden",  "114811848586566",         "Tydencz",                NA,     "2657",    "mainstream",
         "ol_blog_idnes", "online",         "https://blog.idnes.cz/",                 "blogidnes",  "191574701031010",                NA,                NA,     "3770",    "mainstream",
       "ol_zpravy_idnes", "online",       "https://zpravy.idnes.cz/",                          NA,                 NA,                NA,                NA,     "3036",    "mainstream",
         "ol_eurozpravy", "online",         "https://eurozpravy.cz/",             "EuroZpravy.cz",  "120250914680166",    "EuroZpravycz",    "eurozpravycz",     "4738",    "mainstream",
                "ol_e15", "online",                "https://e15.cz/",                  "denikE15",  "228361180513562",         "E15news",         "e15news",     "3406",    "mainstream",
               "ol_info", "online",               "https://info.cz/",               "INFOInfo.cz", "1269502056393120",      "infocz_web",         "info.cz",    "12465",    "mainstream",
            "ol_respekt", "online",            "https://respekt.cz/",            "tydenikrespekt",      "52479821102",      "RESPEKT_CZ",       "respektcz",     "3542",    "mainstream",
          "ol_echoprime", "online",          "https://echoprime.cz/",               "echoprimecz",  "249071368789929",     "echoprimecz",                NA,    "28222",            "am",
               "ol_euro", "online",               "https://euro.cz/",               "Euroteckacz",  "110671101091996",     "Euroteckacz",                NA,     "3407",    "mainstream",
            "ol_tiscali", "online",     "https://zpravy.tiscali.cz/",                "tiscali.cz",  "119778841394355",      "tiscali_cz",                NA,       "81",    "mainstream",
              "ol_tnbiz", "online",              "https://tnbiz.cz/",                          NA,                 NA,                NA,                NA,     "3623",    "mainstream",
              "ol_globe", "online",            "https://globe24.cz/",                "globe24.cz", "1746059345623412",       "Globe24cz",                NA,     "6192",    "mainstream",
             "ol_denikn", "online",             "https://denikn.cz/",                    "enkocz",  "192989578217526",          "enkocz",          "enkocz",    "71909",    "mainstream",
            "ol_rukojmi", "online",            "https://rukojmi.cz/", "Rukojmicz-113066090412619",  "113066090412619",                NA,                NA,     "6335",            "am",
           "ol_roklen24", "online",           "https://roklen24.cz/",                  "Roklen24",  "631911050212445",        "roklen24",                NA,     "4107",    "mainstream",
        "ol_24zpravycom", "online",          "https://24zpravy.com/",                          NA,                 NA,                NA,                NA,    "52817",            "am",
    "ol_securitymagazin", "online",    "https://securitymagazin.cz/",           "securmagazin.cz", "1480089088925714",    "SecurMagazin",                NA,    "12470",            "am",
                "ol_zet", "online",                 "http://zet.cz/",                  "RadioZcz",  "103923024523450",        "RadioZcz",                NA,     "4085",    "mainstream",
       "ol_byznysnoviny", "online",       "https://byznysnoviny.cz/",              "byznysnoviny", "1732377363666694",    "Byznysnoviny",                NA,     "5533",            "am",
         "ol_halonoviny", "online",         "https://halonoviny.cz/",             "Halonoviny.cz",  "379600488789567",      "halonoviny",                NA,     "4486",            "am",
       "ol_krajskelisty", "online",       "https://krajskelisty.cz/",              "krajskelisty",  "531722940204240",    "krajskelisty",                NA,      "123",            "am",
            "ol_express", "online",             "https://expres.cz/",                 "expres.cz", "1477502522567102",        "ExpresCZ",        "exprescz",     "5940",    "mainstream"
  )


# Save Twitter Account Ids
saveRDS(media_organizations_df$twitter_acc, file = "1.data_sources/twitter/twitter_acc_ids.rds")

# Save Facebook Account names
saveRDS(media_organizations_df$fb_page, file = "1.data_sources/facebook/facebook_acc_ids.rds")

# Save Facebook Account names
saveRDS(media_organizations_df$fb_ads_id, file = "1.data_sources/facebook/num_facebook_acc_ids.rds")

# Save Instagram Account names
saveRDS(media_organizations_df$instagram_acc, file = "1.data_sources/instagram/instagram_acc_ids.rds")


### Notes on the process
# Using the dataset with counts of the migration-related articles (searched for with our string) by media outlets in the Newton database,
# we identify the most important media outlets and cross-reference them with the Newton ID dataset to get their numeric identifier.

### Data issues
# Blesk magazine also has an older, much less used twitter account blesk_cz. Not included in the index.
# Svetkolemna.info not in the Newton dataset
# Sputnik news could also have newton ID of 106137. It is necessary to verify validity.
# Krajskelisty's twitter seems to be inactive since 2013, hence no records in our dataset



joined_df <- inner_join(newton_media_list_of_outlets, newton_migration_articles_by_media, by = "media_name") %>% arrange(desc(n))
