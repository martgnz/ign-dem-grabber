library(tidyverse)

# clean data --------------------------------------------------------------

# most files look like this
clean_delimited <- function(file) {
  df <- read_csv(file) %>%
    mutate(
      id = str_extract(filename, '\\d{4}(-\\d(-\\d)?)?'),
      # find either ETRS89, REGCAN95 or WGS84
      # flaky if another datum is used but filenames are VERY inconsistent
      datum = case_when(
        str_detect(filename, 'ETRS89') ~ 'ETRS89',
        str_detect(filename, 'REGCAN95') ~ 'REGCAN95',
        str_detect(filename, 'WGS84') ~ 'WGS84',
        TRUE ~ ""
      ),
      utm_zone = case_when(
          str_detect(filename, 'HU\\d{2}') ~ str_extract(filename, '(?<=HU)\\d{2}'),
          str_detect(filename, 'H\\d{2}') ~ str_extract(filename, '(?<=H)\\d{2}'),
          TRUE ~ ""
        ) %>% 
        as.numeric(.),
      date = str_replace(date, ",$", "")
    ) %>% 
    select(id, download_id, series, datum, utm_zone, date, size)

  return(df)
}

# but this file is by provinces
clean_mdt200_cob1 <- function(file) {
  df <- read_csv(file) %>% 
    mutate(
      id = str_split(filename, '-') %>%
        map_chr(., 1) %>%
        str_trim(.),
      id = case_when(
        id == 'Álava' ~ 'Araba/Álava',
        id == 'Alicante/Alacant' ~ 'Alacant/Alicante',
        id == "Balears, Illes" ~ "Illes Balears",
        id == 'Castellón' ~ 'Castelló/Castellón',
        id == 'Guipúzcoa' ~ 'Gipuzkoa',
        id == 'Valencia' ~ 'València/Valencia',
        id == 'Vizcaya' ~ 'Bizkaia',
        TRUE ~ id
      ),
      datum = case_when(
        id == 'Santa Cruz de Tenerife' ~ 'REGCAN95',
        id == 'Las Palmas' ~ 'REGCAN95',
        TRUE ~ "ETRS89"
      ),
      utm_zone = str_extract(filename, '(?<=Huso )\\d+') %>%
        as.numeric(.),
      date = str_replace_all(date, ' - ', ', ') %>%
        str_replace(., ",$", "")
    ) %>% 
    select(id, download_id, series, datum, utm_zone, date, size)

  return(df)
}

# Run ---------------------------------------------------------------------
mdt02 <- clean_delimited('data/input-data/MDT02_COB2.csv') %>% 
  write_csv('data/output-data/MDT02_COB2.csv')

mdt05 <- clean_delimited('data/input-data/MDT05_COB1.csv') %>% 
  write_csv('data/output-data/MDT05_COB1.csv')

mdt25_cob1 <- clean_delimited('data/input-data/MDT25_COB1.csv') %>% 
  write_csv('data/output-data/MDT25_COB1.csv')

mdt25_cob2 <- clean_delimited('data/input-data/MDT25_COB2.csv') %>% 
  write_csv('data/output-data/MDT25_COB2.csv')

mdt200_cob1 <- clean_mdt200_cob1('data/input-data/MDT200_COB1.csv') %>% 
  write_csv('data/output-data/MDT200_COB1.csv')

mdt200_cob2 <- clean_delimited('data/input-data/MDT200_COB2.csv') %>% 
  write_csv('data/output-data/MDT200_COB2.csv')
