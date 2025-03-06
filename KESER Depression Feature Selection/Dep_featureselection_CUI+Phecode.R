library(KESER)
library(tidyverse)
library(wordcloud)
library(igraph)
library(ggraph)
library(ggplot2)
library(PheWAS)

# embedding dimension
dim = 1500

# Load embedding
load("white_CUI+Phecode_1500dim.Rdata") #white_m_embeds_1500
load("nwhite_CUI+Phecode_1500dim.Rdata") #nwhite_m_embeds_1500
load("CUI+Phecode_1500dim.Rdata") #m_embeds_1500

# Depression CUI = C4049644, C0011581
# Depression Phecode = 296.2, 296.22 (remove this embedding to avoid confusion)

Xembeddings_train = white_m_embeds_1500[!rownames(white_m_embeds_1500) %in% c("C4049644", "C0011581","296.2","296.22"), ]
Xembeddings_validate = nwhite_m_embeds_1500[!rownames(nwhite_m_embeds_1500) %in% c("C4049644", "C0011581","296.2","296.22"), ]
Xembeddings_full = m_embeds_1500[!rownames(m_embeds_1500) %in% c("C4049644", "C0011581","296.2","296.22"), ]

Yembeddings_train = white_m_embeds_1500["C4049644", ]
Yembeddings_validate = nwhite_m_embeds_1500["C4049644", ]
Yembeddings_full = m_embeds_1500["C4049644", ]

# Extract texts that appear in both train and validate sets
# number of common entities = 

common_entity <- intersect(rownames(Xembeddings_train), rownames(Xembeddings_validate))
Xembed_train <- Xembeddings_train[common_entity, ]
Xembed_validate <- Xembeddings_validate[common_entity, ]
Xembed_full <-Xembeddings_full[common_entity, ]
names = as.data.frame(common_entity)

Xembed_train_l_matrix = t(Xembed_train)
Xembed_validate_l_matrix = t(Xembed_validate)
Xembed_full_l_matrix = t(Xembed_full)

# ---------------------------Code description----------------------#
phecode_names = subset(names, !grepl("C", common_entity))
phecode_description = addPhecodeInfo(phecode_names)%>%select(common_entity, description)

library(dplyr)
library(RSQLite)
CUI_names = subset(names, grepl("C", common_entity))
sqlite <- dbDriver("SQLite")
conn <- dbConnect(RSQLite::SQLite(), dbname = "mimic.db", synchronous = NULL)
entity <- dbReadTable(conn, "entities")

CUI_description <- entity %>%
  select(entity_text, entity_label)%>%
  distinct()%>%
  rename(common_entity = entity_label, description= entity_text)%>%
  group_by(common_entity) %>%
  slice(1)

dict = rbind(phecode_description, CUI_description)%>%
  rename(name = common_entity)
#-----------------------------------Feature selection ------------------------------------------------#
set.seed(123)

loc.fit.RPDR <- loc.feature.selection(
  Xembed_full_l_matrix, Yembeddings_full,
  Xembed_train_l_matrix, Yembeddings_train, 
  Xembed_validate_l_matrix, Yembeddings_validate,
  alpha = 1, lambda_lst = NULL, up_rate = 10, 
  drop_rate = 0.5, cos_cut = 0.1, add.ridge = TRUE)

results.RPDR <- merge(loc.fit.RPDR$results, dict ,all.x = TRUE)

results.RPDR %>%
  arrange(desc(coef)) %>%   # Arrange rows in descending order of 'coef'
  slice_head(n = 20) 

# Visualization
wordcloud(words = results.RPDR$description,
          freq = round(as.numeric(results.RPDR$coef) * 100),
          random.order = FALSE,
          colors = brewer.pal(8, "Dark2"),
          rot.per = 0)

