library(tidygraph)
library(plyr)
library(ggraph)
library(dplyr)

followers <- readRDS("1.data_sources/twitter/data/user_followers_data.rds")

followers_df <- plyr::ldply(followers, cbind)

followers_df_small <- slice_sample(followers_df, n = nrow(followers_df)/100)

colnames(followers_df_small) <- c("media_acc", "follower")

# Filter followers that follow more than one media outlet
net <- followers_df_small %>%
  group_by(follower) %>%
  mutate(count = n()) %>%
  ungroup() %>%
  filter(count > 1)

graph <- net %>%
  select(follower, media_acc) %>%
  as_tbl_graph(directed = F) %>%
  activate(nodes) %>%
  mutate(centrality = centrality_betweenness())

ggraph(graph, layout = "nicely") +
  geom_edge_link() +
  geom_node_point(size = 3, colour = 'steelblue') +
  theme_graph()

ggraph(graph) +
  geom_edge_link(edge_width = 0.25, arrow = arrow(30, unit(.15, "cm"))) +
  theme_graph()

ggraph(graph) +
  geom_edge_link() +
  geom_node_point(aes(size = centrality, colour = centrality)) +
  theme_graph()
