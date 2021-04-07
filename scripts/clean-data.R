library(tidyverse)

setwd('~/Projects/cnig-dem-grabber/scripts/')

clean_mdt02 <- function(df) {
  df %>% 
    mutate(
      datum = str_split(filename, '-') %>% map_chr(., 2),
      utm_zone = str_split(filename, '-') %>% map_chr(., 3) %>% substr(., 3, 4),
      # catch everything after "HU"
      # https://stackoverflow.com/a/39592270
      name = str_extract(filename, '(?<=HU).*') %>% 
        # split into a list, remove the first and last element
        # and build a string again
        str_split('-') %>% 
        sapply(., tail, -1) %>% 
        sapply(., head, -1) %>% 
        sapply(., paste, collapse="-")
    ) %>% 
    mutate(
      utm_zone = as.numeric(utm_zone)
    ) %>% 
    select(id, filename, name, datum, utm_zone)
}

clean_mdt0525 <- function(df) {
  df %>% 
    mutate(
      datum = str_split(filename, '_') %>% map_chr(., 3),
      utm_zone = str_split(filename, '_') %>% map_chr(., 4) %>% substr(., 3, 4),
      # catch everything after "HU"
      # https://stackoverflow.com/a/39592270
      name = str_extract(filename, '(?<=HU).*') %>%
        # extract from the fourth character,
        # remove the last four characters
        # split and get the first element
        str_sub(., 4, str_length(.)) %>%
        str_sub(., 1, str_length(.) - 4) %>% 
        str_split(., '_') %>% 
        map_chr(., 1)
    ) %>% 
    mutate(
      utm_zone = as.numeric(utm_zone),
    ) %>% 
    select(id, filename, name, datum, utm_zone)
}

clean_mdt200 <- function(df) {
  df %>% 
    mutate(
      datum = str_split(filename, '_') %>% map_chr(., 3),
      utm_zone = str_split(filename, '_') %>% map_chr(., 4) %>% substr(., 3, 4),
      # catch everything after "HU"
      # https://stackoverflow.com/a/39592270
      name = str_extract(filename, '(?<=HU).*') %>%
        # extract from the fourth character and
        # remove the last four characters
        str_sub(., 4, str_length(.)) %>%
        str_sub(., 1, str_length(.) - 4)
    ) %>% 
    mutate(
      utm_zone = as.numeric(utm_zone),
      name = str_replace(name, '_', ' ')
    ) %>% 
    mutate(
      name = case_when(
        name == 'A Coruna' ~ 'A Coruña',
        name == 'Alboran' ~ 'Alborán',
        name == 'Almeria' ~ 'Almería',
        name == 'Avila' ~ 'Ávila',
        name == 'Caceres' ~ 'Cáceres',
        name == 'Cadiz' ~ 'Cádiz',
        name == 'Cordoba' ~ 'Córdoba',
        name == 'Jaen' ~ 'Jaén',
        name == 'Leon' ~ 'León',
        name == 'Malaga' ~ 'Málaga',
        name == 'Cordoba' ~ 'Córdoba',
        name == 'Alicante' ~ 'Alacant/Alicante',
        name == 'Alava' ~ 'Araba/Álava',
        name == 'Baleares' ~ 'Illes Balears',
        name == 'Alicante' ~ 'Alacant/Alicante',
        name == 'Valencia' ~ 'València/Valencia',
        name == 'Castellon' ~ 'Castelló/Castellón',
        name == 'Vizcaya' ~ 'Bizkaia',
        name == 'Guipuzcoa' ~ 'Gipuzkoa',
        name == 'Tenerife' ~ 'Santa Cruz de Tenerife',
        name == 'Gran Canaria' ~ 'Las Palmas',
        TRUE ~ name
      )
    ) %>% 
    select(id, filename, name, datum, utm_zone)
}

mdt02 <- read_csv('cnig-series-ids/MDT02.csv') %>% 
  clean_mdt02() %>% 
  write_csv('cnig-cleaned-ids/MDT02.csv')

mdt05 <- read_csv('cnig-series-ids/MDT05.csv') %>% 
  clean_mdt0525() %>% 
  write_csv('cnig-cleaned-ids/MDT05.csv')

mdt25 <- read_csv('cnig-series-ids/MDT25.csv') %>% 
  clean_mdt0525() %>% 
  write_csv('cnig-cleaned-ids/MDT25.csv')

mdt200 <- read_csv('cnig-series-ids/MDT200.csv') %>% 
  clean_mdt200() %>% 
  write_csv('cnig-cleaned-ids/MDT200.csv')
