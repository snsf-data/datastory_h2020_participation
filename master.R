# This script produces all the files required to deploy an SNSF data story. 
# 
# Data story template: https://github.com/snsf-data/datastory_template
# 
# By running this file, the following components of a data story are generated
# and stored in the output directory: 
# 
# 1) a HTML file (self-contained), which contains all visualizations and 
#   images in encoded form, one for every specified language.
# 2) one file "metadata.json", which contains the metadata essential for 
#   the story (including all language versions in one file).
# 
# The files are stored in output/xxx, where xxx stands for the title of the
# data story in English, how it can also be used for the vanity URL to the 
# story, that means: no special characters, only lowercase.

# Unique name of this data story in English (all lowercase, underscore as 
# white-space, no special characters etc.)
datastory_name <- "h2020_participation"

# Language-specific names, do adapt! (used for vanity URL! Format: all 
# lowercase, minus as white-space (!) and no special characters, no special 
# characters etc.)
# Europäische Forschungsexzellenz in Zeiten der Nicht-Assoziierung
datastory_name_de <- "europaeische-forschungsexzellenz-in-zeiten-der-nicht-assoziierung"
datastory_name_en <- "european-research-excellence-in-times-of-non-association"
datastory_name_fr <- "excellence-de-la-recherche-europeenne-en-temps-de-non-association"

# English title and lead of the story (Mandatory, even if no EN version)
title_en <- "European research excellence in times of non-association" 
lead_en <- "Newly calculated figures illustrate the sharp decline in contributions from EU programmes to Swiss institutions between 2014 and 2017. They also attest to the relevance of Switzerland and the UK in terms of scientific excellence." 
# German title and lead of the story (Mandatory, even if no DE version)
title_de <- "Europäische Forschungsexzellenz in Zeiten der Nicht-Assoziierung" 
lead_de <- "Neue Zahlen unterstreichen den starken Rückgang von Beiträgen aus EU-Programmen an CH-Institutionen zwischen 2014 und 2017 und bestätigen die Bedeutung der Schweiz und Grossbritanniens für die Exzellenz der Forschung." 
# French title and lead of the story (Mandatory, even if no FR version)
title_fr <- "L'excellence de la recherche européenne en temps de non-association"
lead_fr <- "Les chiffres nouvellement calculés illustrent la forte baisse des contributions des programmes de l'UE aux institutions suisses entre 2014 et 2017. Ils témoignent également de la pertinence de la Suisse et du Royaume-Uni en termes d'excellence scientifique." 
# Contact persons, always (first name + last name)
contact_person <- c("João Martins")
# Mail address to be displayed as contact persons, put "datastories@snf.ch" for 
# every name of a contact person listed above.
contact_person_mail <- c("datastories@snf.ch")
# One of the following categories:  "standard", "briefing", "techreport", 
# "policybrief", "flagship", "figure". Category descriptions are 
datastory_category <- "standard"
# Date, after which the story should be published. Stories not displayed if the 
# date lies in the future. 
publication_date <- "2022-05-09 01:00:00"
# Available language versions in lowercase, possible: "en", "de", "fr".
languages <- c("en", "de", "fr") 
# Whether this story should be a "Feature Story" story
feature_story <- FALSE
# DOI of the story (optional)
doi <- "https://doi.org/10.46446/datastory.h2020-participation" 
# URL to Github page (optional)
github_url <- "https://github.com/snsf-data/datastory_h2020_participation" 
# Put Tag IDs here. Only choose already existing tags. 
tags_ids <- c(120, # H2020
              130, # ERC
              140) # EU

# IMPORTANT: Put a title image (as .jpg) into the output directory. 
# example: "output/datastory-template.jpg"

# Install pacman package if needed
if (!require("pacman")) {
  install.packages("pacman")
  library(pacman)
}

# Install snf.datastory package if not available, otherwise load it
if (!require("snf.datastory")) {
  if (!require("devtools")) {
    install.packages("devtools")
    library(devtools)
  }
  install_github("snsf-data/snf.datastory")
  library(snf.datastory)
}

# Load packages
p_load(tidyverse,
       scales, 
       conflicted, 
       jsonlite, 
       here)

# Conflict preferences
conflict_prefer("filter", "dplyr")

# Function to validate a mandatory parameter value
is_valid <- function(param_value) {
  if (is.null(param_value))
    return(FALSE)
  if (is.na(param_value))
    return(FALSE)
  if (str_trim(param_value) == "")
    return(FALSE)
  return(TRUE)
}

# Validate parameters and throw error message when not correctly filled
if (any(!is_valid(datastory_name), 
        !is_valid(title_en),
        !is_valid(title_de),
        !is_valid(title_fr), 
        !is_valid(datastory_category),
        !is_valid(publication_date), 
        length(languages) < 1,
        !is_valid(lead_en), 
        !is_valid(lead_de), 
        !is_valid(lead_fr)))
stop("Incorrect value for at least one of the mandatory metadata values.")

# Create output directory in main directory
if (!dir.exists(here("output")))
  dir.create(here("output"))

# Create story directory in output directory
if (!dir.exists(here("output", datastory_name)))
  dir.create(here("output", datastory_name))

# Create a JSON file with the metadata and save it in the output directory
tibble(
  title_en = title_en, 
  title_de = title_de, 
  title_fr = title_fr, 
  author = paste(contact_person, collapse = ";"), 
  datastory_category = datastory_category, 
  publication_date = publication_date, 
  languages = paste(languages, collapse = ";"),
  short_desc_en = lead_en, 
  short_desc_de = lead_de, 
  short_desc_fr = lead_fr, 
  tags = paste(paste0("T", tags_ids, "T"), collapse = ","), 
  author_url = paste(contact_person_mail, collapse = ";"), 
  top_story = feature_story, 
  github_url = github_url, 
  doi = doi
) %>%  
  toJSON() %>%  
  write_lines(here("output", datastory_name, "metadata.json"))

# Knit HTML output for each language version
for (idx in seq_len(length(languages))) {
  current_lang <- languages[idx]
  output_file <- here("output", datastory_name, 
                      paste0(str_replace_all(
                        get(paste0("datastory_name_", current_lang)), "_", "-"),
                        "-", current_lang, ".html"))
  print(paste0("Generating output for ", current_lang, " version..."))
  rmarkdown::render(
    input = here(paste0(current_lang, ".Rmd")),
    output_file = output_file, 
    params = list(
      title = get(paste0("title_", current_lang)),
      publication_date = publication_date,
      doi = doi
    ),
    envir = new.env()
  )
}