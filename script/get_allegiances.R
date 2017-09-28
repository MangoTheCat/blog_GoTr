library(purrr)
library(GoTr)
library(tidyverse)
library(rvest)

#get all houses
houses <- 1:9 %>% 
  map(function(x) got_api(type = "houses", query = list(page=x, pageSize="50"))) %>%
  unlist(recursive=FALSE) %>% 
  map(`[`, "name") %>% 
  map(~stringr::str_replace(.x, "House", "")) %>% 
  map(~stringr::str_replace(.x, "of .*", "")) %>% 
  map(stringr::str_trim)
  
# define function to get allegiances
# using a url it scrapes the Allegiance field
# after some processing it then returns a vector of allegiances
get_allegiances <- function(url){
  result <- read_html(url) %>% 
    html_nodes(".pi-border-color") %>% 
    html_text() %>% 
    stringr::str_replace("\n\t\n\t\t", "") %>% 
    stringr::str_replace("\n\t\n\t", " ") %>% 
    stringr::str_replace("\n", "") %>% 
    stringr::str_subset("Allegiance") %>% 
    stringr::str_replace("Allegiance", "") %>% 
    stringr::str_replace_all(" ", "") %>% 
    stringr::str_split("House") %>% 
    stringi::stri_list2matrix() %>% 
    stringr::str_subset("[a-zA-Z]")
  
  return(result)
}
# make function safely as it will fail for some houses
get_allegiances_safely <- safely(get_allegiances, otherwise=NA)

# now for each house, apply the function and extract the result field
# we will filter out the NA fields later
allegiances <- map(houses, ~ sprintf("http://gameofthrones.wikia.com/wiki/House_%s", .x)) %>% 
  map(get_allegiances_safely) %>% 
  map(`[`, "result") %>% 
  flatten() %>% 
  map2(houses, ~list(allegiances=.x, house=.y)) %>% # combine house names with allegiances
  discard(~is.na(.x['allegiances'])) %>% 
  discard(~length(unlist(.x['allegiances']))==0)

saveRDS(allegiances, file="data/allegiances.Rds")
load("data/allegiances.Rds")

head(allegiances)

