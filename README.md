# blog_GoTr
blogpost about GoTr and house network analysis

It's Game of Throne time again and the last time. There are tons of ideas, ingredients and findings out there and I was craving for my own flavour. So step zero, where is data? 

Jenny Bryan's [purrr tutorial](https://jennybc.github.io/purrr-tutorial/ls00_inspect-explore.html) introduced list **got_chars**, representing point-of-view characters informaion alongside the first five books, which seems not much fun beyond exercising list manipulation muscle. However, it led me to an [API of Ice and Fire](https://anapioficeandfire.com/), the world's greatest source for quantified and structured data from the universe of Ice and Fire including the HBO series Game of Thrones. I decided to create my API functions, or better, an R package (inspired by the famous rwar package). 

The API resources cover 3 types of endpoint - Books, Characters and Houses. `GoTr` pulls data in JSON format and parse them to R list objects. `httr`'s [Best practices for writing an API package](https://cran.r-project.org/web/packages/httr/vignettes/api-packages.html) by Hadley is another life saver. 

- One function `got_api()`
- Two ways to specify parameters generally, i.e. endpoint **type** + **id** or **url**
- Three endpoint types

```{r basics, message=FALSE, warning=FALSE}
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
# Retrieve pov characters data in book 8
povData <- books_5$povCharacters %>% 
  flatten_chr() %>%
  map(function(x) got_api(url = x))
```

```{r view, eval=FALSE}
# Helpful functions to check structure of list object
length(books_5)
names(books_5)
names(house_378)
str(characters_583, max.level = 1)
map_chr(povData, "name")
listviewer::jsonedit(povData)
```


Another powerful parameter is **query** which allows filtering by specific attribute such as name of a character, pagination and so on.

It's worth knowing about pagination. The first simple request will render a list of 10 elements, since the default number of items per page is 10. The maximum of valid **pageSize** is 50, i.e. if 567 is passed on to it, you still get 50 characters. 


```{r pagination, eval=FALSE}
# Retrieve character by name
Arya_Stark <- got_api(type = "characters", query = list(name = "Arya Stark"))
# Retrieve characters on page 3, change page size to 20. 
characters_page_3 <- got_api(type = "characters", query = list(page = "3", pageSize="20"))
```


It may have occurred to you how to get ALL books, characters or houses information? The package does not provide the function directly. Here's an implementation. 
```{r booksAll, eval=TRUE}
# Retrieve all books
booksAll <- got_api(type = "books", query = list(pageSize="20"))
# Extract names of all books
map_chr(booksAll, "name")
```

```{r houses, eval=FALSE}
# Retrieve all houses
houses <- 1:9 %>% 
  map(function(x) got_api(type = "houses", query = list(page=x, pageSize="50"))) %>%
  unlist(recursive=FALSE)
```

```{r housesView}
# Load the data as it takes too long
load("data/houses.rda")
map_chr(houses, "name") %>% length()
map_df(houses, `[`, c("name", "region")) %>% head()
```

The **houses** list is a starting point of social network analysis going forward. Mirror mirror tell me, who are the most influential houses in the Seven Kingdom?

Thanks to all open resources. Please comment, fork, issue, star the work-in-progress on our GitHub repository.
