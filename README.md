# STA496: Fair Machine Learning with Biased Labels

## 1. Literature review notes
- A tutorial on fairness in machine learning in healthcare
- Clinical Concept Embeddings Learned from Massive Sources of Multimodal Medical Data
- Clinical knowledge extraction via sparse embedding regression (KESER) with multi-center large scale electronic health record data
- Multiview Incomplete Knowledge Graph Integration with application to cross-institutional EHR data harmonization
- Measuring social bias in knowledge graph embeddings
- The Lifecycle of "Facts": A Survey of Social Bias in Knowledge Graphs
- Learning a Health Knowledge Graph from Electronic Medical Records
- Robustly Extracting Medical Knowledge from EHRs: A Case Study of Learning a Health Knowledge Graph

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
### 3.1 CUI
- MIMIC_summary.R (W12a)
- MIMIC_date.R(W11)
### 3.2 Phecode/ ICD:
- MIMIC-III_summary.R (W12b need to change the last line to ICD_Data_for_generating_embedding.Rdata)
- Phecode_transformation.R

## 4. Data Preprocessing
- Phecode_preprocessing.R: gives Phecode_Data_for_generating_embedding.Rdata
- ICD_preprocessing.R: gives ICD_Data_for_generating_embedding.Rdata
  
## 5. Embedding Training (all output embedding matrix)
Winter break
- CUI_embedding.R (use mimic.db)
- ICD_embedding.R (use ICD_Data_for_generating_embedding.Rdata)
- Phecode_embedding.R (use Phecode_Data_for_generating_embedding.Rdata)

W13
- CUI+Phecode_embedding.R (use mimic.db and Phecode_Data_for_generating_embedding.Rdata)
- CUI+Phecode_embedding_demographics.R: generate demographic specific embeddings (use mimic.db, EHR_demographic.csv, Phecode_Data_for_generating_embedding.Rdata and admissions.csv)

## 6. Embedding Evaluation on known pairs
Calculate AUC, Accuracy, Sensitivity, Specificity
### 6.1 Overall 
Winter break
- CUI_evalutation.R
- ICD_evaluation.R
- Phecode_evaluation.R
W13
- CUI+Phecode_evaluation.R (use CUI+Phecode_kdim.Rdata from embedding training)

### 6.2 By Demographic groups
W13
- CUI+Phecode_demographics_evaluation.R (use demo_CUI+Phecode_kdim.Rdata from embedding training)

### 6.3 Bootstrapping
W19
- Bootstrap_CUI+Phecode_embedding_demographics.R: generate 9 bootstrapped embeddings demo_CUI+Phecode_1500dim_j.Rdata
- bootstrapping_demo_se.R: evaluate bootstrapped metric means and se (use bootstrapped embeddings and original embeddings)

## 7. Incorporate Pre-trained embedding
Source: https://celehs.github.io/PEHRT/m2.html
W17+18
- PLM.ipynb: gives PLMembeddings.csv
- PLM.R: embeddings+evaluation (use CUI+Phecode_kdim.Rdata,demo_CUI+Phecode_kdim.Rdata, PLMembeddings.csv,phecode_definitions1.2.csv)
  
## 8. KESER Depression Feature Selection
W14+15
- CUI_Phecode_train_test.R: gives train and test CUI/Phecode embeddings (use use mimic.db and Phecode_Data_for_generating_embedding.Rdata)
- Dep_featureselection_CUI/Phecode.R (use CUI_kdim.Rdata, train_CUI_kdim.Rdata, test_CUI_kdim.Rdata, Phecode_kdim.Rdata, train_Phecode_kdim.Rdata,test_Phecode_kdim.Rdata)
- Dep_featureselection_CUI+Phecode.R (use CUI+Phecode_kdim.Rdata, white_CUI+Phecode_kdim.Rdata, nwhite_CUI+Phecode_kdim.Rdata)
  
## 9. Supervised ML models for Depression Prediction
W20
(use mimic.db, EHR_demographic.csv, Phecode_Data_for_generating_embedding.Rdata and admissions.csv)
### 9.1 Logistic Regression
- Dep_LR.R: on overall and demogroups observations
- Dep_LR_fullvar.R: on all observations, including demographic indicators

### 9.2 Random Forest
- Dep_randomforest.R: on overall and demogroups observations
- Dep_randomforest_fullvar.R: on all observations, including demographic indicators
