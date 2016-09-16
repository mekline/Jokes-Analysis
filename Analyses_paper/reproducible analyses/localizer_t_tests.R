#This rebuilds the t tests that spmss spits out from the individual signal change values (reproduced here
#so mk can track how those are done/feed into other analyses)

rm(list=ls(all=TRUE))
library(tidyr)
library(dplyr)

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

View(allSigChange)


#######
# Calculate T Tests
#######

allTests <- allSigChange %>%
  group_by(Group)%>%
  summarize(familySize = length(unique(ROI))) %>%
  merge(allSigChange) %>%
  group_by(Group, ROI, Contrast, ROIName, contrastName, familySize) %>%
  summarise(t = t.test(sigChange, mu=0,alt='greater')$statistic, 
            p = t.test(sigChange, mu=0,alt='greater')$p.value) %>%
  ungroup()%>%
  group_by(Group, Contrast)%>%
  mutate(p.adj = p.adjust(p, method="fdr", n=familySize[1]))


View(allTests)
setwd("~/Dropbox/_Projects/Jokes - fMRI/Jokes-Analysis Repository/Analyses_paper/reproducible analyses")
zz = file('localizer_t_tests_all.csv', 'w')
write.csv(allTests, zz, row.names=FALSE)
close(zz)


