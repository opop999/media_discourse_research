# 0. Load necessary packages & dataset ----------------------------------------------
packages <- c("dplyr", "TraMineR", "stringr", "purrr", "tidytext", "tidyr", "forcats", "cluster", "NbClust", "gt", "gtExtras", "ggplot2", "umap")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# Load dataset with all migration content and join it with dataset of dates and media types

words <- readRDS("4.data_analysis/frequencies/data/key_words_per_doc.rds")
media_labels <- readRDS("1.data_sources/media_articles/data/media_type_labels/all_media_labels_with_doc_id.rds")
media_labels_summary <- readRDS("1.data_sources/media_articles/data/media_type_labels/joined_labels_df.rds")
dates <- readRDS("4.data_analysis/frequencies/data/doc_id_by_date.rds")
annotated_media_types_basic <- list.files(path = "1.data_sources/media_articles/data/annotations/chunks/",
                                          pattern = "*.rds",
                                          full.names = TRUE) %>%
                                          map_dfr(readRDS) %>%
                                          transmute(article_id = code,
                                                    media_type_basic = mediaType.id,
                                                    name = sourceName,
                                                    date = as.Date(cut(as.Date(datePublished), breaks = "6 months")))
recoded_factor <- c("refugee_term" = "azylant",
                    "refugee_term" = "azylanta",
                    "refugee_term" = "azylanté",
                    "refugee_term" = "azylanti",
                    "refugee_term" = "azylantské",
                    "refugee_term" = "azylantů",
                    "refugee_term" = "azylanty",
                    "refugee_term" = "běženec",
                    "refugee_term" = "běženectví",
                    NULL = "chodili",
                    "migration_term" = "imigra",
                    "migration_term" = "imigrace",
                    "migration_term" = "imigracecz",
                    "migration_term" = "imigraci",
                    "migration_term" = "imigrací",
                    "migration_term" = "imigračné",
                    "migration_term" = "imigračného",
                    "migration_term" = "imigračnej",
                    "migration_term" = "imigrační",
                    "migration_term" = "imigračních",
                    "migration_term" = "imigračního",
                    "migration_term" = "imigračním",
                    "migration_term" = "imigračními",
                    "migration_term" = "imigrafická",
                    "migration_term" = "imigrant",
                    "migration_term" = "imigranta",
                    "migration_term" = "imigrante",
                    "migration_term" = "imigrantech",
                    "migration_term" = "imigrantem",
                    "migration_term" = "imigranti",
                    "migration_term" = "imigrantka",
                    "migration_term" = "imigrantky",
                    "migration_term" = "imigrantmi",
                    "migration_term" = "imigrantom",
                    "migration_term" = "imigrantov",
                    "migration_term" = "imigrantovi",
                    "migration_term" = "imigrantska",
                    "migration_term" = "imigrantské",
                    "migration_term" = "imigrantského",
                    "migration_term" = "imigrantskému",
                    "migration_term" = "imigrantský",
                    "migration_term" = "imigrantských",
                    "migration_term" = "imigrantskými",
                    "migration_term" = "imigrantství",
                    "migration_term" = "imigrantů",
                    "migration_term" = "imigrantum",
                    "migration_term" = "imigrantům",
                    "migration_term" = "imigranty",
                    "migration_term" = "migrac",
                    "migration_term" = "migrace",
                    "migration_term" = "migraci",
                    "migration_term" = "migrací",
                    "migration_term" = "migracích",
                    "migration_term" = "migracihovory",
                    "migration_term" = "migracii",
                    "migration_term" = "migracím",
                    "migration_term" = "migračné",
                    "migration_term" = "migračně",
                    "migration_term" = "migračnej",
                    "migration_term" = "migrační",
                    "migration_term" = "migračních",
                    "migration_term" = "migračního",
                    "migration_term" = "migračním",
                    "migration_term" = "migračními",
                    "migration_term" = "migračných",
                    NULL = "migraine",
                    "migration_term" = "migrančmní",
                    "migration_term" = "migrans",
                    "migration_term" = "migrant",
                    "migration_term" = "migranta",
                    "migration_term" = "migrantech",
                    "migration_term" = "migrantek",
                    "migration_term" = "migrantem",
                    "migration_term" = "migrantes",
                    "migration_term" = "migranti",
                    "migration_term" = "migrantka",
                    "migration_term" = "migrantky",
                    "migration_term" = "migrantov",
                    "migration_term" = "migrantovy",
                    "migration_term" = "migrantská",
                    "migration_term" = "migrantské",
                    "migration_term" = "migrantských",
                    "migration_term" = "migrantským",
                    "migration_term" = "migrantů",
                    "migration_term" = "migrantům",
                    "migration_term" = "migranty",
                    "migration_term" = "migration",
                    "migration_term" = "přistěhoval",
                    "migration_term" = "přistěhovala",
                    "migration_term" = "přistěhovalá",
                    "migration_term" = "přistěhovalce",
                    "migration_term" = "přistěhovalci",
                    "migration_term" = "přistěhovalců",
                    "migration_term" = "přistěhovalcům",
                    "migration_term" = "přistěhovalé",
                    "migration_term" = "přistěhovalec",
                    "migration_term" = "přistěhovalecká",
                    "migration_term" = "přistěhovalecké",
                    "migration_term" = "přistěhovaleckého",
                    "migration_term" = "přistěhovaleckých",
                    "migration_term" = "přistěhovalectví",
                    "migration_term" = "přistěhovali",
                    "migration_term" = "přistěhovalí",
                    "migration_term" = "přistěhovalo",
                    "migration_term" = "přistěhovaly",
                    "migration_term" = "přistěhovalých",
                    "migration_term" = "přistěhovalým",
                    "migration_term" = "přistěhovalými",
                    "refugee_term" = "uprchl",
                    "refugee_term" = "uprchla",
                    "refugee_term" = "uprchlá",
                    "refugee_term" = "uprchlé",
                    "refugee_term" = "uprchlého",
                    "refugee_term" = "uprchlém",
                    "refugee_term" = "uprchlému",
                    "refugee_term" = "uprchli",
                    "refugee_term" = "uprchlí",
                    "refugee_term" = "uprchlice",
                    "refugee_term" = "uprchlicemi",
                    "refugee_term" = "uprchlici",
                    "refugee_term" = "uprchlicí",
                    "refugee_term" = "uprchlíci",
                    "refugee_term" = "uprchlících",
                    "refugee_term" = "uprchlická",
                    "refugee_term" = "uprchlicke",
                    "refugee_term" = "uprchlické",
                    "refugee_term" = "uprchlického",
                    "refugee_term" = "uprchlickém",
                    "refugee_term" = "uprchlickou",
                    "refugee_term" = "uprchlický",
                    "refugee_term" = "uprchlických",
                    "refugee_term" = "uprchlictví",
                    "refugee_term" = "uprchlík",
                    "refugee_term" = "uprchlíka",
                    "refugee_term" = "uprchlíkama",
                    "refugee_term" = "uprchlíkem",
                    "refugee_term" = "uprchlíkovi",
                    "refugee_term" = "uprchlíku",
                    "refugee_term" = "uprchlíků",
                    "refugee_term" = "uprchlíkům",
                    "refugee_term" = "uprchlíky",
                    "refugee_term" = "uprchlo",
                    "refugee_term" = "uprchlou",
                    "refugee_term" = "uprchly",
                    "refugee_term" = "uprchlý",
                    "refugee_term" = "uprchlých",
                    "refugee_term" = "uprchlým",
                    "refugee_term" = "uprchlými",
                    "refugee_term" = "utečence",
                    "refugee_term" = "utečenci",
                    "refugee_term" = "utečencom",
                    "refugee_term" = "utečencov",
                    "refugee_term" = "utečenců",
                    "refugee_term" = "utečenec",
                    "refugee_term" = "utečenecká",
                    "refugee_term" = "utečenecké",
                    "refugee_term" = "utečeneckého",
                    "refugee_term" = "utečeneckém",
                    "refugee_term" = "utečeneckom",
                    "refugee_term" = "utečenkyňou",
                    NULL = "13",
                    NULL = "3",
                    NULL = "43",
                    NULL = "at",
                    "refugee_term" = "azylantech",
                    "refugee_term" = "azylantek",
                    "refugee_term" = "azylantem",
                    "refugee_term" = "azylantka",
                    "refugee_term" = "azylantku",
                    "refugee_term" = "azylantky",
                    "refugee_term" = "azylantovi",
                    "refugee_term" = "azylantský",
                    "refugee_term" = "azylantských",
                    "refugee_term" = "azylantům",
                    NULL = "bandcamp",
                    "refugee_term" = "běženecká",
                    "refugee_term" = "běženecké",
                    "refugee_term" = "běženecky",
                    "refugee_term" = "běženeckých",
                    "refugee_term" = "běženkyně",
                    "refugee_term" = "běženkyni",
                    "refugee_term" = "běženkyním",
                    NULL = "com",
                    NULL = "cz",
                    NULL = "do",
                    "migration_term" = "imigračná",
                    "migration_term" = "imigračně",
                    "migration_term" = "imigračnému",
                    "migration_term" = "imigračněprávní",
                    "migration_term" = "imigracni",
                    "migration_term" = "imigracní",
                    "migration_term" = "imigračnímu",
                    "migration_term" = "imigračnou",
                    "migration_term" = "imigračných",
                    "migration_term" = "imigračným",
                    "migration_term" = "imigran",
                    "migration_term" = "imigrankprotože",
                    "migration_term" = "imigrantama",
                    "migration_term" = "imigrantce",
                    "migration_term" = "imigrantek",
                    "migration_term" = "imigrantkám",
                    "migration_term" = "imigrantkami",
                    "migration_term" = "imigrantkou",
                    "migration_term" = "imigrantku",
                    "migration_term" = "imigrantoch",
                    "migration_term" = "imigrantovu",
                    "migration_term" = "imigrantská",
                    "migration_term" = "imigrantskej",
                    "migration_term" = "imigrantském",
                    "migration_term" = "imigrantsko",
                    "migration_term" = "imigrantskou",
                    "migration_term" = "imigrantským",
                    "migration_term" = "imigrantští",
                    "migration_term" = "imigrantu",
                    "migration_term" = "imigraotnovi",
                    "migration_term" = "imigratnských",
                    "migration_term" = "imigratů",
                    NULL = "it",
                    NULL = "js",
                    NULL = "k",
                    NULL = "ma",
                    NULL = "měla",
                    "migration_term" = "migra",
                    "migration_term" = "migrač",
                    "migration_term" = "migracemi",
                    "migration_term" = "migracena",
                    "migration_term" = "migracev",
                    "migration_term" = "migraceza",
                    "migration_term" = "migracezarazitúplně",
                    "migration_term" = "migracia",
                    "migration_term" = "migracja",
                    "migration_term" = "migracje",
                    "migration_term" = "migracji",
                    "migration_term" = "migračmigračje",
                    "migration_term" = "migračná",
                    "migration_term" = "migračného",
                    "migration_term" = "migračněhumanitární",
                    "migration_term" = "migracni",
                    "migration_term" = "migračnim",
                    "migration_term" = "migračnímu",
                    "migration_term" = "migračnú",
                    "migration_term" = "migračný",
                    NULL = "migraines",
                    NULL = "migralgin",
                    NULL = "migramah",
                    NULL = "migran",
                    NULL = "migranas",
                    NULL = "migrance",
                    "migration_term" = "migranční",
                    NULL = "migrane",
                    NULL = "migranea",
                    NULL = "migranetem",
                    NULL = "migrano",
                    "migration_term" = "migranstvem",
                    "migration_term" = "migrantce",
                    "migration_term" = "migrante",
                    "migration_term" = "migranten",
                    NULL = "migrantiek",
                    "migration_term" = "migrantin",
                    NULL = "migrantium",
                    NULL = "migrantiv",
                    "migration_term" = "migrantkách",
                    "migration_term" = "migrantkám",
                    "migration_term" = "migrantkami",
                    "migration_term" = "migrantkou",
                    "migration_term" = "migrantku",
                    "migration_term" = "migrantkypokud",
                    "migration_term" = "migrantom",
                    "migration_term" = "migrantos",
                    "migration_term" = "migrantova",
                    "migration_term" = "migrantovi",
                    "migration_term" = "migrants",
                    "migration_term" = "migrantského",
                    "migration_term" = "migrantskej",
                    "migration_term" = "migrantskou",
                    "migration_term" = "migrantský",
                    "migration_term" = "migrantství",
                    "migration_term" = "migrantu",
                    "migration_term" = "migrare",
                    NULL = "migrastatické",
                    NULL = "migrastatickou",
                    NULL = "migrastatik",
                    NULL = "migrastatika",
                    "migration_term" = "migrate",
                    "migration_term" = "migrated",
                    "migration_term" = "migrates",
                    "migration_term" = "migratie",
                    "migration_term" = "migrating",
                    "migration_term" = "migrationhealth",
                    "migration_term" = "migrations",
                    "migration_term" = "migrationsfeindlichen",
                    "migration_term" = "migrationskritischen",
                    "migration_term" = "migratoire",
                    "migration_term" = "migratoria",
                    "migration_term" = "migratorius",
                    "migration_term" = "migratorní",
                    "migration_term" = "migratory",
                    NULL = "na",
                    "migration_term" = "přistěhovalcem",
                    "migration_term" = "přistěhovalcích",
                    "migration_term" = "přistěhovalcina",
                    "migration_term" = "přistěhovaleckému",
                    "migration_term" = "přistěhovaleckou",
                    "migration_term" = "přistěhovalecký",
                    "migration_term" = "přistěhovaleckým",
                    "migration_term" = "přistěhovaleckými",
                    "migration_term" = "přistěhovalectvím",
                    "migration_term" = "přistěhovalého",
                    "migration_term" = "přistěhovalému",
                    "migration_term" = "přistěhovalkyň",
                    "migration_term" = "přistěhovalkyně",
                    "migration_term" = "přistěhovalkyni",
                    "migration_term" = "přistěhovalou",
                    "migration_term" = "přistěhovalsů",
                    "migration_term" = "přistěhovalý",
                    "refugee_term" = "uprchlci",
                    "refugee_term" = "uprchle",
                    "refugee_term" = "uprchlic",
                    "refugee_term" = "uprchlící",
                    "refugee_term" = "uprchlíci1",
                    "refugee_term" = "uprchlicích",
                    "refugee_term" = "uprchlicím",
                    "refugee_term" = "uprchlickéhotáborajde",
                    "refugee_term" = "uprchlickému",
                    "refugee_term" = "uprchlicky",
                    "refugee_term" = "uprchlickýho",
                    "refugee_term" = "uprchlickým",
                    "refugee_term" = "uprchlickými",
                    "refugee_term" = "uprchličtí",
                    "refugee_term" = "uprchlictvím",
                    "refugee_term" = "uprchlíkovy",
                    "refugee_term" = "uprchliku",
                    "refugee_term" = "uprchlikuv",
                    "refugee_term" = "uprchliky",
                    "refugee_term" = "uprchlíkyproč",
                    "refugee_term" = "utečená",
                    "refugee_term" = "utečencami",
                    "refugee_term" = "utečenče",
                    "refugee_term" = "utečencem",
                    "refugee_term" = "utečencích",
                    "refugee_term" = "utečencům",
                    "refugee_term" = "utečeneckej",
                    "refugee_term" = "utečeneckou",
                    "refugee_term" = "utečenecku",
                    "refugee_term" = "utečenecký",
                    "refugee_term" = "utečeneckých",
                    "refugee_term" = "utečenectva",
                    "refugee_term" = "utečenectví",
                    "refugee_term" = "utečeni",
                    "refugee_term" = "utečení",
                    "refugee_term" = "utečenka",
                    "refugee_term" = "utečeny",
                    "refugee_term" = "utečený",
                    "refugee_term" = "utečených",
                    NULL = "az",
                    NULL = "čím",
                    NULL = "gob",
                    "migration_term" = "imigračn",
                    "migration_term" = "imigračněprávních",
                    "migration_term" = "imigracního",
                    "migration_term" = "imigračnim",
                    "migration_term" = "imigračnú",
                    "migration_term" = "imigračnými",
                    "migration_term" = "imigrantú",
                    "migration_term" = "imigraty",
                    NULL = "jpg",
                    "migration_term" = "migracebrbr",
                    "migration_term" = "migraceinfo",
                    "migration_term" = "migraceing",
                    "migration_term" = "migraceonline",
                    "migration_term" = "migracion",
                    "migration_term" = "migraciplatforma",
                    "migration_term" = "migračnívlna",
                    "migration_term" = "migračnou",
                    "migration_term" = "migracnu",
                    NULL = "migrad",
                    NULL = "migrainefacts",
                    NULL = "migrainefoundation",
                    NULL = "migraineresearchfoundation",
                    NULL = "migrainesknee",
                    NULL = "migrainesummit2017",
                    NULL = "migraineux",
                    NULL = "migrastatická",
                    NULL = "migrastatickým",
                    NULL = "migrate2rocky",
                    "migration_term" = "migratepage",
                    "migration_term" = "migrati",
                    "migration_term" = "migrationology",
                    "migration_term" = "migratori",
                    NULL = "migratorybirdfestival",
                    "migration_term" = "migravoat",
                    "migration_term" = "migrazione",
                    NULL = "mimmo",
                    NULL = "ministerstvo",
                    NULL = "ne",
                    NULL = "pokud",
                    NULL = "potom",
                    "migration_term" = "přistěhovaleckém",
                    "migration_term" = "přistěhovalečtí",
                    "migration_term" = "přistěhovalství",
                    "refugee_term" = "uprchleho",
                    "refugee_term" = "uprchlícivýraznou",
                    "refugee_term" = "uprchlíciz",
                    "refugee_term" = "uprchlíkůjihokorejský",
                    "refugee_term" = "uprchlíkůmatthew",
                    "refugee_term" = "utečenca",
                    "refugee_term" = "utečencoch",
                    "refugee_term" = "utečené",
                    "refugee_term" = "utečenej",
                    "refugee_term" = "utečenku",
                    "refugee_term" = "utečenky"
)

#########################
# For exploratory purposes, we can create the a dataset with counts of migration-related terms
# by period and media type.

normalit <- function(m) {
(m - min(m)) / (max(m) - min(m))
}

media_migration_term_counts <- words %>%
  inner_join(media_labels, by = c("article_id" = "doc_id")) %>%
  select(media_type, name, article_id, text) %>%
  inner_join(dates, by = c("article_id" = "doc_id")) %>%
  mutate(text = gsub(x = text, pattern = "[[:punct:]]", " "),
         date = as.Date(cut(date, breaks = "1 month"))) %>%
  filter(nchar(text) > 0) %>%
  unnest_tokens(input = text, output = token) %>%
  select(-article_id) %>%
  filter(!media_type %in% c("institution_web", "irrelevant", "other")) %>%
  mutate(media_type = fct_collapse(media_type, alternative = c("antisystem", "political_tabloid"))) %>%
  group_by(name, date) %>%
  summarise(media_type = first(media_type), n = n()) %>%
  ungroup() %>%
  group_by(media_type) %>%
  mutate(n_scaled = normalit(n)) %>%
  ungroup()


######################## Sequence analysis of media aggregated to their media types
seq_df_media_type_aggregated <- words %>%
  inner_join(media_labels, by = c("article_id" = "doc_id")) %>%
  select(article_id, media_type, text) %>%
  inner_join(dates, by = c("article_id" = "doc_id")) %>%
  mutate(text = gsub(x = text, pattern = "[[:punct:]]", " "),
         date = as.Date(cut(date, breaks = "month"))) %>%
  filter(nchar(text) > 0) %>%
  unnest_tokens(input = text, output = token) %>%
  select(-article_id) %>%
  filter(!media_type %in% c("institution_web", "irrelevant", "other")) %>%
  mutate(media_type = fct_collapse(media_type, alternative = c("antisystem", "political_tabloid"))) %>%
  group_by(media_type, date) %>%
  count(token) %>%
  slice_max(n, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(media_type, date, token = fct_recode(token, !!!recoded_factor[recoded_factor %in% .[["token"]]])) %>%
  filter(!is.na(token)) %>%
  pivot_wider(names_from = date, values_from = token)

saveRDS(seq_df_media_type_aggregated, "4.data_analysis/sequence_analysis/data/seq_df_media_type_aggregated_1mth.rds")

################################# Sequence analysis of individual media for which we have media type labels
# For all media that we have media type information
seq_df_media_type <- words %>%
  inner_join(media_labels, by = c("article_id" = "doc_id")) %>%
  select(media_type, name, article_id, text) %>%
  inner_join(dates, by = c("article_id" = "doc_id")) %>%
  mutate(text = gsub(x = text, pattern = "[[:punct:]]", " "),
         date = as.Date(cut(date, breaks = "6 months"))) %>%
  filter(nchar(text) > 0) %>%
  unnest_tokens(input = text, output = token) %>%
  select(-article_id) %>%
  filter(!media_type %in% c("institution_web", "irrelevant", "other")) %>%
  mutate(media_type = fct_collapse(media_type, alternative = c("antisystem", "political_tabloid"))) %>%
  group_by(name, date, token) %>%
  summarise(media_type = first(media_type), n = n()) %>%
  slice_max(n, n = 3, with_ties = FALSE) %>% # Get top three tokens, so it is managable to recode them manually
  ungroup() %>%
  transmute(name,
            date,
            media_type,
            token = fct_recode(token, !!!recoded_factor[recoded_factor %in% .[["token"]]]), n) %>%
  filter(!is.na(token)) %>%
  group_by(name, date) %>%
  slice_max(n, n = 1, with_ties = FALSE) %>% # Finally, limit ourselves to the most prevalent
  ungroup() %>%
  select(-n) %>%
  pivot_wider(names_from = date, values_from = token)

saveRDS(seq_df_media_type, "4.data_analysis/sequence_analysis/data/seq_df_media_type_6mth.rds")

################################# Sequence analysis of individual media for which we only have the basic type description
# Get "basic" media type (2: Internet, 3: Radio, 4: Television, 5: Print)
seq_df_all_media <- words %>%
  inner_join(annotated_media_types_basic, by = "article_id") %>%
  mutate(text = gsub(x = text, pattern = "[[:punct:]]", replacement = " ")) %>%
  filter(nchar(text) > 0) %>%
  unnest_tokens(input = text, output = token) %>%
  select(-article_id) %>%
  group_by(name, date, token) %>%
  summarise(media_type_basic = first(media_type_basic), n = n()) %>%
  slice_max(n, n = 3, with_ties = FALSE) %>% # Get top three tokens, so it is managable to recode them manually
  ungroup() %>%
  transmute(name,
            date,
            media_type_basic = factor(media_type_basic, levels = c("2", "3", "4", "5"), labels = c("internet", "radio", "television", "print")),
            token = fct_recode(token, !!!recoded_factor[recoded_factor %in% .[["token"]]]), n) %>%
  filter(!is.na(token)) %>%
  group_by(name, date) %>%
  slice_max(n, n = 1, with_ties = FALSE) %>% # Finally, limit ourselves to the most prevalent
  ungroup() %>%
  select(-n) %>%
  pivot_wider(names_from = date, values_from = token)

saveRDS(seq_df_all_media, "4.data_analysis/sequence_analysis/data/seq_df_all_media_6mth.rds")

# Analysis ----------------------------------------------------------------

# Load datasets, and create sequence objects ------------------------------

# Media types aggregated as a group, 1 month aggregation
seq_df_media_type_aggregated <- readRDS("4.data_analysis/sequence_analysis/data/seq_df_media_type_aggregated_1mth.rds")
seq_object_media_type_aggregated <- seqdef(seq_df_media_type_aggregated, var = 2:ncol(seq_df_media_type_aggregated))

# Media with type labels, 6 month aggregation
seq_df_media_type <- readRDS("4.data_analysis/sequence_analysis/data/seq_df_media_type_6mth.rds")
seq_object_media_type <- seqdef(seq_df_media_type, var = 3:ncol(seq_df_media_type))

# All media only with basic type labels, 6 month aggregation
seq_df_all_media <- readRDS("4.data_analysis/sequence_analysis/data/seq_df_all_media_6mth.rds")
seq_object_all_media <- seqdef(seq_df_all_media, var = 3:ncol(seq_df_all_media))

# Check missingness
paste(round((sum(is.na(seq_df_media_type_aggregated[2:ncol(seq_df_media_type_aggregated)]))/prod(dim(seq_df_media_type_aggregated[2:ncol(seq_df_media_type_aggregated)])))*100), "percent of the media type aggregated dataset is missing")
paste(round((sum(is.na(seq_df_media_type[3:ncol(seq_df_media_type)]))/prod(dim(seq_df_media_type[3:ncol(seq_df_media_type)])))*100), "percent of the media type dataset is missing")
paste(round((sum(is.na(seq_df_all_media[3:ncol(seq_df_all_media)]))/prod(dim(seq_df_all_media[3:ncol(seq_df_all_media)])))*100), "percent of the basic media type dataset is missing")

# Check if the possible states of the dataset are equal for all of the ones selected
seqstatl(seq_df_media_type_aggregated[,2:ncol(seq_df_media_type_aggregated)])
seqstatl(seq_df_media_type[,3:ncol(seq_df_media_type)])
seqstatl(seq_df_media_type[,3:ncol(seq_df_media_type)])

# Preview legend with the color palette
col_pal <- c("#db1d0b", "#2b9bf4") # Palette for states of the sequence analysis
seqlegend(seq_object_all_media, cex = 7, cpal = col_pal, position = "center")

# Create graph layout
layout(matrix(c(1, 2), ncol = 2, byrow = FALSE)) # create layout of 3x2 plots using matrix
layout.show(2) # Optional - preview how plots will be layed out

# All sequences for each of the objects: with and without NAs
# State distribution plot
seqdplot(seq_object_media_type_aggregated, border = TRUE, main = "Aggregated media types sequences w/o NAs", with.legend = FALSE, cpal = col_pal)

seqIplot(seq_object_media_type, main = "Media types sequences", with.legend = FALSE, cpal = col_pal)
seqdplot(seq_object_media_type, border = TRUE, main = "Media types sequences w/o NAs", with.legend = FALSE, cpal = col_pal)

seqIplot(seq_object_all_media, border = NA, main = "All media sequences", with.legend = FALSE, cpal = col_pal)
seqdplot(seq_object_all_media, border = TRUE, main = "All media sequences w/o NAs", with.legend = FALSE, cpal = col_pal)

# All sequences for each of the objects, grouped by media type: with and without NAs
seqiplot(seq_object_media_type_aggregated, border = NA, main = "Aggregated media types", group = seq_df_media_type_aggregated$media_type, cpal = col_pal)

seqiplot(seq_object_media_type, border = NA, main = "Media types", with.legend = FALSE,  group = seq_df_media_type$media_type, cpal = col_pal)
seqdplot(seq_object_media_type, border = NA, main = "State distribution w/o NAs", with.legend = FALSE, group = seq_df_media_type$media_type, cpal = col_pal)

seqiplot(seq_object_all_media, border = NA, main = "All media category", with.legend = FALSE, group = seq_df_all_media$media_type_basic, cpal = col_pal)
seqdplot(seq_object_all_media, border = NA, main = "State distribution w/o NAs",  with.legend = FALSE, group = seq_df_all_media$media_type_basic, cpal = col_pal)

# Most frequent sequences for some of the objects
seqfplot(seq_object_media_type, main = "TOP 5 most common sequences", with.legend = FALSE, cpal = col_pal, group = seq_df_media_type$media_type, idxs = 1:5)
seqfplot(seq_object_all_media, main = "TOP 5 most common sequences", with.legend = FALSE, cpal = col_pal, seq_df_all_media$media_type_basic, idxs = 1:5)

# b. Proportion of time in each of the sequence states
prop.table(seqmeant(seq_object_media_type_aggregated))*100
prop.table(seqmeant(seq_object_media_type))*100
prop.table(seqmeant(seq_object_all_media))*100

# Duration average visualization by group
seqmtplot(seq_object_media_type_aggregated, group = seq_df_media_type_aggregated$media_type, cpal = col_pal)
seqmtplot(seq_object_media_type, group = seq_df_media_type$media_type, cpal = col_pal, main = "Mean time plot: media type", with.legend = FALSE)
seqmtplot(seq_object_all_media, group = seq_df_all_media$media_type_basic, cpal = col_pal, main = "Mean time plot: basic media type", with.legend	= FALSE)

# c. Transitions
# Number of transitions - Family_Educ example, absolute nrs.
by(seq_object_media_type_aggregated, seq_df_media_type_aggregated$media_type, seqtransn)
# Separating transition probability based on media type
by(seq_object_media_type, seq_df_media_type$media_type, seqtrate)


# Creation of Distance Matrix ---------------------------------------------
distance_matrix_agg <- seqdist(seq_object_media_type_aggregated, method = "OM", indel = 1, sm = "CONSTANT", with.missing = TRUE)
dimnames(distance_matrix_agg) <- list(seq_df_media_type_aggregated$media_type, seq_df_media_type_aggregated$media_type)

distance_matrix_media_type <- seqdist(seq_object_media_type, method = "OM", indel = 1, sm = "CONSTANT", with.missing = TRUE)
dimnames(distance_matrix_media_type) <- list(seq_df_media_type$name, seq_df_media_type$name)

distance_matrix_all <- seqdist(seq_object_all_media, method = "OM", indel = 1, sm = "CONSTANT", with.missing = TRUE)
dimnames(distance_matrix_all) <- list(seq_df_all_media$name, seq_df_all_media$name)

# Create a simple heatmap image for aggregated data and media type data
dimension <- 7L
image(1:dimension, 1:dimension, distance_matrix_agg[1:dimension, 1:dimension], axes = FALSE, xlab = "", ylab = "")
axis(1, 1:dimension, colnames(distance_matrix_agg)[1:dimension], cex.axis = 0.5, las = 3)
axis(2, 1:dimension, colnames(distance_matrix_agg)[1:dimension], cex.axis = 0.5, las = 1)

dimension <- 3843L
image(1:dimension, 1:dimension, distance_matrix_media_type[1:dimension, 1:dimension], axes = FALSE, xlab = "", ylab = "")
axis(1, 1:dimension, colnames(distance_matrix_media_type)[1:dimension], cex.axis = 0.5, las = 3)
axis(2, 1:dimension, colnames(distance_matrix_media_type)[1:dimension], cex.axis = 0.5, las = 1)
title("Heatmap of Media Types Dataset (N=202)")

image(1:dimension, 1:dimension, distance_matrix_all[1:dimension, 1:dimension], axes = FALSE, xlab = "", ylab = "")
title("Heatmap of All Media Dataset (N=3843)")

# Determine optimal number of clusters with NbClust -----------------------

# Selected indexes
indexes <- c("frey", "mcclain", "cindex", "silhouette", "dunn")
# Prealocate list to which we append
nr_clust <- vector(mode = "list", length = length(indexes)) %>% setNames(indexes)

set.seed(2022)
# indices <- sample(1:dim(distance_matrix_all)[[1]], 500)
# distance_matrix_all_frac <- distance_matrix_all[indices, indices]

# Run for loop that appends the result of the selected index
for (i in indexes) {
  nr_clust[[i]] <- NbClust(data = distance_matrix_media_type, distance = "euclidean", min.nc = 2, max.nc = 7, method = "ward.D2", index = i)[["Best.nc"]][["Number_clusters"]]
  print(i)
}

# Set the most appropriate number of clusters based on the recommendation
nr_clust <- 2


# Clustering using Hiearchical method -------------------------------------

#Generate the clusters using the distance matrix we have created.
set.seed(2022)
hiearch_cluster <- agnes(distance_matrix_media_type, diss = TRUE, method = "ward")
hiearch_cluster_all <- agnes(distance_matrix_all, diss = TRUE, method = "ward")

# We can display the dendrogram by following this syntax:
plot(hiearch_cluster, ask = FALSE, which.plots = 2)

hiearch_cluster <- cutree(hiearch_cluster, k = nr_clust)
hiearch_cluster_all <- cutree(hiearch_cluster_all, k = nr_clust)

object_cluster <- factor(hiearch_cluster, levels = 1:nr_clust, labels = paste0("cluster_", 1:nr_clust))
object_cluster_all <- factor(hiearch_cluster_all, levels = 1:nr_clust, labels = paste0("cluster_", 1:nr_clust))

Heatmap(distance_matrix_media_type,  split =  hiearch_cluster,  show_row_names = FALSE, show_column_names = FALSE)

saveRDS(object_cluster, "4.data_analysis/sequence_analysis/data/clustering_media_type_groups.rds")
saveRDS(object_cluster_all, "4.data_analysis/sequence_analysis/data/clustering_all_groups.rds")

# Create graphics ---------------------------------------------------------

object_cluster <- readRDS("4.data_analysis/sequence_analysis/data/clustering_media_type_groups.rds")
object_cluster_all <- readRDS("4.data_analysis/sequence_analysis/data/clustering_all_groups.rds")

# Set margin 1 to get row proportion (per media type per cluster)
with(seq_df_media_type, prop.table(table(media_type, object_cluster), margin = 1)) %>%
  as_tibble() %>%
  pivot_wider(names_from = object_cluster, values_from = n) %>%
  gt() %>%
  tab_spanner(label = "CLUSTER", columns = c(2:3)) %>%
  cols_label(media_type = "Basic Media Type", cluster_1 = "Group 1", cluster_2 = "Group 2") %>%
  gt_theme_nytimes() %>%
  fmt_percent(c(2:3), decimals = 1) %>%
  tab_header(title = "Percent of Media in Each Cluster", subtitle = "Separated by media type") %>%
  gt_highlight_rows(rows = c(1,3), font_weight = "normal", alpha = 0.5) %>%
  tab_footnote("N = 202") %>%
  gtsave("clustering.png", expand = 10, vwidth = 1920, vheight = 1080)

with(seq_df_all_media, prop.table(table(media_type_basic, object_cluster_all), margin = 1)) %>%
  as_tibble() %>%
  pivot_wider(names_from = object_cluster_all, values_from = n) %>%
  gt() %>%
  tab_spanner(label = "CLUSTER", columns = c(2:3)) %>%
  cols_label(media_type_basic = "Media Type", cluster_1 = "Group 1", cluster_2 = "Group 2") %>%
  gt_theme_nytimes() %>%
  fmt_percent(c(2:3), decimals = 1) %>%
  tab_header(title = "Percent of Media in Each Cluster", subtitle = "Separated by basic media type") %>%
  gt_highlight_rows(rows = c(1,3), font_weight = "normal", alpha = 0.5) %>%
  tab_footnote("N = 3843") %>%
  gtsave("clustering_all.png", expand = 10, vwidth = 1920, vheight = 1080)

# Using UMAP for dimensionality reduction
set.seed(2022)
umap_results <- umap(distance_matrix_media_type)

umap_results$layout %>%
  as_tibble() %>%
ggplot(aes(x = V1, y = V2)) +
  geom_point(aes(color = object_cluster), alpha = 0.5, position = "jitter", size = 1.5) +
  scale_color_manual(values = c("cluster_1" = "#1B9E77", "cluster_2" = "#D95F02"), labels = c("cluster_1" = "Cluster 1", "cluster_2" = "Cluster 2")) +
  facet_wrap(vars(seq_df_media_type$media_type)) +
  ylab(element_blank()) +
  xlab(element_blank()) +
  labs(color = "Hierarchical clustering") +
  labs(title = "Visualization of Sequence Clusters across Czech Media Types",
       subtitle = "Using Uniform Manifold Approximation and Projection (UMAP) to reduce multidimensionality") +
  theme_bw() +
  theme(axis.text = element_text(size = 7),
        plot.background = element_rect(fill = "grey90"),
        plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(face = "italic", size = 7),
        legend.title = element_text(size = 8, face = "bold"),
        legend.text = element_text(size = 7),
        legend.key = element_rect(fill = NA, size = 8),
        legend.background = element_rect(fill = NA),
        legend.position = c(0.7, 0.12),
        plot.margin = margin(7,30,3,5, "pt"))

ggsave("cluster_visualization_media_types.png", device = "png",
         width = 1920, height = 1080, units = "px")
