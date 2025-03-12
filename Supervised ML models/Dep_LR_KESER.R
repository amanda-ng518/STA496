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

#-----------------Testing demographic subsets----------------#
test_data_white = test_data%>%filter(Ethnicity == 1)
test_data_nwhite = test_data%>%filter(Ethnicity == 0)
test_data_private = test_data%>%filter(Insurance == 1)
test_data_nprivate = test_data%>%filter(Insurance == 0)

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

# Test
# Function to preprocess test datasets
process_test_data <- function(data) {
  data <- data %>%
    group_by(subject_id) %>%
    summarise(code = list(code)) %>%
    ungroup()
  # Create indicator variables for each feature code
  for (feature in feature_codes) {
    data[[feature]] <- sapply(data$code, function(labels) as.integer(feature %in% labels))
  }
  # Create indicator for depression codes
  data$dep <- sapply(data$code, function(labels) as.integer(any(labels %in% depression_codes)))
  # Drop original code column
  data <- select(data, -code)
  
  return(data)
}

# Apply function to each dataset
LR_test_white <- process_test_data(test_data_white)
LR_test_nwhite <- process_test_data(test_data_nwhite)
LR_test_private <- process_test_data(test_data_private)
LR_test_nprivate <- process_test_data(test_data_nprivate)


#-------------------LR model-------------------------#
# Fit the model
model <- glm(dep ~ . - subject_id, data = LR_train, family = binomial)
summary(model)

#------------------LR model validation-------------------------# 

# Set threshold
threshold = 0.7

# List of LR datasets
test_datasets <- list(
  "LR_test_white" = LR_test_white,
  "LR_test_nwhite" = LR_test_nwhite,
  "LR_test_private" = LR_test_private,
  "LR_test_nprivate" = LR_test_nprivate
)

# Initialize an empty dataframe to store results
LR_demo_results_df <- data.frame(
  Dataset = character(),
  Accuracy = numeric(),
  Sensitivity = numeric(),
  Specificity = numeric(),
  AUC = numeric(),
  stringsAsFactors = FALSE
)

# Loop through each dataset
for (name in names(test_datasets)) {
  LR_test <- test_datasets[[name]]
  
  # Make predictions
  pred_probs <- predict(model, newdata = LR_test, type = "response")
  predictions <- ifelse(pred_probs > threshold, 1, 0)  
  
  # Confusion matrix
  conf_matrix <- table(Predicted = predictions, Actual = LR_test$dep)
  
  # Extract TP, TN, FP, FN
  TP <- conf_matrix[2, 2]
  TN <- conf_matrix[1, 1]
  FP <- conf_matrix[1, 2]
  FN <- conf_matrix[2, 1]
  
  # Compute metrics
  accuracy <- mean(predictions == LR_test$dep)
  sensitivity <- TP / (TP + FN)
  specificity <- TN / (TN + FP)
  
  # Compute ROC and AUC
  roc_curve <- roc(LR_test$dep, pred_probs)
  auc_value <- auc(roc_curve)
  
  # Store results
  LR_demo_results_df <- rbind(LR_demo_results_df, data.frame(
    Dataset = name,
    Accuracy = accuracy,
    Sensitivity = sensitivity,
    Specificity = specificity,
    AUC = auc_value
  ))
}

# Print results
print(LR_demo_results_df)

#--------------------Bootstrap test data for within group metrics-----------------------#
# Test
LR_test <- test_data %>%
  group_by(subject_id) %>%
  summarise(
    code = list(code),  # Keep all entity labels per subject as a list
    Ethnicity = first(Ethnicity),  # Retain Ethnicity per subject
    Insurance = first(Insurance)   # Retain Insurance per subject
  ) %>%
  ungroup()
# Create an indicator for each feature code
for (feature in feature_codes) {
  LR_test[[feature]] <- sapply(LR_test$code, function(labels) as.integer(feature %in% labels))
}
# Create an indicator for depression codes
LR_test$dep <- sapply(LR_test$code, function(labels) as.integer(any(labels %in% depression_codes)))
# Drop the original code column
LR_test <- LR_test %>% select(-code)

# Set seed for reproducibility
set.seed(123)

# Number of bootstrap samples
num_bootstrap <- 200

# Function to perform bootstrapping and compute metrics within demographic subgroups
bootstrap_metrics_by_single_group <- function(test_data, num_bootstrap, demographic_col) {
  # Initialize list to store results
  results_list <- list()
  
  for (i in 1:num_bootstrap) {
    # Generate bootstrap sample
    boot_sample <- test_data[sample(nrow(test_data), replace = TRUE), ]
    
    # Split by demographic subgroup
    demographic_groups <- split(boot_sample, boot_sample[[demographic_col]])
    
    # Compute metrics for each subgroup
    subgroup_results <- lapply(demographic_groups, function(group_data) {
      if (nrow(group_data) == 0) return(NULL)
      
      # Make predictions
      pred_probs <- predict(model, newdata = group_data, type = "response")
      predictions <- ifelse(pred_probs > threshold, 1, 0)  
      
      # Confusion matrix
      conf_matrix <- table(Predicted = predictions, Actual = group_data$dep)
      
      # Extract TP, TN, FP, FN (handle cases where table might be incomplete)
      TP <- ifelse("1" %in% rownames(conf_matrix) & "1" %in% colnames(conf_matrix), conf_matrix["1", "1"], 0)
      TN <- ifelse("0" %in% rownames(conf_matrix) & "0" %in% colnames(conf_matrix), conf_matrix["0", "0"], 0)
      FP <- ifelse("0" %in% rownames(conf_matrix) & "1" %in% colnames(conf_matrix), conf_matrix["0", "1"], 0)
      FN <- ifelse("1" %in% rownames(conf_matrix) & "0" %in% colnames(conf_matrix), conf_matrix["1", "0"], 0)
      
      # Compute metrics (handle division by zero)
      accuracy <- mean(predictions == group_data$dep)
      sensitivity <- ifelse((TP + FN) > 0, TP / (TP + FN), NA)
      specificity <- ifelse((TN + FP) > 0, TN / (TN + FP), NA)
      
      # Compute AUC
      roc_curve <- roc(group_data$dep, pred_probs, quiet = TRUE)
      auc_value <- auc(roc_curve)
      
      # Rename group values
      group_name <- ifelse(demographic_col == "Ethnicity", 
                           ifelse(unique(group_data[[demographic_col]]) == 1, "White", "Non-White"), 
                           ifelse(unique(group_data[[demographic_col]]) == 1, "Private Insurance", "Non-Private Insurance"))
      
      return(data.frame(
        Group = group_name,
        Accuracy = accuracy,
        Sensitivity = sensitivity,
        Specificity = specificity,
        AUC = auc_value
      ))
    })
    
    # Combine subgroup results
    results_list[[i]] <- do.call(rbind, subgroup_results)
  }
  
  # Aggregate results across bootstrap samples (only computing standard errors)
  results_df <- do.call(rbind, results_list) %>%
    group_by(Group) %>%
    summarise(
      SE_Accuracy = sd(Accuracy, na.rm = TRUE) / sqrt(num_bootstrap),
      SE_Sensitivity = sd(Sensitivity, na.rm = TRUE) / sqrt(num_bootstrap),
      SE_Specificity = sd(Specificity, na.rm = TRUE) / sqrt(num_bootstrap),
      SE_AUC = sd(AUC, na.rm = TRUE) / sqrt(num_bootstrap)
    )
  
  return(results_df)
}

# Apply bootstrapping function separately for Ethnicity and Insurance
e1_results <- bootstrap_metrics_by_single_group(LR_test, num_bootstrap, "Ethnicity")
i1_results <- bootstrap_metrics_by_single_group(LR_test, num_bootstrap, "Insurance")

# Combine and print results
results_df <- bind_rows(e1_results, i1_results)
print("Bootstrap SE metrics")
print(results_df)


#-------------------------------Differences-----------------------------#
# Compute absolute differences between demographic groups
diff_white_nwhite <- abs(LR_demo_results_df[LR_demo_results_df$Dataset == "LR_test_white", 2:5] - 
                           LR_demo_results_df[LR_demo_results_df$Dataset == "LR_test_nwhite", 2:5])

diff_private_nprivate <- abs(LR_demo_results_df[LR_demo_results_df$Dataset == "LR_test_private", 2:5] - 
                               LR_demo_results_df[LR_demo_results_df$Dataset == "LR_test_nprivate", 2:5])

# Format the results into a clean dataframe
diff_metrics <- data.frame(
  Metric = colnames(LR_demo_results_df)[2:5],
  Diff_White_NWhite = as.numeric(diff_white_nwhite),
  Diff_Private_NPrivate = as.numeric(diff_private_nprivate)
)

# Print the results
print(diff_metrics)

#--------------------Bootstrap test data for difference between group metrics-----------------------#

# Set seed for reproducibility
set.seed(123)

# Number of bootstrap samples
num_bootstrap <- 200  

# Function to perform bootstrapping, compute metrics, and calculate the difference
bootstrap_metrics_by_group <- function(test_data, num_bootstrap, demographic_col) {
  # Initialize list to store results (differences in metrics)
  diff_results_list <- list()
  
  for (i in 1:num_bootstrap) {
    # Generate bootstrap sample
    boot_sample <- test_data[sample(nrow(test_data), replace = TRUE), ]
    
    # Split by demographic subgroup
    demographic_groups <- split(boot_sample, boot_sample[[demographic_col]])
    
    # If there are both groups, compute metrics for each
    if (length(demographic_groups) == 2) {
      # Extract group names (assuming two groups, e.g., "White" vs "Non-White")
      group_names <- names(demographic_groups)
      
      # Compute metrics for each group
      subgroup_metrics <- lapply(demographic_groups, function(group_data) {
        # Make predictions
        pred_probs <- predict(model, newdata = group_data, type = "response")
        predictions <- ifelse(pred_probs > threshold, 1, 0)  
        
        # Confusion matrix
        conf_matrix <- table(Predicted = predictions, Actual = group_data$dep)
        
        # Extract TP, TN, FP, FN (handle cases where table might be incomplete)
        TP <- ifelse("1" %in% rownames(conf_matrix) & "1" %in% colnames(conf_matrix), conf_matrix["1", "1"], 0)
        TN <- ifelse("0" %in% rownames(conf_matrix) & "0" %in% colnames(conf_matrix), conf_matrix["0", "0"], 0)
        FP <- ifelse("0" %in% rownames(conf_matrix) & "1" %in% colnames(conf_matrix), conf_matrix["0", "1"], 0)
        FN <- ifelse("1" %in% rownames(conf_matrix) & "0" %in% colnames(conf_matrix), conf_matrix["1", "0"], 0)
        
        # Compute metrics (handle division by zero)
        accuracy <- mean(predictions == group_data$dep)
        sensitivity <- ifelse((TP + FN) > 0, TP / (TP + FN), NA)
        specificity <- ifelse((TN + FP) > 0, TN / (TN + FP), NA)
        
        # Compute AUC
        roc_curve <- roc(group_data$dep, pred_probs, quiet = TRUE)
        auc_value <- auc(roc_curve)
        
        return(c(Accuracy = accuracy, Sensitivity = sensitivity, Specificity = specificity, AUC = auc_value))
      })
      
      # Combine the results of both subgroups into a dataframe
      metrics_df <- data.frame(
        Group = group_names,
        Accuracy = sapply(subgroup_metrics, function(x) x[1]),
        Sensitivity = sapply(subgroup_metrics, function(x) x[2]),
        Specificity = sapply(subgroup_metrics, function(x) x[3]),
        AUC = sapply(subgroup_metrics, function(x) x[4])
      )
      
      # Calculate the differences between the two groups for each metric
      diff_results_list[[i]] <- data.frame(
        Diff_Accuracy = diff(metrics_df$Accuracy),
        Diff_Sensitivity = diff(metrics_df$Sensitivity),
        Diff_Specificity = diff(metrics_df$Specificity),
        Diff_AUC = diff(metrics_df$AUC)
      )
    }
  }
  
  # Combine all bootstrap results and calculate the standard error of the differences
  diff_results_df <- do.call(rbind, diff_results_list)
  
  # Create row names based on demographic groups being compared
  group1 <- ifelse(demographic_col == "Ethnicity", "White", "Private Insurance")
  group2 <- ifelse(demographic_col == "Ethnicity", "Non-White", "Non-Private Insurance")
  
  # Compute SE of differences
  se_diff_results <- colSums(diff_results_df^2) / num_bootstrap  # Variance formula, sqrt(variance) = SE
  
  # Return results with proper row names
  result <- data.frame(
    SE_Diff_Accuracy = sqrt(se_diff_results[1]),
    SE_Diff_Sensitivity = sqrt(se_diff_results[2]),
    SE_Diff_Specificity = sqrt(se_diff_results[3]),
    SE_Diff_AUC = sqrt(se_diff_results[4])
  )
  
  # Assign row names that describe the demographic subgroups being compared
  rownames(result) <- paste(group1, "vs", group2)
  
  return(result)
}

# Apply the bootstrapping function separately for Ethnicity and Insurance
e1_diff_se <- bootstrap_metrics_by_group(LR_test, num_bootstrap, "Ethnicity")
i1_diff_se <- bootstrap_metrics_by_group(LR_test, num_bootstrap, "Insurance")

# Combine and print results
diff_results_df <- bind_rows(e1_diff_se, i1_diff_se)
print("Bootstrap SE metrics diff")
print(diff_results_df)
