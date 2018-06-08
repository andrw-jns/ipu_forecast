library(tidyverse)
library(dbplyr)
library(DBI)
library(odbc)


con <- dbConnect(odbc(), 
                 Driver = "SQL Server", 
                 Server = "MLCSU-BI-SQL-SU", 
                 Database = "StrategicWorking", 
                 Trusted_Connection = "True")


con_ref <- dbConnect(odbc(), 
                 Driver = "SQL Server", 
                 Server = "MLCSU-BI-SQL-SU", 
                 Database = "Reference", 
                 Trusted_Connection = "True")


tbdiagnoses <- tbl(con_ref, "DIM_tbDiagnosis") %>% collect()

chapters <- tbdiagnoses %>%
  group_by(ChapterCode, ChapterDescription) %>%
  summarise %>%
  filter(!is.na(ChapterCode))

teens    <- chapters %>% filter(ChapterCode == 1 & ChapterDescription != "Certain infectious and parasitic diseases") %>% pull(ChapterDescription)
twenties <- chapters %>% filter(ChapterCode == 2 & ChapterDescription != "Neoplasms") %>% pull(ChapterDescription)

tbdiagnoses <- tbdiagnoses %>% 
  mutate(chap = case_when(
    ChapterDescription == teens[1] ~ 16,
    ChapterDescription == teens[2] ~ 17,
    ChapterDescription == teens[3] ~ 11,
    ChapterDescription == teens[4] ~ 14,
    ChapterDescription == teens[5] ~ 13,
    ChapterDescription == teens[6] ~ 10,
    ChapterDescription == teens[7] ~ 12,
    ChapterDescription == teens[8] ~ 19,
    ChapterDescription == teens[9] ~ 15,
    ChapterDescription == teens[10]~ 18,
    ChapterDescription == twenties[1]~ 22,
    ChapterDescription == twenties[2]~ 20,
    ChapterDescription == twenties[3]~ 21
  )) %>% 
  mutate(chapter = ifelse(is.na(chap), ChapterCode, chap)) %>% 
  select(-ChapterCode, -chap)

# Need to remove the unicode chars from ChapterDescription: 
"Try one of these solutions:"
# uni <- prot_flw_count[68,1]
# uni
# str_detect(uni, "\\*")
# stri_enc_isascii(uni)
# stri_trans_general("gro\u00df", "latin-ascii")
# stri_trans_general("stringi", "latin-greek")
# # saveRDS(chronixx_flw_data, "chronixx.RDS")
# stringi::stri_trans_general(uni)
# stringi::tri_trans_general("\u0104", "nfd; lower")
# Sample only these rows (1-40) because of odd characters: 



tbdiagnoses %>% slice(1128:1132) %>% View()

devtools::install_github("rstats-db/odbc@SQLTable")

dbWriteTable(con, "aj_180607_icd10_chap_fix", tbdiagnoses)
copy_to(con, test1, in_schema("DEFAULTS", "aj_180607_icd10_chap_fix"), temporary = F)

