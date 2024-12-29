library(tidyverse)

# clean data --------------------------------------------------------------

# most files look like this
clean_delimited <- function(file) {
  df <- read_csv(file, col_names = c('filename', 'filetype', 'size', 'date')) %>%
    mutate(
      name = str_extract(filename, '\\d{4}(-\\d(-\\d)?)?'),
      datum = str_trim(str_split(filename, '-') %>%
        map_chr(., 2)),
      utm_zone = case_when(
          str_detect(filename, 'HU\\d{2}') ~ str_extract(filename, '(?<=HU)\\d{2}'),
          str_detect(filename, 'H\\d{2}') ~ str_extract(filename, '(?<=H)\\d{2}'),
          TRUE ~ ""
        ) %>% 
        as.numeric(.),
      date = str_replace(date, ",$", "")
    ) %>% 
    select(filename, name, datum, utm_zone, date, size)

  return(df)
}

# but this file is by provinces
clean_mdt200_cob1 <- function(file) {
  df <- read_csv(file,
                 col_names = c('filename', 'filetype', 'size', 'date'),
                 # make sure encoding works ok
                 locale = locale(encoding = 'WINDOWS-1252')) %>% 
    mutate(
      name = str_split(filename, '-') %>%
        map_chr(., 1) %>%
        str_trim(.),
      name = case_when(
          name == 'Álava' ~ 'Araba/Álava',
          name == 'Alicante/Alacant' ~ 'Alacant/Alicante',
          name == "Balears, Illes" ~ "Illes Balears",
          name == 'Castellón' ~ 'Castelló/Castellón',
          name == 'Guipúzcoa' ~ 'Gipuzkoa',
          name == 'Valencia' ~ 'València/Valencia',
          name == 'Vizcaya' ~ 'Bizkaia',
          TRUE ~ name
        ),
      datum = case_when(
        name == 'Santa Cruz de Tenerife' ~ 'REGCAN95',
        name == 'Las Palmas' ~ 'REGCAN95',
        TRUE ~ "ETRS89"
      ),
      utm_zone = str_extract(filename, '(?<=Huso )\\d+') %>%
        as.numeric(.),
      date = str_replace_all(date, ' - ', ', ') %>%
        str_replace(., ",$", "")
    ) %>% 
    select(filename, name, datum, utm_zone, date, size)

  return(df)
}

# Run ---------------------------------------------------------------------
mdt02 <- clean_delimited('data/input-data/MDT02.csv') %>% 
  write_csv('data/output-data/MDT02.csv')

mdt05 <- clean_delimited('data/input-data/MDT05.csv') %>% 
  write_csv('data/output-data/MDT05.csv')

mdt25_cob1 <- clean_delimited('data/input-data/MDT25_COB1.csv') %>% 
  write_csv('data/output-data/MDT25_COB1.csv')

mdt25_cob2 <- clean_delimited('data/input-data/MDT25_COB2.csv') %>% 
  write_csv('data/output-data/MDT25_COB2.csv')

mdt200_cob1 <- clean_mdt200_cob1('data/input-data/MDT200_COB1.csv') %>% 
  write_csv('data/output-data/MDT200_COB1.csv')

mdt200_cob2 <- clean_delimited('data/input-data/MDT200_COB2.csv') %>% 
  write_csv('data/output-data/MDT200_COB2.csv')
