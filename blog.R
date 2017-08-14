#------------------------------
library(GoTr)
library(listviewer)
library(tidyverse)
library(stringr)
library(networkD3)
library(visNetwork)
library(igraph)
library(formattable)

source("utils.R")

#-----------------------------
## Get all houses data
## or load from memory as takes long to response
#houses <- 1:9 %>% # Reponse takes ~ 10 min
#  map(function(x) got_api(type = "houses", query = list(page=x, pageSize="50"))) %>%
#  unlist(recursive=FALSE)

load(file.path("data", "houses.rda"))

houses_url <- map_chr(houses, "url")
houses_url_to <- houses_url %>% # Reponse takes ~ 5 mins
  map_chr(function(x) from_url_to(from = x))

#------------------------------
# Gnerate edge list pbject
elist <- tibble(
  from = houses_url %>% 
    map_int(~extract_id_from_url(.x)),
  to = houses_url_to %>%
    map_int(~extract_id_from_url(.x))
)

#------------------------------
# Generate node list pbject
nlist <- map_df(houses, `[`, c("url", "name", "region")) %>%
  group_by(url) %>%
  mutate(id = extract_id_from_url(url))

# drop duplicates in nlist, chances are a house has different branches, regions etc.
elist <- (elist - 1) %>%
  na.omit()
  
#------------------------------
# Group Great Houses * 9 for coloring
greatHouses <- c(
  "Targaryen of King's Landing",
  "Stark of Winterfell",
  "Lannister of Casterly Rock",
  "Arryn of the Eyrie",
  "Tully of Riverrun",
  "Greyjoy of Pyke",
  "Baratheon of Storm's End",
  "Tyrell of Highgarden",
  "Nymeros Martell of Sunspear"
) %>% map_chr(~paste("House", .x))

groupCols <- 'd3.scaleOrdinal().range(["#A3A5A5","#E0A225", "#C93312"]);'

nlist <- nlist %>%
  mutate(
    id = id - 1,
    group = case_when(
      name == "House Baratheon of King's Landing" ~ "House Baratheon of King's Landing",
      name %in% greatHouses ~ "Great Houses",
      TRUE ~ "Bend your knees"
    )
  ) %>%
  na.omit()


#------------------------------------
# network plot using networkD3
# NB
# 1. id must sart from 0
# 2. Links and Nodes only take plain data frames
# 3. No NA is allowed
# 4. param arrows misbehaves or something wrong
# 5. param charge is used to adjust scale of distance between nodes
forceNetwork(Links = as.data.frame(elist), Nodes = as.data.frame(nlist), 
             NodeID = "name", Source = "from", Target = "to",
             Group = "group", colourScale = groupCols, charge = -4,
             opacity = 1, zoom = TRUE, legend = TRUE)#, arrows = TRUE

#------------------------------------
# network plot using visNetwork
# NB
# 1. Add title and label for nodes info
# 2. Position of nodes and links parameter are opposite of networkD3
nlist <- nlist %>%
  mutate(
    title = name, # text on label
    label = str_replace(name, "House *", "")
  ) # hover label, select by
visNetwork(nodes = nlist, edges = elist) %>%
  visIgraphLayout() %>%
  #visPhysics(stabilization = FALSE) %>%
  visEdges(arrows = list(to = list(enabled = TRUE, 
                                   type = 'circal')), width = 1) %>%
  visNodes(color = list(border = "white")) %>%
  visOptions(highlightNearest = list(enabled = T, degree = 1),
             selectedBy = list(variable = "region", multiple = TRUE),
             nodesIdSelection = TRUE
  ) %>%
  visGroups(groupname = "House Baratheon of King's Landing", color = "#C93312") %>%
  visGroups(groupname = "Great Houses", color = "#E0A225") %>%
  visGroups(groupname = "Bend your knees", color = "#A3A5A5") %>%
  visLayout(randomSeed = 123)

#------------------------------------
# indegree, a measure of directed graph centrality
# indegree is a count of the number of ties directed to the node, ie incoming nodes
ig <- graph.data.frame(elist, directed=TRUE)

indegree <- degree(ig, mode="in")
outdegree <- degree(ig, mode="out")
bothdegree <- degree(ig)

top10central <- sort(indegree, decreasing = TRUE)[1:10]

dat <- data.frame(indegree=top10central) %>%
  mutate(id = as.integer(rownames(.))) %>% # turn rowname from character to integer
  left_join(nlist[, c("id", "name", "region", "group")], by = "id") %>%
  select(name, indegree, region, group)

formattable(dat, list(
  indegree = color_bar('lightblue'),
  group = formatter("span",
    style = x ~ style(
      color = ifelse(x == "House Baratheon of King's Landing", "#C93312", 
                     ifelse(x == "Great Houses", "#E0A225", "#A3A5A5")),
      font.weight = "bold")
  )
))

