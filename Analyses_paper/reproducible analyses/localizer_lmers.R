#This takes the individual-subject contrast values and runs some nifty lmer models.  First #many
#lines are reading in the contrasts as in localizer_t_tests, fun stuff starts on line 105

rm(list=ls(all=TRUE))
library(tidyr)
library(dplyr)
library(lme4)

#Set wd!
setwd("~/Dropbox/_Projects/Jokes - fMRI/Jokes-Analysis Repository/Analyses_paper/contrasts")

#######
# Read in all contrast values
#######

# Add in the contrast and ROI names so it's not just numbers!!!!!

RHLangROI.Names = c('RPostTemp', 'RAntTemp', 'RAngG', 'RIFG',      'RMFG',     'RIFGorb');
LangROI.Names = c('LPostTemp', 'LAntTemp', 'LAngG', 'LIFG',      'LMFG',     'LIFGorb');

MDROI.Names = c('LIFGop',  'RIFGop', 'LMFG',    'RMFG',    'LMFGorb',
                'RMFGorb', 'LPrecG', 'RPrecG',  'LInsula', 'RInsula',
                'LSMA',    'RSMA',   'LParInf', 'RParInf', 'LParSup',
                'RParSup', 'LACC',   'RACC');

ToMROI.Names = c('DMPFC', 'LTPJ',  'MMPFC', 'PC',
                 'RTPJ',  'VMPFC', 'RSTS');


lang.contrasts = c('sent','non','sent-non')
md.contrasts = c()
tom.contrasts = c('bel','pho','bel-pho')

normal.contrasts = c('joke', 'lit', 'joke-lit')
custom.contrasts = c('low','med','high','other')


###RESP LOCALIZER
myResults = read.csv('RHLangfROIsrespLangLoc.csv')%>%
  mutate(ROIName = RHLangROI.Names[ROI]) %>%
  mutate(contrastName = lang.contrasts[Contrast])%>%
  mutate(Group = 'RHLang-toLang')
allSigChange = myResults

myResults = read.csv('LangfROIsrespLangLoc.csv')%>%
  mutate(ROIName = LangROI.Names[ROI]) %>%
  mutate(contrastName = lang.contrasts[Contrast])%>%
  mutate(Group = 'LHLang-toLang')
allSigChange = rbind(allSigChange, myResults)

##TO ADD: MD to Lang localizer measure (Non should > Sent)
# myResults = read.csv('MDfROIsrespLang.csv')%>%
#   mutate(ROIName = MDROI.Names[ROI]) %>%
#   mutate(contrastName = lang.contrasts[Contrast])%>%
#   mutate(Group = 'MDall-toLang')
# allSigChange = rbind(allSigChange, myResults)
#Little extra thing here, rename MD to split by L and R hemisphere!
#allSigChange[(allSigChange$Group == 'MDall-toLang') & (allSigChange$ROI %%2 == 1),]$Group = 'MDLeft-toLang'
#allSigChange[(allSigChange$Group == 'MDall-toLang') & (allSigChange$ROI %%2 == 0),]$Group = 'MDRight-toLang'


myResults = read.csv('NewToMfROIsrespToMLoc.csv')%>%
  mutate(ROIName = ToMROI.Names[ROI]) %>%
  mutate(contrastName = tom.contrasts[Contrast])%>%
  mutate(Group = 'ToM-toToM')
allSigChange = rbind(allSigChange, myResults)

###RESP JOKES

myResults = read.csv('RHLangfROIsrespNonlitJokes.csv')%>%
  mutate(ROIName = RHLangROI.Names[ROI]) %>%
  mutate(contrastName = normal.contrasts[Contrast])%>%
  mutate(Group = 'RHLang')
allSigChange = rbind(allSigChange, myResults)

myResults = read.csv('LangfROIsrespNonlitJokes.csv') %>%
  mutate(ROIName = LangROI.Names[ROI]) %>%
  mutate(contrastName = normal.contrasts[Contrast])%>%
  mutate(Group = 'LHLang')
allSigChange = rbind(allSigChange, myResults)

myResults = read.csv('MDfROIsrespNonlitJokes.csv') %>%
  mutate(ROIName = MDROI.Names[ROI]) %>%
  mutate(contrastName = normal.contrasts[Contrast]) %>%
  mutate(Group = 'MDAll')
allSigChange = rbind(allSigChange, myResults)

#Little extra thing here, rename MD to split by L and R hemisphere!
allSigChange[(allSigChange$Group == 'MDAll') & (allSigChange$ROI %%2 == 1),]$Group = 'MDLeft'
allSigChange[(allSigChange$Group == 'MDAll') & (allSigChange$ROI %%2 == 0),]$Group = 'MDRight'

myResults = read.csv('NewToMfROIsrespNonlitJokes.csv')%>%
  mutate(ROIName = ToMROI.Names[ROI]) %>%
  mutate(contrastName = normal.contrasts[Contrast]) %>%
  mutate(Group = 'ToM')
allSigChange = rbind(allSigChange, myResults)

###RESP JOKES-CUSTOM

myResults = read.csv('NewToMfROIsresCustomJokes.csv')%>%
  mutate(ROIName = ToMROI.Names[ROI]) %>%
  mutate(contrastName = custom.contrasts[Contrast])%>%
  mutate(Group = 'ToMCustom')
allSigChange = rbind(allSigChange, myResults)

#########

# Linear mixed Models!
#Plan: Within each system (localizers, and jokes), test for condition differences, then do some
#between-system comparisons


RHLangtoLang <- filter(allSigChange, Group == "RHLang-toLang", contrastName == 'sent' | contrastName == 'non')
m1 <- lmer(sigChange ~ contrastName + (contrastName|ROIName) + (contrastName|SubjectNumber), data = RHLangtoLang)
m0 <- lmer(sigChange ~ 1 + (contrastName|ROIName) + (contrastName|SubjectNumber), data = RHLangtoLang)
anova(m1,m0)

LHLangtoLang <- filter(allSigChange, Group == "LHLang-toLang", contrastName == 'sent' | contrastName == 'non')
m1 <- lmer(sigChange ~ contrastName + (contrastName|ROIName) + (contrastName|SubjectNumber), data = LHLangtoLang)
m0 <- lmer(sigChange ~ 1 + (contrastName|ROIName) + (contrastName|SubjectNumber), data = LHLangtoLang)
anova(m1,m0)


##TO ADD: RMD and LMD to Lang Localizer check (sent < non)

ToMtoToM <- filter(allSigChange, Group == "ToM-toToM", contrastName == 'bel' | contrastName == 'pho')
m1 <- lmer(sigChange ~ contrastName + (contrastName|ROIName) + (contrastName|SubjectNumber), data = ToMtoToM)
m0 <- lmer(sigChange ~ 1 + (contrastName|ROIName) + (contrastName|SubjectNumber), data = ToMtoToM)
anova(m1,m0)

#To jokes!

RHLang <- filter(allSigChange, Group == "RHLang", contrastName == 'joke' | contrastName == 'lit')
m1 <- lmer(sigChange ~ contrastName + (contrastName|ROIName) + (contrastName|SubjectNumber), data = RHLang)
m0 <- lmer(sigChange ~ 1 + (contrastName|ROIName) + (contrastName|SubjectNumber), data = RHLang)
anova(m1,m0)

LHLang <- filter(allSigChange, Group == "LHLang", contrastName == 'joke' | contrastName == 'lit')
m1 <- lmer(sigChange ~ contrastName + (contrastName|ROIName) + (contrastName|SubjectNumber), data = LHLang)
m0 <- lmer(sigChange ~ 1 + (contrastName|ROIName) + (contrastName|SubjectNumber), data = LHLang)
anova(m1,m0)

MDRight <- filter(allSigChange, Group == "MDRight", contrastName == 'joke' | contrastName == 'lit')
m1 <- lmer(sigChange ~ contrastName + (contrastName|ROIName) + (contrastName|SubjectNumber), data = MDRight)
m0 <- lmer(sigChange ~ 1 + (contrastName|ROIName) + (contrastName|SubjectNumber), data = MDRight)
anova(m1,m0)

MDLeft <- filter(allSigChange, Group == "MDLeft", contrastName == 'joke' | contrastName == 'lit')
m1 <- lmer(sigChange ~ contrastName + (contrastName|ROIName) + (contrastName|SubjectNumber), data = MDLeft)
m0 <- lmer(sigChange ~ 1 + (contrastName|ROIName) + (contrastName|SubjectNumber), data = MDLeft)
anova(m1,m0)

ToM <- filter(allSigChange, Group == "ToM", contrastName == 'joke' | contrastName == 'lit')
m1 <- lmer(sigChange ~ contrastName + (contrastName|ROIName) + (contrastName|SubjectNumber), data = ToM)
m0 <- lmer(sigChange ~ 1 + (contrastName|ROIName) + (contrastName|SubjectNumber), data = ToM)
anova(m1,m0)

######
#Then, do some comparisons between systems: ToM > MDRight and ToM RHLang, plus LHs for completeness

ToM_MDRight <- filter(allSigChange, Group == "ToM" | Group == "MDRight", contrastName == 'joke' | contrastName == 'lit')
m1 <- lmer(sigChange ~ contrastName*Group + (contrastName|ROIName) + (contrastName*Group|SubjectNumber), data = ToM_MDRight)
m0 <- lmer(sigChange ~ contrastName+Group + (contrastName|ROIName) + (contrastName*Group|SubjectNumber), data = ToM_MDRight)
anova(m1,m0)

#hypothesis: large between-system differences eat most of the variance.  Use joke-lit contrast value instead
ToM_MDRight_cont <- filter(allSigChange, Group == "ToM" | Group == "MDRight", contrastName == 'joke-lit')
m1 <- lmer(sigChange ~ Group + (1|ROIName) + (Group|SubjectNumber), data = ToM_MDRight_cont)
m0 <- lmer(sigChange ~ 1 + (1|ROIName) + (Group|SubjectNumber), data = ToM_MDRight_cont)
anova(m1,m0)

ToM_RHLang_cont <- filter(allSigChange, Group == "ToM" | Group == "RHLang", contrastName == 'joke-lit')
m1 <- lmer(sigChange ~ Group + (1|ROIName) + (Group|SubjectNumber), data = ToM_RHLang_cont)
m0 <- lmer(sigChange ~ 1 + (1|ROIName) + (Group|SubjectNumber), data = ToM_RHLang_cont)
anova(m1,m0)

ToM_MDLeft_cont <- filter(allSigChange, Group == "ToM" | Group == "MDLeft", contrastName == 'joke-lit')
m1 <- lmer(sigChange ~ Group + (1|ROIName) + (Group|SubjectNumber), data = ToM_MDLeft_cont)
m0 <- lmer(sigChange ~ 1 + (1|ROIName) + (Group|SubjectNumber), data = ToM_MDLeft_cont)
anova(m1,m0)

ToM_LHLang_cont <- filter(allSigChange, Group == "ToM" | Group == "LHLang", contrastName == 'joke-lit')
m1 <- lmer(sigChange ~ Group + (1|ROIName) + (Group|SubjectNumber), data = ToM_LHLang_cont)
m0 <- lmer(sigChange ~ 1 + (1|ROIName) + (Group|SubjectNumber), data = ToM_LHLang_cont)
anova(m1,m0)




#####
#Finally, remodel ToM activations with funniness ratings
ToMCustom <- filter(allSigChange, Group == "ToMCustom", contrastName == 'low' | contrastName == 'med' | contrastName == 'high')
#Make sure those factors are ordered....
ToMCustom$contrastName <- as.factor(ToMCustom$contrastName)
m1 <- lmer(sigChange ~ contrastName + (contrastName|ROIName) + (contrastName|SubjectNumber), data = ToMCustom)
m0 <- lmer(sigChange ~ 1 + (contrastName|ROIName) + (contrastName|SubjectNumber), data = ToMCustom)
anova(m1,m0)
