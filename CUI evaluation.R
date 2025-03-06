library(kgraph)

# m_embeds: each row is a code embedding (rowname = code)
# df_cuis_pairs: known relationship matrix, each row is a relationship between two codes
data('df_cuis_pairs')

#-----------------------Read data----------------------------#
load("CUI_1500dim.Rdata") #m_embeds_1500
load("CUI_2000dim.Rdata") #m_embeds_2000
load("CUI_2500dim.Rdata") #m_embeds_2500
load("CUI_3000dim.Rdata") #m_embeds_3000

#-----------------------Define related pairs--------------------------#
data('df_cuis_pairs')

#---------------------------------------AUC------------------------------------------#
# FPR = 0.01
fit_kg_1500_001= fit_embeds_kg(m_embeds_1500, 'cosine', threshold_projs=0.99,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_1500_001$roc, print.auc = TRUE)
fit_kg_2000_001= fit_embeds_kg(m_embeds_2000, 'cosine', threshold_projs=0.99,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_2000_001$roc, print.auc = TRUE)
fit_kg_2500_001= fit_embeds_kg(m_embeds_2500, 'cosine', threshold_projs=0.99,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_2500_001$roc, print.auc = TRUE)
fit_kg_3000_001= fit_embeds_kg(m_embeds_3000, 'cosine', threshold_projs=0.99,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_3000_001$roc, print.auc = TRUE)

# FPR = 0.05
fit_kg_1500_005= fit_embeds_kg(m_embeds_1500, 'cosine', threshold_projs=0.95,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_1500_005$roc, print.auc = TRUE)
fit_kg_2000_005= fit_embeds_kg(m_embeds_2000, 'cosine', threshold_projs=0.95,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_2000_005$roc, print.auc = TRUE)
fit_kg_2500_005= fit_embeds_kg(m_embeds_2500, 'cosine', threshold_projs=0.95,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_2500_005$roc, print.auc = TRUE)
fit_kg_3000_005= fit_embeds_kg(m_embeds_3000, 'cosine', threshold_projs=0.95,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_3000_005$roc, print.auc = TRUE)

# FPR = 0.1
fit_kg_1500_01= fit_embeds_kg(m_embeds_1500, 'cosine', threshold_projs=0.9,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_1500_01$roc, print.auc = TRUE)
fit_kg_2000_01= fit_embeds_kg(m_embeds_2000, 'cosine', threshold_projs=0.9,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_2000_01$roc, print.auc = TRUE)
fit_kg_2500_01= fit_embeds_kg(m_embeds_2500, 'cosine', threshold_projs=0.9,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_2500_01$roc, print.auc = TRUE)
fit_kg_3000_01= fit_embeds_kg(m_embeds_3000, 'cosine', threshold_projs=0.9,df_pairs = df_cuis_pairs[c(1, 3)])
pROC::plot.roc(fit_kg_3000_01$roc, print.auc = TRUE)
