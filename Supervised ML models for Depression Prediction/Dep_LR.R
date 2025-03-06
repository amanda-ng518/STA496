library(dplyr)
library(RSQLite)
library(stringr)
library(nlpembeds)
library(readr)
library(pROC)

sqlite <- dbDriver("SQLite")
conn <- dbConnect(RSQLite::SQLite(), dbname = "mimic.db", synchronous = NULL)

#------------------------------CUI------------------------------------#
# Read data
entity <- dbReadTable(conn, "entities")
note <- dbReadTable(conn, "notes")
entity_merged <- merge(entity, note, by = "row_id")
CUI_demographics <- read_csv("EHR_demographic.csv")

# Add demographic variables
entity_merged <- merge(entity_merged, CUI_demographics, by.x = "hadm_id", by.y = "HADM_ID", all.y = FALSE)

# Prepare data by demographic groups
# Overall
entity_merged_overall = entity_merged%>%select(subject_id, entity_label)
# white
white_entity = entity_merged%>%filter(ETHNICITY == "WHITE")%>%select(subject_id, entity_label)
# non-white
nwhite_entity = entity_merged%>%filter(ETHNICITY != "WHITE")%>%select(subject_id, entity_label)
# private insurance
private_entity = entity_merged%>%filter(INSURANCE == "Private")%>%select(subject_id, entity_label)
# non-private insurance
nprivate_entity = entity_merged%>%filter(INSURANCE != "Private")%>%select(subject_id, entity_label)


# Train & Test
train_indices1 <- sample(seq_len(nrow(entity_merged_overall)), size = 0.7 * nrow(entity_merged_overall))
train_data1 <- entity_merged_overall[train_indices1, ]
test_data1 <- entity_merged_overall[-train_indices1, ]

train_indices_white1 <- sample(seq_len(nrow(white_entity)), size = 0.7 * nrow(white_entity))
train_data_white1 <- white_entity[train_indices_white1, ]
test_data_white1 <- white_entity[-train_indices_white1, ]

train_indices_nwhite1 <- sample(seq_len(nrow(nwhite_entity)), size = 0.7 * nrow(nwhite_entity))
train_data_nwhite1 <- nwhite_entity[train_indices_nwhite1, ]
test_data_nwhite1 <- nwhite_entity[-train_indices_nwhite1, ]

train_indices_private1 <- sample(seq_len(nrow(private_entity)), size = 0.7 * nrow(private_entity))
train_data_private1 <- private_entity[train_indices_private1, ]
test_data_private1 <- private_entity[-train_indices_private1, ]

train_indices_nprivate1 <- sample(seq_len(nrow(nprivate_entity)), size = 0.7 * nrow(nprivate_entity))
train_data_nprivate1 <- nprivate_entity[train_indices_nprivate1, ]
test_data_nprivate1 <- nprivate_entity[-train_indices_nprivate1, ]

#-----------------------Phecode-----------------------------#
# Read data
load("Phecode_Data_for_generating_embedding.Rdata") # I named the object as cleaned_data in the Phecode_transformation R script
data_merged = cleaned_data
phecode_demographics = read_csv("admissions.csv")%>%select(subject_id, insurance, race)%>%unique()

# Add demographic variables
data_merged <- merge(data_merged, phecode_demographics, by = "subject_id", all.x = TRUE, all.y = FALSE)

# Prepare data by demographic groups
# Overall
data_merged_overall = data_merged%>%select(subject_id, phecode)
# white
white_data = data_merged%>%filter(race == "WHITE")%>%select(subject_id, phecode)
# nwhite
nwhite_data = data_merged%>%filter(race != "WHITE")%>%select(subject_id, phecode)
# private 
private_data = data_merged%>%filter(insurance == "Private")%>%select(subject_id, phecode)
# nprivate 
nprivate_data = data_merged%>%filter(insurance != "Private")%>%select(subject_id, phecode)

# Train & Test
train_indices2 <- sample(seq_len(nrow(data_merged_overall)), size = 0.7 * nrow(data_merged_overall))
train_data2 <- data_merged_overall[train_indices2, ]
test_data2 <- data_merged_overall[-train_indices2, ]

train_indices_white2 <- sample(seq_len(nrow(white_data)), size = 0.7 * nrow(white_data))
train_data_white2 <- white_data[train_indices_white2, ]
test_data_white2 <- white_data[-train_indices_white2, ]

train_indices_nwhite2 <- sample(seq_len(nrow(nwhite_data)), size = 0.7 * nrow(nwhite_data))
train_data_nwhite2 <- nwhite_data[train_indices_nwhite2, ]
test_data_nwhite2 <- nwhite_data[-train_indices_nwhite2, ]

train_indices_private2 <- sample(seq_len(nrow(private_data)), size = 0.7 * nrow(private_data))
train_data_private2 <- private_data[train_indices_private2, ]
test_data_private2 <- private_data[-train_indices_private2, ]

train_indices_nprivate2 <- sample(seq_len(nrow(nprivate_data)), size = 0.7 * nrow(nprivate_data))
train_data_nprivate2 <- nprivate_data[train_indices_nprivate2, ]
test_data_nprivate2 <- nprivate_data[-train_indices_nprivate2, ]

#-----------------Combine datasets---------------#
# Rename columns so that both datasets have the same structure
train_data1 <- train_data1 %>% rename(code = entity_label)
train_data2 <- train_data2 %>% rename(code = phecode)
test_data1 <- test_data1 %>% rename(code = entity_label)
test_data2 <- test_data2 %>% rename(code = phecode)

train_data_white1 <- train_data_white1 %>% rename(code = entity_label)
train_data_white2 <- train_data_white2 %>% rename(code = phecode)
test_data_white1 <- test_data_white1 %>% rename(code = entity_label)
test_data_white2 <- test_data_white2 %>% rename(code = phecode)

train_data_nwhite1 <- train_data_nwhite1 %>% rename(code = entity_label)
train_data_nwhite2 <- train_data_nwhite2 %>% rename(code = phecode)
test_data_nwhite1 <- test_data_nwhite1 %>% rename(code = entity_label)
test_data_nwhite2 <- test_data_nwhite2 %>% rename(code = phecode)

train_data_private1 <- train_data_private1 %>% rename(code = entity_label)
train_data_private2 <- train_data_private2 %>% rename(code = phecode)
test_data_private1 <- test_data_private1 %>% rename(code = entity_label)
test_data_private2 <- test_data_private2 %>% rename(code = phecode)

train_data_nprivate1 <- train_data_nprivate1 %>% rename(code = entity_label)
train_data_nprivate2 <- train_data_nprivate2 %>% rename(code = phecode)
test_data_nprivate1 <- test_data_nprivate1 %>% rename(code = entity_label)
test_data_nprivate2 <- test_data_nprivate2 %>% rename(code = phecode)

# Combine the datasets
train_data <- bind_rows(train_data1, train_data2)
test_data <- bind_rows(test_data1, test_data2)

train_data_white <- bind_rows(train_data_white1, train_data_white2)
test_data_white <- bind_rows(test_data_white1, test_data_white2)

train_data_nwhite <- bind_rows(train_data_nwhite1, train_data_nwhite2)
test_data_nwhite <- bind_rows(test_data_nwhite1, test_data_nwhite2)

train_data_private <- bind_rows(train_data_private1, train_data_private2)
test_data_private <- bind_rows(test_data_private1, test_data_private2)

train_data_nprivate <- bind_rows(train_data_nprivate1, train_data_nprivate2)
test_data_nprivate <- bind_rows(test_data_nprivate1, test_data_nprivate2)

#---------------------Define new var for LR-----------------#
# Depression codes
depression_codes <- c("C4049644", "C0011581","296.2","296.22")

# Feature codes
feature_codes <- c("C0867389", "C1512523", "C0003469", "C4726934", "C0060926", 
           "C0008845", "C0017168", "C0152020", "C1306597", "C0812393", 
           "C0078569", "C0552595", "C1564453", "C0748061", "C1547426", 
           "C0237284", "C2987514", "C0009011", "C0079304", "C0745031")

# Train
# change train_data to train_data_white/train_data_nwhite/train_data_private/train_data_nprivate
LR_train <- train_data %>% 
  group_by(subject_id) %>%
  summarise(code = list(code)) %>%  # Keep all entity labels per subject as a list
  ungroup()
# Create an indicator for each feature code
for (feature in feature_codes) {
  LR_train[[feature]] <- sapply(LR_train$code, function(labels) as.integer(feature %in% labels))
}
# Create an indicator for depression codes
LR_train$dep <- sapply(LR_train$code, function(labels) as.integer(any(labels %in% depression_codes)))
# Drop the original code column
LR_train <- LR_train %>% select(-code)

# Test
# change test_data to test_data_white/test_data_nwhite/test_data_private/test_data_nprivate
LR_test <- test_data %>%
  group_by(subject_id) %>%
  summarise(code = list(code)) %>%  # Keep all entity labels per subject as a list
  ungroup()
# Create an indicator for each feature code
for (feature in feature_codes) {
  LR_test[[feature]] <- sapply(LR_test$code, function(labels) as.integer(feature %in% labels))
}
# Create an indicator for depression codes
LR_test$dep <- sapply(LR_test$code, function(labels) as.integer(any(labels %in% depression_codes)))
# Drop the original code column
LR_test <- LR_test %>% select(-code)

#-------------------LR model-------------------------#
# Fit the model
model <- glm(dep ~ . - subject_id, data = LR_train, family = binomial)
summary(model)

#------------------LR model validation-------------------------# 
# Validate with original test data
model_test_data = LR_test

pred_probs <- predict(model, newdata = LR_test, type = "response")
predictions <- ifelse(pred_probs > 0.5, 1, 0) # using 0.5 as threshold

# Confusion matrix
conf_matrix = table(Predicted = predictions, Actual = LR_test$dep)
# Extract TP, TN, FP, FN
TP <- conf_matrix[2, 2]
TN <- conf_matrix[1, 1]
FP <- conf_matrix[1, 2]
FN <- conf_matrix[2, 1]
# Accuracy
mean(predictions == LR_test$dep) 
# Sensitivity (True Positive Rate)
TP / (TP + FN) 
# Specificity (True Negative Rate)
TN / (TN + FP) 
# Compute ROC curve
roc_curve <- roc(LR_test$dep, pred_probs)
# Calculate AUC
auc(roc_curve) 

#--------------------Bootstrap test data-----------------------#

# Set seed for reproducibility
set.seed(123)

# Number of bootstrap samples
num_bootstrap <- 9

# Perform bootstrapping and store as separate data frames
for (i in 1:num_bootstrap) {
  assign(paste0("bootstrap_test_", i), 
         LR_test[sample(nrow(LR_test), replace = TRUE), ])
}

# Initialize vectors to store metric values
accuracy_values <- numeric(num_bootstrap)
sensitivity_values <- numeric(num_bootstrap)
specificity_values <- numeric(num_bootstrap)
auc_values <- numeric(num_bootstrap)

# Compute metrics for each bootstrap sample
for (i in 1:num_bootstrap) {
  test_data <- get(paste0("bootstrap_test_", i))
  pred_probs <- predict(model, newdata = test_data, type = "response")
  predictions <- ifelse(pred_probs > 0.5, 1, 0) # using 0.5 as threshold
  
  # Confusion matrix
  conf_matrix <- table(Predicted = predictions, Actual = test_data$dep)
  
  # Extract TP, TN, FP, FN
  TP <- conf_matrix[2, 2]
  TN <- conf_matrix[1, 1]
  FP <- conf_matrix[1, 2]
  FN <- conf_matrix[2, 1]
  
  # Accuracy
  accuracy_values[i] <- mean(predictions == test_data$dep)
  
  # Sensitivity (True Positive Rate)
  sensitivity_values[i] <- TP / (TP + FN)
  
  # Specificity (True Negative Rate)
  specificity_values[i] <- TN / (TN + FP)
  
  # Compute ROC curve
  roc_curve <- roc(test_data$dep, pred_probs)
  
  # Calculate AUC
  auc_values[i] <- auc(roc_curve)
}

# Compute bootstrapped mean for all metrics
mean_accuracy <-mean(accuracy_values)
mean_sensitivity <- mean(sensitivity_values) 
mean_specificity <- mean(specificity_values) 
mean_auc <- mean(auc_values) 

# Compute standard errors for all metrics
se_accuracy <- sd(accuracy_values) / sqrt(num_bootstrap)
se_sensitivity <- sd(sensitivity_values) / sqrt(num_bootstrap)
se_specificity <- sd(specificity_values) / sqrt(num_bootstrap)
se_auc <- sd(auc_values) / sqrt(num_bootstrap)

# Print standard errors
print(list(SE_Accuracy = se_accuracy, SE_Sensitivity = se_sensitivity, SE_Specificity = se_specificity, SE_AUC = se_auc))
# Print bootstrap mean
print(list(Accuracy = mean_accuracy, Sensitivity = mean_sensitivity, mean_Specificity = mean_specificity, mean_AUC = mean_auc))
