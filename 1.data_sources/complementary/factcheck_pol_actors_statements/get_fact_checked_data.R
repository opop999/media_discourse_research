# This script gets data from the Demagog.cz database using GraphQL query
library(httr)
library(dplyr)
library(jsonlite)
library(tidyr)
library(ggplot2)
library(forcats)


# Specify variables of interest with GraphQL query. Documentation and schema at: https://demagog.cz/graphiql
# Useful resource for more manageable query body: https://codepen.io/dangodev/pen/Baoqmoy
speakers_graphql_query <- '{"query":"{speakers(limit:100000,offset:0){wikidataId osobaId firstName lastName body{shortName name}stats{true untrue misleading unverifiable}}}"}'
statements_graphql_query <- '{"query":"{statements(limit:100000,offset:0){id excerptedAt content sourceSpeaker{firstName lastName body{shortName name}}assessment{veracity{key}}}}"}'

# Get all speakers
speakers <- httr::RETRY(
  verb = "POST",
  url = "https://demagog.cz/graphql",
  config = httr::add_headers(`Content-Type` = "application/json"),
  body = speakers_graphql_query
) %>%
  content(as = "text") %>%
  fromJSON() %>%
  {
    .[["data"]][["speakers"]]
  } %>%
  unnest_wider(all_of(c("stats", "body")), strict = TRUE) %>%
  transmute(
    wiki_id = wikidataId,
    hlidac_id = osobaId,
    speaker_full_name = paste(firstName, lastName),
    org_name_short = shortName,
    org_name_full = name,
    n_true = true,
    n_untrue = untrue,
    n_misleading = misleading,
    n_unverifiable = unverifiable
  )

# Get all statements with their assessments of truthfulness
statements <- httr::RETRY(
  verb = "POST",
  url = "https://demagog.cz/graphql",
  config = httr::add_headers(`Content-Type` = "application/json"),
  body = statements_graphql_query
) %>%
  content(as = "text") %>%
  fromJSON() %>%
  {
    .[["data"]][["statements"]]
  } %>%
  transmute(
    statement_id = id,
    date = as.Date(excerptedAt),
    statement_txt = content,
    speaker_full_name = paste(sourceSpeaker$firstName, sourceSpeaker$lastName),
    org_name_short = sourceSpeaker$body$shortName,
    org_name_full = sourceSpeaker$body$name,
    assessment = assessment$veracity$key
  ) %>%
  distinct()


# Join both datasets to get information about a speaker for every investigated claim
statements_with_speakers <- statements %>%
  left_join(speakers, by = c("speaker_full_name", "org_name_short", "org_name_full")) %>%
  distinct()

# Save combined dataset
saveRDS(
  statements_with_speakers,
  "1.data_sources/complementary/contextual_datasets/factcheck_pol_actors_statements/data/statements_with_speakers.rds"
)

# Quick vizualization

# Which actor has the highest proportion of problematic (misleading + lies) statements?
statements_with_speakers %>%
  group_by(speaker_full_name) %>%
  summarise(
    n_problematic = first(n_untrue) + first(n_misleading),
    n = n(),
    prop_problematic = n_problematic / n
  ) %>%
  filter(n >= 100) %>%
  na.omit() %>%
  ggplot(aes(y = fct_reorder(speaker_full_name, prop_problematic), x = prop_problematic)) +
  geom_col() +
  theme_minimal() +
  ylab(element_blank()) +
  xlab("Proportion of Problematic Statements in %")

# Statements regarding migration

regex_pattern <- "(běženec\\S*)|(běženk\\S*)|(imigrant\\S*)|(migra\\S*)|(imigra\\S*)|(přistěhoval\\S*)|(uprchl\\S*)|(utečen\\S*)|(azylant\\S*)"

statements_with_speakers %>%
  filter(grepl(regex_pattern, statement_txt, ignore.case = TRUE)) %>%
  mutate(problematic_statement = ifelse(assessment %in% c("misleading", "untrue"), 1, 0)) %>%
  group_by(speaker_full_name) %>%
  summarise(
    n_problematic = sum(problematic_statement),
    n = n(),
    prop_problematic = n_problematic / n
  ) %>%
  na.omit() %>%
  filter(n >= 5) %>%
  ggplot(aes(y = fct_reorder(speaker_full_name, prop_problematic), x = prop_problematic)) +
  geom_col() +
  theme_minimal() +
  ylab(element_blank()) +
  xlab("Proportion of Migration-relevant Problematic Statements in %")
