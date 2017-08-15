# GoTr - R wrapper for An API of Ice And Fire
Ava Yang  



It's Game of Thrones time again as the battle for Westeros is heating up. There are tons of ideas, ingredients and interesting analyses out there and I was craving for my own flavour. So step zero, where is the data? 

Jenny Bryan's [purrr tutorial](https://jennybc.github.io/purrr-tutorial/ls00_inspect-explore.html) introduced the list **got_chars**, representing characters information from the first five books, which seems not much fun beyond exercising list manipulation muscle. However, it led me to an [API of Ice and Fire](https://anapioficeandfire.com/), the world's greatest source for quantified and structured data from the universe of Ice and Fire including the HBO series Game of Thrones. I decided to create my own API functions, or better, an R package (inspired by the famous rwar package). 

The API resources cover 3 types of endpoint - Books, Characters and Houses. `GoTr` pulls data in JSON format and parses them to R list objects. `httr`'s [Best practices for writing an API package](https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html) by Hadley Wickham is another life saver. 

The package contains:
- One function `got_api()`
- Two ways to specify parameters generally, i.e. endpoint **type** + **id** or **url**
- Three endpoint types


```r
## Install GoTr from github
#devtools::install_github("MangoTheCat/GoTr")
library(GoTr)
library(tidyverse)
library(listviewer)

# Retrieve books id 5
books_5 <- got_api(type = "books", id = 5)
# Retrieve characters id 583
characters_583 <- got_api(type = "characters", id = 583)
# Retrieve houses id 378
house_378 <- got_api(type = "houses", id = 378)
# Retrieve pov characters data in book 5
povData <- books_5$povCharacters %>% 
  flatten_chr() %>%
  map(function(x) got_api(url = x))
```


```r
# Helpful functions to check structure of list object
length(books_5)
## [1] 11
names(books_5)
##  [1] "url"           "name"          "isbn"          "authors"      
##  [5] "numberOfPages" "publisher"     "country"       "mediaType"    
##  [9] "released"      "characters"    "povCharacters"
names(house_378)
##  [1] "url"              "name"             "region"          
##  [4] "coatOfArms"       "words"            "titles"          
##  [7] "seats"            "currentLord"      "heir"            
## [10] "overlord"         "founded"          "founder"         
## [13] "diedOut"          "ancestralWeapons" "cadetBranches"   
## [16] "swornMembers"
str(characters_583, max.level = 1)
## List of 16
##  $ url        : chr "https://anapioficeandfire.com/api/characters/583"
##  $ name       : chr "Jon Snow"
##  $ gender     : chr "Male"
##  $ culture    : chr "Northmen"
##  $ born       : chr "In 283 AC"
##  $ died       : chr ""
##  $ titles     :List of 1
##  $ aliases    :List of 8
##  $ father     : chr ""
##  $ mother     : chr ""
##  $ spouse     : chr ""
##  $ allegiances:List of 1
##  $ books      :List of 1
##  $ povBooks   :List of 4
##  $ tvSeries   :List of 6
##  $ playedBy   :List of 1
map_chr(povData, "name")
##  [1] "Aeron Greyjoy"     "Arianne Martell"   "Arya Stark"       
##  [4] "Arys Oakheart"     "Asha Greyjoy"      "Brienne of Tarth" 
##  [7] "Cersei Lannister"  "Jaime Lannister"   "Samwell Tarly"    
## [10] "Sansa Stark"       "Victarion Greyjoy" "Areo Hotah"
#listviewer::jsonedit(povData)
```


Another powerful parameter is **query** which allows filtering by specific attribute such as the name of a character, pagination and so on.

It's worth knowing about pagination. The first simple request will render a list of 10 elements, since the default number of items per page is 10. The maximum valid **pageSize** is 50, i.e. if 567 is passed on to it, you still get 50 characters. 



```r
# Retrieve character by name
Arya_Stark <- got_api(type = "characters", query = list(name = "Arya Stark"))
# Retrieve characters on page 3, change page size to 20. 
characters_page_3 <- got_api(type = "characters", query = list(page = "3", pageSize="20"))
```


So how do we get ALL books, characters or houses information? The package does not provide the function directly but here's an implementation. 

```r
# Retrieve all books
booksAll <- got_api(type = "books", query = list(pageSize="20"))
# Extract names of all books
map_chr(booksAll, "name")
```

```
##  [1] "A Game of Thrones"              "A Clash of Kings"              
##  [3] "A Storm of Swords"              "The Hedge Knight"              
##  [5] "A Feast for Crows"              "The Sworn Sword"               
##  [7] "The Mystery Knight"             "A Dance with Dragons"          
##  [9] "The Princess and the Queen"     "The Rogue Prince"              
## [11] "The World of Ice and Fire"      "A Knight of the Seven Kingdoms"
```


```r
# Retrieve all houses
houses <- 1:9 %>% 
  map(function(x) got_api(type = "houses", query = list(page=x, pageSize="50"))) %>%
  unlist(recursive=FALSE)
```




```r
map_chr(houses, "name") %>% length()
## [1] 444
map_df(houses, `[`, c("name", "region")) %>% head()
## # A tibble: 6 x 2
##                          name          region
##                         <chr>           <chr>
## 1                House Algood The Westerlands
## 2 House Allyrion of Godsgrace           Dorne
## 3                 House Amber       The North
## 4               House Ambrose       The Reach
## 5  House Appleton of Appleton       The Reach
## 6     House Arryn of Gulltown        The Vale
```

The **houses** list is a starting point for a social network analysis: Mirror mirror tell me, who are the most influential houses in the Seven Kingdom? Stay tuned for that is the topic of the next blogpost.

Thanks to all open resources. Please comment, fork, issue, star the work-in-progress on our [GitHub repository](https://github.com/MangoTheCat/blog_GoTr).
