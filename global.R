## Author: Jorge Cornejo
## Date: May 09, 2024
## Last Update:
## Goal: Generate a dynamics report of the data Panama VMS Gaps
rm(list=ls())
library(dplyr)
library(ggplot2)
library(sf)
library(lubridate)
library(shinythemes)
library(ggthemes)
library(shinythemes)
library(kableExtra)

gaps <- load(file = "VMSGaps/data/montlyGaps.rds")

montlyGaps <- montlyGaps %>%
              mutate(month=month(timestamp, label = F))

lMonth <- unique(montlyGaps$month)




