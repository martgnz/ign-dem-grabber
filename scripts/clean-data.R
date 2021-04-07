library(tidyverse)

setwd('~/Projects/cnig-dem-grabber/scripts/')

clean_mdt25 <- function(df) {
  df %>% 
    mutate(
      datum = str_split(filename, '_') %>% map_chr(., 3),
      utm_zone = str_split(filename, '_') %>% map_chr(., 4) %>% substr(., 3, 4),
      # catch everything after "HU"
      # https://stackoverflow.com/a/39592270
      name = str_extract(filename, '(?<=HU).*') %>%
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
    select(id, name, datum, utm_zone)
}

mdt200 <- read_csv('cnig-series-ids/MDT200.csv') %>% 
  clean_mdt200() %>% 
  write_csv('cnig-cleaned-ids/MDT200.csv')

mdt25 <- read_csv('cnig-series-ids/MDT25.csv') %>% 
  clean_mdt25() %>% 
  write_csv('cnig-cleaned-ids/MDT25.csv')
