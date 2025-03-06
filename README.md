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

Source: https://www.dropbox.com/scl/fo/m4sdd07arwp4gts8ea5tg/h?rlkey=99fb1m2j2b9z3ido02w2eu9wg&e=1&dl=0

MIMIC data -> Data cleaning -> ehr data prep
- mimic.db
- EHR_demographic.csv
  
Source: https://physionet.org/content/mimiciv/3.1/hosp/#files-panel

base -> hosp
- admission.csv
- diagnosis_icd.csv
- d_icd_diagnoses.csv

Other datasets:
- ICD_Phecode.Rdata
- phecode_definitions1.2.csv

## 3. Data Summary 
- CUI_summary.R 
- ICD_summary.R 
- Phecode_summary.R
- MIMIC-III_demographics. R

## 4. Data Preprocessing
- Phecode_preprocessing.R: gives Phecode_Data_for_generating_embedding.Rdata
- ICD_preprocessing.R: gives ICD_Data_for_generating_embedding.Rdata
  
## 5. Embedding Training (all output embedding matrix)

- CUI_embedding.R (use mimic.db)
- ICD_embedding.R (use ICD_Data_for_generating_embedding.Rdata)
- Phecode_embedding.R (use Phecode_Data_for_generating_embedding.Rdata)
- CUI+Phecode_embedding.R (use mimic.db and Phecode_Data_for_generating_embedding.Rdata)
- CUI+Phecode_embedding_demographics.R: generate demographic specific embeddings (use mimic.db, EHR_demographic.csv, Phecode_Data_for_generating_embedding.Rdata and admissions.csv)

## 6. Embedding Evaluation on known pairs
Calculate AUC, Accuracy, Sensitivity, Specificity
### 6.1 Overall 

- CUI_evalutation.R
- ICD_evaluation.R
- Phecode_evaluation.R
- CUI+Phecode_evaluation.R (use CUI+Phecode_kdim.Rdata from embedding training)

### 6.2 By Demographic groups

- CUI+Phecode_demographics_evaluation.R (use demo_CUI+Phecode_kdim.Rdata from embedding training)

### 6.3 Bootstrapping

- Bootstrap_CUI+Phecode_embedding_demographics.R: generate 9 bootstrapped embeddings demo_CUI+Phecode_1500dim_j.Rdata
- bootstrapping_demo_se.R: evaluate bootstrapped metric means and se (use bootstrapped embeddings and original embeddings)

## 7. Incorporate Pre-trained embedding
Reference: https://celehs.github.io/PEHRT/m2.html

- PLM.ipynb: gives PLMembeddings.csv
- PLM.R: embeddings+evaluation (use CUI+Phecode_kdim.Rdata,demo_CUI+Phecode_kdim.Rdata, PLMembeddings.csv,phecode_definitions1.2.csv)
  
## 8. KESER Depression Feature Selection
Reference: https://github.com/celehs/KESER 

- CUI_Phecode_train_test.R: gives train and test CUI/Phecode embeddings (use use mimic.db and Phecode_Data_for_generating_embedding.Rdata)
- Dep_featureselection_CUI/Phecode.R (use CUI_kdim.Rdata, train_CUI_kdim.Rdata, test_CUI_kdim.Rdata, Phecode_kdim.Rdata, train_Phecode_kdim.Rdata,test_Phecode_kdim.Rdata)
- Dep_featureselection_CUI+Phecode.R (use CUI+Phecode_kdim.Rdata, white_CUI+Phecode_kdim.Rdata, nwhite_CUI+Phecode_kdim.Rdata)
  
## 9. Supervised ML models for Depression Prediction

(use mimic.db, EHR_demographic.csv, Phecode_Data_for_generating_embedding.Rdata and admissions.csv)
### 9.1 Logistic Regression
- Dep_LR.R: on overall and demogroups observations
- Dep_LR_fullvar.R: on all observations, including demographic indicators

### 9.2 Random Forest
- Dep_randomforest.R: on overall and demogroups observations
- Dep_randomforest_fullvar.R: on all observations, including demographic indicators
