#############################
"IMD Local Authority Summary"
#############################

url <- "https://www.gov.uk/government/uploads/system/uploads/attachment_data/file/464464/File_10_ID2015_Local_Authority_District_Summaries.xlsx"
destfile <- data_slash("imd_local_auth.xlsx")

tmp <- curl::curl_download(url, destfile)
imd_la <- readxl::read_excel(destfile, sheet = 2) # other sheets for different indices.

