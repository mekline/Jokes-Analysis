library("xlsx")
library("lme4")

##setwd("~/Documents/MIT/UROP-Ev/data_jokes/") ##CHANGE

langLH <- read.xlsx("summary.xlsx", sheetName = "langLH")
langRH <- read.xlsx("summary.xlsx", sheetName = "langRH")
MDLH <- read.xlsx("summary.xlsx", sheetName = "MDLH")
MDRH <- read.xlsx("summary.xlsx", sheetName = "MDRH")


langLH.lmer <- lmer(value~condition*region +(1|subject), data = langLH)
langLH.lmer
langRH.lmer <- lmer(value~condition*region +(1|subject), data = langRH)
langRH.lmer
MDLH.lmer <- lmer(value~condition*region +(1|subject), data = MDLH)
MDLH.lmer
MDRH.lmer <- lmer(value~condition*region +(1|subject), data = MDRH)
MDRH.lmer