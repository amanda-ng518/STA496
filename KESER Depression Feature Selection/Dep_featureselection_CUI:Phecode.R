library(KESER)
library(tidyverse)
library(wordcloud)
library(igraph)
library(ggraph)
library(ggplot2)
library(PheWAS)

#---------------CUI----------------------#
# embedding dimension
dim = 1500

# Load CUI embedding
load("test_CUI_1500dim.Rdata") #test_m_embeds_1500_1
load("train_CUI_1500dim.Rdata") #train_m_embeds_1500_1
load("CUI_1500dim.Rdata") #m_embeds_1500

# Depression CUI = C4049644,C0011581

Xembeddings_train = train_m_embeds_1500_1[!rownames(train_m_embeds_1500_1) %in% c("C4049644","C0011581"), ]
Xembeddings_validate = test_m_embeds_1500_1[!rownames(test_m_embeds_1500_1) %in% c("C4049644","C0011581"), ]
Xembeddings_full = m_embeds_1500[!rownames(m_embeds_1500) %in% c("C4049644","C0011581"), ]

Yembeddings_train = train_m_embeds_1500_1["C4049644", ]
Yembeddings_validate = test_m_embeds_1500_1["C4049644", ]
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

dict = CUI_description%>%
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

#---------------Phecode----------------------#
# embedding dimension
dim = 100

# Load Phecode embedding
load("test_Phecode_100dim.Rdata") #test_m_embeds_100_2
load("train_Phecode_100dim.Rdata") #train_m_embeds_100_2
load("Phecode_100dim.Rdata") #m_phecode_embeds_100

# Depression Phecode = 296.2, 296.22

Xembeddings_train = train_m_embeds_100_2[!rownames(train_m_embeds_100_2) %in% c("296.2","296.22"), ]
Xembeddings_validate = test_m_embeds_100_2[!rownames(test_m_embeds_100_2) %in% c("296.2","296.22"), ]
Xembeddings_full = m_phecode_embeds_100[!rownames(m_phecode_embeds_100) %in% c("296.2","296.22"), ]

Yembeddings_train = train_m_embeds_100_2["296.2", ]
Yembeddings_validate = test_m_embeds_100_2["296.2", ]
Yembeddings_full = m_phecode_embeds_100["296.2", ]

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

dict = phecode_description%>%
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
          freq = as.numeric(results.RPDR$coef),
          random.order = FALSE,
          colors = brewer.pal(8, "Dark2"),
          rot.per = 0)
