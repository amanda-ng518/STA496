#-----------------------Set up----------------------------#
library(dplyr)
library(readr)
library(ggplot2)
#-----------------------Read data----------------------------#
note <- read_csv("admissions.csv")

data = note%>%
  group_by(subject_id)%>%
  slice(1)

#-----------------------Insurance type----------------------------#
insurance_data <- data %>%
  group_by(insurance) %>%
  summarise(insurance_counts = n())

ggplot(insurance_data, aes(x = insurance, y = insurance_counts)) +
  geom_bar(stat = "identity", fill = "cornflowerblue") +
  geom_text(aes(label = insurance_counts), vjust = -0.5, color = "black", size = 3) + 
  labs(title = "Number of Observations by Insurance Type", x = "Insurance Type", y = "Count") +
  theme_minimal()

#-----------------------Language----------------------------#
language_data <- data %>%
  filter(language!= "English")%>%
  group_by(language) %>%
  summarise(language_counts = n())

# English = 202713

ggplot(language_data, aes(x = language, y = language_counts)) +
  geom_bar(stat = "identity", fill = "cornflowerblue") +
  geom_text(aes(label = language_counts), hjust = -0.2, color = "black", size = 3) + 
  labs(title = "Number of Observations by Language Type (Non-English)", x = "Language Type", y = "Count") +
  theme_minimal()+
  coord_flip() 

#-----------------------Marital status----------------------------#
marital_data <- data %>%
  group_by(marital_status) %>%
  summarise(marital_counts = n())

ggplot(marital_data, aes(x = marital_status, y = marital_counts)) +
  geom_bar(stat = "identity", fill = "cornflowerblue") +
  geom_text(aes(label = marital_counts), vjust = -0.5, color = "black", size = 3) + 
  labs(title = "Number of Observations by Marital status", x = "Marital status", y = "Count") +
  theme_minimal()

#-----------------------Race----------------------------#
race_data <- data %>%
  filter(race != "WHITE")%>%  
  group_by(race) %>%
  summarise(race_counts = n())

# WHITE = 138346

ggplot(race_data, aes(x = race, y = race_counts)) +
  geom_bar(stat = "identity", fill = "cornflowerblue") +
  geom_text(aes(label = race_counts), hjust = -0.2, color = "black", size = 3) + 
  labs(title = "Number of Observations by Race Type (Non-white)", x = "Race Type", y = "Count") +
  theme_minimal()+
  coord_flip() 

#-----------------------Admission type----------------------------#
admission_type_data <- data %>%
  group_by(admission_type) %>%
  summarise(admission_type_counts = n())

ggplot(admission_type_data, aes(x = admission_type, y = admission_type_counts)) +
  geom_bar(stat = "identity", fill = "cornflowerblue") +
  geom_text(aes(label = admission_type_counts), hjust = -0.2, color = "black", size = 3) + 
  labs(title = "Number of Observations by Admission Type", x = "Admission Type", y = "Count") +
  theme_minimal()+
  coord_flip() 

#-----------------------Admission location----------------------------#
admission_location_data <- data %>%
  group_by(admission_location) %>%
  summarise(admission_location_counts = n())

ggplot(admission_location_data, aes(x = admission_location, y = admission_location_counts)) +
  geom_bar(stat = "identity", fill = "cornflowerblue") +
  geom_text(aes(label = admission_location_counts), hjust = -0.2, color = "black", size = 3) + 
  labs(title = "Number of Observations by Admission Location Type", x = "Admission Location Type", y = "Count") +
  theme_minimal()+
  coord_flip() 

#-----------------------Discharge location----------------------------#
discharge_location_data <- data %>%
  group_by(discharge_location) %>%
  summarise(discharge_location_counts = n())

ggplot(discharge_location_data, aes(x = discharge_location, y = discharge_location_counts)) +
  geom_bar(stat = "identity", fill = "cornflowerblue") +
  geom_text(aes(label = discharge_location_counts), hjust = -0.2, color = "black", size = 3) + 
  labs(title = "Number of Observations by Discharge Location Type", x = "Discharge Location Type", y = "Count") +
  theme_minimal()+
  coord_flip() 
