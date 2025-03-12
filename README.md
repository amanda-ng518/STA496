# STA496: Fair Machine Learning with Biased Labels

## 1. Literature review notes

|Week|Paper|
|----|-------------------------|
|[1](https://github.com/amanda-ng518/STA496/blob/67c052f13b8a057e4c0fa5df83fa3c773af68af7/Literature%20review%20notes/W1.docx)|A tutorial on fairness in machine learning in healthcare|
|[2](https://github.com/amanda-ng518/STA496/blob/67c052f13b8a057e4c0fa5df83fa3c773af68af7/Literature%20review%20notes/W2.docx)|Clinical Concept Embeddings Learned from Massive Sources of Multimodal Medical Data|
|[3](https://github.com/amanda-ng518/STA496/blob/67c052f13b8a057e4c0fa5df83fa3c773af68af7/Literature%20review%20notes/W3.docx)|Clinical knowledge extraction via sparse embedding regression (KESER) with multi-center large scale electronic health record data|
|[4](https://github.com/amanda-ng518/STA496/blob/67c052f13b8a057e4c0fa5df83fa3c773af68af7/Literature%20review%20notes/W4.docx)|Multiview Incomplete Knowledge Graph Integration with application to cross-institutional EHR data harmonization|
|[5](https://github.com/amanda-ng518/STA496/blob/67c052f13b8a057e4c0fa5df83fa3c773af68af7/Literature%20review%20notes/W5.docx)| Measuring social bias in knowledge graph embeddings|
|[6](https://github.com/amanda-ng518/STA496/blob/67c052f13b8a057e4c0fa5df83fa3c773af68af7/Literature%20review%20notes/W6.docx)|The Lifecycle of "Facts": A Survey of Social Bias in Knowledge Graphs|
|[7a](https://github.com/amanda-ng518/STA496/blob/67c052f13b8a057e4c0fa5df83fa3c773af68af7/Literature%20review%20notes/W7a.docx)| Learning a Health Knowledge Graph from Electronic Medical Records|
|[7b](https://github.com/amanda-ng518/STA496/blob/67c052f13b8a057e4c0fa5df83fa3c773af68af7/Literature%20review%20notes/W7b.docx)|Robustly Extracting Medical Knowledge from EHRs: A Case Study of Learning a Health Knowledge Graph|

## 2. Initial Set up
### 2.1 Datasets
Please download the following datasets.

|Source| File path| Data|
|--|--------------|-------|
|https://www.dropbox.com/scl/fo/m4sdd07arwp4gts8ea5tg/h?rlkey=99fb1m2j2b9z3ido02w2eu9wg&e=1&dl=0|MIMIC data -> Data cleaning -> ehr data prep| <ul><li>mimic.db</li><li>EHR_demographic.csv</li></ul>|      
|https://physionet.org/content/mimiciv/3.1|base -> hosp|<ul><li>admission.csv</li><li>diagnosis_icd.csv</li><li>d_icd_diagnoses.csv</li></ul>|
|[Initial Setup Datasets](https://github.com/amanda-ng518/STA496/tree/32139f5b69bcce9de94b93c0c6dad1b66408c2ab/Initial%20Setup%20Datasets)| |<ul><li>ICD_Phecode.Rdata</li><li>phecode_definitions1.2.csv</li></ul>


### 2.2 R library
The following R packages are required to run the R scripts.

`readr`, `dplyr`, `tidyr`, `ggplot2`, `PheWAS`, `icd`, `kgraph`, `RSQLite`, `stringr`, `nlpembeds`, `KESER`, `wordcloud`, `tidyverse`, `igraph`, `ggraph`, `pROC`, `randomForest`

For `KESER`, please first download the `remote` package and then install `KESER` from Github using the following code:
```
# install.packages("remotes")
remotes::install_github("celehs/KESER")
library(KESER)
```
## 3. Data Summary 

The following R scripts provide information on the EHR datasets such as number of codes each patient has on record, average hospital visits per patient, demographic group distribution in the dataset, etc. This section is not necessary for implementation of latter sections.

- CUI_summary.R
  - Required datasets: mimic.db
- ICD_summary.R 
  - Required datasets: admissions.csv, diagnoses_icd.csv
- Phecode_summary.R
  - Required datasets: admissions.csv, diagnoses_icd.csv, d_icd_diagnoses.csv
- MIMIC-III_demographics. R
  - Required datasets: admissions.csv

## 4. Data Preprocessing

The following R scripts processed the medical notes to extract codes (ICD/Phecode) and assigned each code to the corresponding patient's hospital visit discharge date, recorded in month-year format. We denote the code date as the discharge date. The resulting cleaned dataset is organized such that each row represents a single code extracted from the notes, along with the associated patient ID and discharge date. Note that mimic.db which contains CUI codes has already been cleaned in the desired format.

- ICD_preprocessing.R
  - Required datasets: admissions.csv, diagnoses_icd.csv
  - Output: ICD_Data_for_generating_embedding.Rdata
- Phecode_preprocessing.R
  - Required datasets: admissions.csv, diagnoses_icd.csv, d_icd_diagnoses.csv
  - Output: Phecode_Data_for_generating_embedding.Rdata
    
## 5. Embedding Training 
Reference: https://gitlab.com/thomaschln/nlpembeds

The following R scripts generate embeddings using SVD-PMI method.

- CUI_embedding.R
  - Required dataset: mimic.db
  - Output: CUI_kdim.Rdata
- ICD_embedding.R 
  - Required dataset: ICD_Data_for_generating_embedding.Rdata
  - Output: ICD_kdim.Rdata
- Phecode_embedding.R 
  - Required dataset: Phecode_Data_for_generating_embedding.Rdata
  - Output: Phecode_kdim.Rdata
- CUI+Phecode_embedding.R 
  - Required dataset: mimic.db, Phecode_Data_for_generating_embedding.Rdata
  - Output: CUI+Phecode_kdim.Rdata
- CUI+Phecode_embedding_demographics.R
  - Required dataset: mimic.db, EHR_demographic.csv, Phecode_Data_for_generating_embedding.Rdata, admissions.csv
  - Output: demogroup_CUI+Phecode_kdim.Rdata

## 6. Embedding Evaluation on known pairs
Reference: https://cran.r-project.org/web/packages/kgraph/vignettes/kgraph.html

The following R scripts calculate AUC, accuracy, sensitivity and specificity of the result embeddings using known relationship between codes.

### 6.1 Overall 

- CUI_evalutation.R
  - Required dataset: CUI_kdim.Rdata 
- ICD_evaluation.R
  - Required dataset: ICD_Phecode.Rdata, ICD_kdim.Rdata 
- Phecode_evaluation.R
  - Required dataset: d_icd_diagnoses.csv, Phecode_kdim.Rdata 
- CUI+Phecode_evaluation.R
  - Required dataset: ICD_Phecode.Rdata, CUI+Phecode_kdim.Rdata 

### 6.2 By Demographic groups

- CUI+Phecode_demographics_evaluation.R (use demo_CUI+Phecode_kdim.Rdata from embedding training)
  - Required dataset: ICD_Phecode.Rdata, demogroup_CUI+Phecode_kdim.Rdata
    
### 6.3 Bootstrapping 

The following R scrips create 9 bootstrap samples by resampling observations from the original dataset, and hence generate 9 sets of bootstrap embeddings. These bootstrap embeddings are then used to estimate the standard error of the embedding evaluation metrics.

- Bootstrap_CUI+Phecode_embedding_demographics.R: 
  - Required dataset: mimic.db, EHR_demographic.csv, Phecode_Data_for_generating_embedding.Rdata, admissions.csv
  - Output: demogroup_CUI+Phecode_kdim_j.Rdata (9 sets per group)
- bootstrapping_demo_se.R: 
  - Required dataset: demogroup_CUI+Phecode_kdim.Rdata (i.e. original embedding), demogroup_CUI+Phecode_kdim_j.Rdata (i.e. bootstrap embeddings)
    
## 7. Incorporate Pre-trained embedding
Reference: https://celehs.github.io/PEHRT/m2.html

To enhance the predictive performance of the embeddings, we explored the use of pre-trained language models (PLMs) to generate embeddings based on the descriptions or names of Phecodes and CUIs. The follwing R scripts create an additional set of embeddings by leveraging the description or names information from the codes. These embeddings were then concatenated with the original SCD-PMI-based embeddings. The PLM-concatenated embeddings are evaluated on AUC, accuracy, sensitivity and specificity with known pairs.

- PLM.ipynb
  - Required dataset: phecode_definitions1.2.csv
  - Output: PLMembeddings.csv 
- PLM.R: 
  - Required dataset: CUI+Phecode_kdim.Rdata,demo_CUI+Phecode_kdim.Rdata, PLMembeddings.csv,phecode_definitions1.2.csv

## 8. KESER Depression Feature Selection
Reference: https://github.com/celehs/KESER 

- CUI_Phecode_train_test.R
  - Required dataset: mimic.db, Phecode_Data_for_generating_embedding.Rdata
  - Output: test_CUI_kdim.Rdata, train_CUI_kdim.Rdata, test_Phecode_kdim.Rdata, train_Phecode_kdim.Rdata
- Dep_featureselection_CUI/Phecode.R
  - Required dataset: test_CUI_kdim.Rdata, train_CUI_kdim.Rdata, test_CUI_kdim.Rdata, train_Phecode_kdim.Rdata, train_Phecode_kdim.Rdata,test_Phecode_kdim.Rdata
- Dep_featureselection_CUI+Phecode.R 
  - Required dataset: CUI+Phecode_kdim.Rdata, demogroup_CUI+Phecode_kdim.Rdata, oppositedemogroup_CUI+Phecode_kdim.Rdata
    
## 9. Supervised ML models for Depression Prediction

The following R scrips use logistic regression and random forest to predict presence of depression based on the 20 KESER selected features from previous step. Using the 70:30 training-testing approach, models are fitted using the full training dataset. They were then evaluated on demographic subgroups in the testing dataset, in terms of AUC, accuracy, sensitivity, specificty. Standard errors of metrics are computed by bootstrapping the testing datasets. Difference (and their corresponding standard errors) in metrics between complementary demographic groups (i.e. white vs non-white and private vs non-private insurance) are also computed. Addition models incorporating demographic variables are also fitted (i.e. Dep_method_KESER_demo.R) and evaluated.

Required dataset: mimic.db, EHR_demographic.csv, Phecode_Data_for_generating_embedding.Rdata, admissions.csv

### 9.1 Logistic Regression
- Dep_LR_KESER.R
- Dep_LR_KESER_demo.R

### 9.2 Random Forest
- Dep_randomforest_KESER.R
- Dep_randomforest_KESER_demo.R
