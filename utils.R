#------------------------------------
# Utility functions to plat network
from_url_to <- function(from = "https://anapioficeandfire.com/api/houses/1"){
  overlord <- got_api(url = from) %>% 
    flatten() %>%
    magrittr::extract2("overlord") 
  
  if (overlord == "")
    return("") 
  else return(overlord)
}

extract_id_from_url <- function(url){
  flatten_chr(strsplit(url, "/"))[6] %>%
    as.integer()
}