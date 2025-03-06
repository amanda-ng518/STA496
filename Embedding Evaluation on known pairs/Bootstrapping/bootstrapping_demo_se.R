library(icd)
library(readr)
library(dplyr)
library(tidyr)
library(PheWAS)
library(kgraph)

#-----------------------Read data----------------------------#
load("nprivate_CUI+Phecode_1500dim.Rdata") #demogroup_m_embeds_1500
load("nprivate_CUI+Phecode_1500dim_1.Rdata") 
load("nprivate_CUI+Phecode_1500dim_2.Rdata") 
load("nprivate_CUI+Phecode_1500dim_3.Rdata") 
load("nprivate_CUI+Phecode_1500dim_4.Rdata") 
load("nprivate_CUI+Phecode_1500dim_5.Rdata") 
load("nprivate_CUI+Phecode_1500dim_6.Rdata") 
load("nprivate_CUI+Phecode_1500dim_7.Rdata") 
load("nprivate_CUI+Phecode_1500dim_8.Rdata") 
load("nprivate_CUI+Phecode_1500dim_9.Rdata") 

#-----------------------Define related pairs--------------------------#
data('df_cuis_pairs')
df_cuis_pairs=df_cuis_pairs[c(1, 3)]

load("ICD_Phecode.Rdata") # ICD_Phecode transformation: ICD_ver_def

# I defined related pairs by Phecode Hierarchy
Phecode_trim = ICD_ver_def%>%
  select(phecode,phecode_parent)%>%
  unique()

# Create Phecode pairs for the same phecode_parent group
phecode_pairs_data <- Phecode_trim %>%
  group_by(phecode_parent) %>%
  filter(n() > 1) %>%  # Keep groups with more than 1 observation
  summarize(phecode_pairs = list(combn(phecode, 2, simplify = FALSE)), .groups = "drop") %>%
  unnest(phecode_pairs) %>%
  transmute(phecode_1 = sapply(phecode_pairs, `[`, 1),
            phecode_2 = sapply(phecode_pairs, `[`, 2))

colnames(phecode_pairs_data) <- colnames(df_cuis_pairs)  
combined_pairs <- rbind(df_cuis_pairs, phecode_pairs_data)

#----------------------Bootstrapped TPR-FPR-------------------------------------#
# threshold_projs = 0.9 (default)

# Define FPR values for TPR extraction
fpr_values <- c(0.05, 0.1, 0.2)

# Initialize a matrix to store TPR values (rows: iterations, columns: FPR values)
bootstrap_tpr <- matrix(NA, nrow = 9, ncol = length(fpr_values))

# Loop through 1 to 9
for (i in 1:9) {
  embed_var <- get(paste0("nprivate_m_embeds_1500_", i))  # Get the embedding variable dynamically
  fit_kg <- fit_embeds_kg(embed_var, 'cosine', df_pairs = combined_pairs[c(1, 2)])
  roc_curve <- fit_kg$roc  # Store the ROC result
  
  # Extract TPR at specified FPR values and store in the matrix
  bootstrap_tpr[i, ] <-  as.numeric(unlist(pROC::coords(roc_curve, x = fpr_values, input = "1-specificity", ret = "sensitivity")))
}

# Compute standard error of TPR estimates
boot_tpr_se <- apply(bootstrap_tpr, 2, sd, na.rm = TRUE)
boot_tpr_se <- boot_tpr_se/3

# Compute mean of boot TPR estimates
boot_tpr_at_fpr <- colMeans(bootstrap_tpr, na.rm = TRUE)

# Compute non-bootstrap TPR using the original embeddings
fit_kg_nonboot <- fit_embeds_kg(nprivate_m_embeds_1500, 'cosine', df_pairs = combined_pairs[c(1, 2)])
roc_nonboot <- fit_kg_nonboot$roc
tpr_nonboot <- as.numeric(unlist(pROC::coords(roc_nonboot, x = fpr_values, input = "1-specificity", ret = "sensitivity")))

# Combine results into a dataframe
data.frame(FPR = fpr_values, TPR_orig = tpr_nonboot, boot_TPR = boot_tpr_at_fpr, boot_SE = boot_tpr_se)
