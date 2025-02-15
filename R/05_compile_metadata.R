source("https://raw.githubusercontent.com/timriffe/covid_age/master/R/00_Functions.R")
setwd(wd_sched_detect())
here::i_am("covid_age.Rproj")
startup::startup()

# 1) which files have metadata tab.

library(googlesheets4)
library(tidyverse)

logfile <- here::here("buildlog.md")
log_section("Compile metadata", 
            append = TRUE, 
            logfile = logfile)
# if (interactive()){
#   osf_retrieve_file("8uk9n") %>%
#     osf_download(path = "Data",
#                conflicts = "overwrite") 
# }
# This reads it in
#inputDB <-  readRDS(here("Data","inputDB.rds"))

gs4_auth(email = Sys.getenv("email"))


rubric <- get_input_rubric()

rubric <- rubric %>% 
  dplyr::filter(!is.na(Sheet))

metadata_tabs <- list()
for (i in 1:nrow(rubric)){
   ss <- rubric %>% dplyr::pull(Sheet) %>% '['(i)
   
   # has metadata?
   tabs_i <- try(as_sheets_id(ss) %>% sheet_properties())
   if (class(tabs_i)[1] == "try-error"){
     cat(rubric$Country[i],"has problem\n")
     next
   }
   if ("metadata" %in% tabs_i$name){
     X <- try(read_sheet(ss, sheet = "metadata", col_types = "ccc"))
     
     if(class(X)[1] == "try-error"){
       Sys.sleep(120)
       X <- try(read_sheet(ss, sheet = "metadata", col_types = "ccc"))
     }
     metadata_tabs[[i]] <- X
     Sys.sleep(2)
   } else {
     metadata_tabs[[i]] <- NULL
   }
}

# some of these are simply empty metadata tabs by design 
# (sources parsed over multiple sheets only need one)
errors <- lapply(metadata_tabs, function(x){
  class(x)[1] == "try-error"
}) %>% unlist()

# rubric$Short[errors]
metadata_tabs <- metadata_tabs[!errors]

nulls <- lapply(metadata_tabs, is.null) %>% unlist()
metadata_tabs <- metadata_tabs[!nulls]
saveRDS(metadata_tabs,here::here("Data","metadata_tabs.rds"))

vars.dash <- c( "Country", 
                "Region(s)",
                "Author",
                "Main website",
                "Retrospective corrections",
                "Date of start of data series (data captured for this project)",
                "Date of end of data series",
                "CASES - Definition",
                "CASES - Coverage",
                "CASES - Date of events",
                "DEATHS - Definition",
                "DEATHS - Coverage",
                "DEATHS - Date of events"
)
# pick out Fields for basic source table
metadata_important <- 
  metadata_tabs %>% 
  lapply(function(X,vars.dash){
    #cnames <- c("Country","Region(s)","Author","Main website")
    X <- X %>% 
      dplyr::filter(Field %in%vars.dash) 
    out <- data.frame(t(X[, 2]),stringsAsFactors = FALSE)
    colnames(out) <- vars.dash
    out
  },vars.dash=vars.dash) %>% 
  bind_rows() 


# save Drive copy for manual inspection / corrections
write_sheet(metadata_important, ss = "https://docs.google.com/spreadsheets/d/1ik5RNGYP0uB9TIrV5vVF7ixYJ9y9P4N7oW9a-9Cqw6M/edit#gid=0", sheet = "metadata_important")

metadata_important <- 
  metadata_important %>% 
  arrange(Country, `Region(s)`) 

drm <- duplicated(metadata_important)
metadata_important <- 
  metadata_important %>% 
  filter(!drm)
# save local copy for dash building
saveRDS(metadata_important, file = here::here("Data","metadata_important.rds"))


# ----------------
# further stuff to design / implement. Lots of field gaps to fill still here.
do_this <- FALSE
if (do_this){
  vars.dash <- c( "Country", 
                  "Region(s)",
                  "Author",
                  "Main website",
                  "Retrospective corrections",
                  "Date of start of data series (data captured for this project)",
                  "Date of end of data series",
                  "CASES - Definition",
                  "CASES - Coverage",
                  "CASES - Date of events",
                  "DEATHS - Definition",
                  "DEATHS - Coverage",
                  "DEATHS - Date of events"
  )
metadata_table <- lapply(metadata_tabs, function(X, vars.dash){
  dash.vars <-
    X %>% 
    filter(Field %in% vars.dash) %>% 
    select(Answer)
  
  this.row <- as.matrix(dash.vars) %>% 
    t() %>% 
    as.data.frame(stringsAsFactors = FALSE)
  colnames(this.row) <- vars.dash
  this.row
},vars.dash=vars.dash) %>% 
  bind_rows() %>% 
  arrange(Country, `Region(s)`)

tab1 <- metadata_table %>% 
  select(Country, 
         `Region(s)`,
         Author, 
         `Main website`,
         Corrected = `Retrospective corrections`,
         `Series start` = `Date of start of data series (data captured for this project)`,
         `Series end` = `Date of end of data series`)


# TODO:
# add new field, Metrics that contains the unique metrics captured for cases and for deaths.
# for CA_BC ASCFR go to DEATHS, but for ITinfo ASCFR (Ratios) go to Cases.

# TODO:
# for Fraction and Ratio metrics, is the collected data rounded or not?

tab2 <- metadata_table %>% 
  select(Country, 
         `Region(s)`,
         Definition = `CASES - Definition`,
         Coverage = `CASES - Coverage`,
         `Date of events` = `CASES - Date of events`)

tab3 <- metadata_table %>% 
  select(Country, 
         `Region(s)`,
         Definition = `DEATHS - Definition`,
         Coverage = `DEATHS - Coverage`,
         `Date of events` = `DEATHS - Date of events`)


saveRDS(metadata_tabs,file = here::here("Data","metadata_tabs.rds"))
saveRDS(metadata_table,file = here::here("Data","metadata_table.rds"))
saveRDS(tab1,file = here::here("Data","tab1.rds"))
saveRDS(tab2,file = here::here("Data","tab2.rds"))
saveRDS(tab3,file = here::here("Data","tab3.rds"))


}






# Note:

# Shiny App:

# select countries and metadata variables.





# sheet_tabs <- list()
# for (i in 1:nrow(rubric)){
#   ss <- rubric %>% dplyr::pull(Sheet) %>% '['(i)
#   sheet_tabs[[i]] <- gs4_get(ss)
# }
# 
# get_sheet_names <- function(sheets_metadata){
#   sheets_metadata %>% '[['("sheets") %>% pull(name)
# }
# 
# 
# has_source_metadata <- function(sheets_metadata){
#   tabs<- sheets_metadata %>% '[['("sheets") %>% pull(name)
#   "metadata" %in% tabs
# }
# 
# names(sheet_tabs) <- rubric$Short
# metas <- lapply(sheet_tabs, get_sheet_names) %>% 
#   lapply(grepl,pattern="meta") %>% 
#   lapply(any) %>% unlist()
# metas[!metas]
# 
# 
# metadata_sheets <- lapply(sheet_tabs, has_source_metadata) %>% unlist()
# metadata_sheets[metadata_sheets]


# template_ss <- "https://docs.google.com/spreadsheets/d/15HktFkvdmxZ36nHzAfFqAa63rPWnbyP2BFjVsMNBVZs/edit#gid=889172199"

# create_meta <- metas[!metas]
# for (i in 1:length(create_meta)){
#   # get destination ss
#   ss <- rubric %>% 
#     filter(Short == names(create_meta)[i]) %>%  
#     pull(Sheet) 
#   
#   # any sheet named metadata?
#   has_meta <- 
#     gs4_get(ss) %>% 
#     '[['("sheets") %>% 
#     pull(name) %>% 
#     '=='("metadata") %>% 
#     any()
#   
#   if (!has_meta){
#     sheet_copy(from_ss = template_ss,
#                from_sheet = "metadata",
#                to_ss = ss,
#                to_sheet = "metadata")
#   }
# }
# 
# 
# for (i in 1:nrow(rubric)){
#   ss <- rubric %>% pull(Sheet) %>% '['(i)
#   
#   sheet_copy(from_ss = ss,
#              from_sheet = "metadata",
#              to_ss = ss,
#              to_sheet = "metadata_old")
# }
# 


# ss_v2 <- "https://docs.google.com/spreadsheets/d/15HktFkvdmxZ36nHzAfFqAa63rPWnbyP2BFjVsMNBVZs/edit#gid=575566620"
# 
# for (i in 1:nrow(rubric)){
#   ss <- rubric %>% pull(Sheet) %>% '['(i)
#   sheet_delete(ss, sheet = "metadata")
#   sheet_copy(from_ss = ss_v2,
#              from_sheet = "metadata",
#              to_ss = ss,
#              to_sheet = "metadata")
# }






# new_template_ss <- "https://docs.google.com/spreadsheets/d/1G9Fo2by_r7jLWfpge7XEAxKN7v9ckexZZOHLl52hbVQ/edit#gid=1301732609"
# 
# template <- read_sheet(new_template_ss, sheet = "metadata")
# write_sheet(template, new_template_ss, sheet = "attempt2")
# 
# metadata_tabs <- list()
# for (i in 1:nrow(rubric)){
#   ss <- rubric %>% pull(Sheet) %>% '['(i)
#   metadata_tabs[[i]] <- read_sheet(ss, sheet = "metadata_old")
#   metadata_tabs[[i]]$Answer <- lapply(metadata_tabs[[i]]$Answer,
#                                       function(x){
#                                         if(is.null(x)){return(NA)} else {return(x)}
#                                       })
#   metadata_tabs[[i]]$Answer <- unlist( metadata_tabs[[i]]$Answer)
#   basic   <- metadata_tabs[[i]]$Answer[1:3] 
#   default <- unlist(rubric[i,c("Short","Country","Region")])
#   impute  <- ifelse(is.na(basic),default,basic)
#   metadata_tabs[[i]]$Answer[1:3] <- impute
#   r16     <- data.frame(Answer=metadata_tabs[[i]]$Answer[1:15])
#   range_write(ss,
#               data = r16,
#               sheet = "metadata",
#               range = "B1:B16",
#               reformat = FALSE)
#   Sys.sleep(10)
#   
# }
# names(metadata_tabs) <- rubric$Short
# lapply(metadata_tabs,colnames)

############################
# Write loop that copies the first 16 Answer values from 
# metadata_old to metadata.
# also the last two values.






