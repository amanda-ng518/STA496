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

Source: https://www.dropbox.com/scl/fo/m4sdd07arwp4gts8ea5tg/h?rlkey=99fb1m2j2b9z3ido02w2eu9wg&e=1&dl=0

File path: MIMIC data -> Data cleaning -> ehr data prep
- mimic.db
- EHR_demographic.csv
  
Source: https://physionet.org/content/mimiciv/3.1/hosp/#files-panel

File path: base -> hosp
- admission.csv
- diagnosis_icd.csv
- d_icd_diagnoses.csv

Some additional datasets are available under the [Data preprocessing directory](https://github.com/amanda-ng518/STA496/tree/af8c8af2c25aec4b50261bd31f896f85daf2e15b/Data%20preprocessing):
- ICD_Phecode.Rdata
- phecode_definitions1.2.csv

### 2.2 R library
The following R packages are necessary to run the R scripts.

readr, dplyr, tidyr, ggplot2, PheWAS, icd, kgraph, RSQLite, stringr, nlpembeds, KESER, wordcloud, tidyverse, igraph, ggraph, pROC, randomForest

## 3. Data Summary 

- CUI_summary.R
  - Required datasets: mimic.db
- ICD_summary.R 
  - Required datasets: admissions.csv, diagnoses_icd.csv
- Phecode_summary.R
  - Required datasets: admissions.csv, diagnoses_icd.csv, d_icd_diagnoses.csv
- MIMIC-III_demographics. R
  - Required datasets: admissions.csv

## 4. Data Preprocessing
- ICD_preprocessing.R
  - Required datasets: admissions.csv, diagnoses_icd.csv
  - Output: ICD_Data_for_generating_embedding.Rdata
- Phecode_preprocessing.R
  - Required datasets: admissions.csv, diagnoses_icd.csv, d_icd_diagnoses.csv
  - Output: Phecode_Data_for_generating_embedding.Rdata
    
## 5. Embedding Training 

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

Calculate AUC, Accuracy, Sensitivity, Specificity
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

- Bootstrap_CUI+Phecode_embedding_demographics.R: 
  - Required dataset: mimic.db, EHR_demographic.csv, Phecode_Data_for_generating_embedding.Rdata, admissions.csv
  - Output: demogroup_CUI+Phecode_kdim_j.Rdata (9 sets per group)
- bootstrapping_demo_se.R: evaluate bootstrapped metric means and se (use bootstrapped embeddings and original embeddings)
  - Required dataset: demogroup_CUI+Phecode_kdim_j.Rdata
    
## 7. Incorporate Pre-trained embedding
Reference: https://celehs.github.io/PEHRT/m2.html

- PLM.ipynb
  - Required dataset: phecode_definitions1.2.csv
  - Output: PLMembeddings.csv
- PLM.R: generate embeddings + evaluation 
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
Required dataset: mimic.db, EHR_demographic.csv, Phecode_Data_for_generating_embedding.Rdata, admissions.csv

### 9.1 Logistic Regression
- Dep_LR.R
- Dep_LR_fullvar.R

### 9.2 Random Forest
- Dep_randomforest.R
- Dep_randomforest_fullvar.R

Note:

- Dep_method.R = predict presence of depression based on KESER selected features on overall and demogroups observations
- Dep_method_fullvar.R = predict presence of depression based on KESER selected feature and demographic indicators on all observations
