library(dplyr)
library(RSQLite)
library(stringr)
library(nlpembeds)
library(readr)
library(randomForest)
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

# Create demographic groups indicators
entity_merged_demo = entity_merged%>%mutate(Ethnicity = case_when((ETHNICITY == "WHITE")~1,
                                                                  (ETHNICITY != "WHITE")~0),
                                            Insurance = case_when((INSURANCE == "Private")~1,
                                                                  (INSURANCE != "Private")~0))

# Overall
entity_merged_overall = entity_merged_demo%>%select(subject_id, entity_label,Ethnicity,Insurance)

# Train & Test
train_indices1 <- sample(seq_len(nrow(entity_merged_overall)), size = 0.7 * nrow(entity_merged_overall))
train_data1 <- entity_merged_overall[train_indices1, ]
test_data1 <- entity_merged_overall[-train_indices1, ]

#-----------------------Phecode-----------------------------#
# Read data
load("Phecode_Data_for_generating_embedding.Rdata") # I named the object as cleaned_data in the Phecode_transformation R script
data_merged = cleaned_data
phecode_demographics = read_csv("admissions.csv")%>%select(subject_id, insurance, race)%>%unique()

# Add demographic variables
data_merged <- merge(data_merged, phecode_demographics, by = "subject_id", all.x = TRUE, all.y = FALSE)

# Prepare data with demographic groups indicators
data_merged_demo = data_merged%>%mutate(Ethnicity = case_when((race == "WHITE")~1,
                                                              (race != "WHITE")~0),
                                        Insurance = case_when((insurance == "Private")~1,
                                                              (insurance != "Private")~0))

data_merged_overall = data_merged_demo%>%select(subject_id, phecode,Ethnicity,Insurance)

# Train & Test
train_indices2 <- sample(seq_len(nrow(data_merged_overall)), size = 0.7 * nrow(data_merged_overall))
train_data2 <- data_merged_overall[train_indices2, ]
test_data2 <- data_merged_overall[-train_indices2, ]

#-----------------Combine datasets---------------#
# Rename columns so that both datasets have the same structure
train_data1 <- train_data1 %>% rename(code = entity_label)
train_data2 <- train_data2 %>% rename(code = phecode)
test_data1 <- test_data1 %>% rename(code = entity_label)
test_data2 <- test_data2 %>% rename(code = phecode)

# Combine the datasets
train_data <- bind_rows(train_data1, train_data2)
test_data <- bind_rows(test_data1, test_data2)

#---------------------Define new var for LR-----------------#
# Depression codes
depression_codes <- c("C4049644", "C0011581","296.2","296.22")

# Feature codes
feature_codes <- c("C0867389", "C1512523", "C0003469", "C4726934", "C0060926", 
                   "C0008845", "C0017168", "C0152020", "C1306597", "C0812393", 
                   "C0078569", "C0552595", "C1564453", "C0748061", "C1547426", 
                   "C0237284", "C2987514", "C0009011", "C0079304", "C0745031")

# Train
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
# Set factor
LR_train$dep <- as.factor(LR_train$dep)

# Test
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
# Set factor
LR_test$dep <- as.factor(LR_test$dep)

#---------------Random forest model---------------------#

# Build the random forest model
rf_model <- randomForest(dep ~ . -subject_id,ntree = 100, data = LR_train, importance = TRUE)

# Print the model summary
print(rf_model)

#------------------RF model validation-------------------------# 
# Predict on test data
predictions <- predict(rf_model, newdata = LR_test)
prob <- as.numeric(predict(rf_model, LR_test, type = "prob")[,2])

# Confusion matrix
conf_matrix = table(Predicted = predictions, Actual = LR_test$dep)
# Extract TP, TN, FP, FN
TP <- conf_matrix[2, 2]
TN <- conf_matrix[1, 1]
FP <- conf_matrix[1, 2]
FN <- conf_matrix[2, 1]
# Accuracy
sum(diag(conf_matrix)) / sum(conf_matrix)
# Sensitivity (True Positive Rate)
TP / (TP + FN) 
# Specificity (True Negative Rate)
TN / (TN + FP) 
# Compute ROC curve
roc_curve <- roc(LR_test$dep, prob)
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
  predictions <- predict(rf_model, newdata = test_data)
  prob <- as.numeric(predict(rf_model, test_data, type = "prob")[,2])
  
  # Confusion matrix
  conf_matrix <- table(Predicted = predictions, Actual = test_data$dep)
  
  # Extract TP, TN, FP, FN
  TP <- conf_matrix[2, 2]
  TN <- conf_matrix[1, 1]
  FP <- conf_matrix[1, 2]
  FN <- conf_matrix[2, 1]
  
  # Accuracy
  accuracy_values[i] <-sum(diag(conf_matrix)) / sum(conf_matrix)
  
  # Sensitivity (True Positive Rate)
  sensitivity_values[i] <- TP / (TP + FN)
  
  # Specificity (True Negative Rate)
  specificity_values[i] <- TN / (TN + FP)
  
  # Compute ROC curve
  roc_curve <- roc(test_data$dep, prob)
  
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

