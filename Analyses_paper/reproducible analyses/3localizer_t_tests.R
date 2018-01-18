#This rebuilds the t tests that spmss spits out from the individual signal change values (reproduced here from ind. 
#signal change values so mk can track how those are done/feed into other analyses)

rm(list=ls(all=TRUE))
library(tidyr)
library(dplyr)
library(pwr)

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
revlang.contrasts = c('sent','non','non-sent')
md.contrasts = c('hard','easy','hard-easy')
tom.contrasts = c('bel','pho','bel-pho')

normal.contrasts = c('joke', 'lit', 'joke-lit')
custom.contrasts = c('low','med','high','other','paramfun')


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

#REMOVED old/wrong MD validator (MDfROIsrespRevLangLoc): we want Hard>Easy measured in regions localized
# by N>S (since most subj have only 1 MD run), *not the reverse*!
##TO ADD: MD to Lang localizer measure (Non should > Sent)
myResults = read.csv('RevLangfROIsrespMD_20171220.csv')%>%
   mutate(ROIName = MDROI.Names[ROI]) %>%
   mutate(contrastName = revlang.contrasts[Contrast])%>%
   mutate(Group = 'RevLang-toMD') %>%
  select(c("ROI", "ROI.size","average.localizer.mask.size",
           "inter.subject.overlap","sigChange","SubjectNumber",
           "Contrast", "ROIName", "contrastName","Group"))
 allSigChange = rbind(allSigChange, myResults)
#Little extra thing here, rename MD to split by L and R hemisphere!
allSigChange[(allSigChange$Group == 'RevLang-toMD') & (allSigChange$ROI %%2 == 1),]$Group = 'RevLangLeft-toMD'
allSigChange[(allSigChange$Group == 'RevLang-toMD') & (allSigChange$ROI %%2 == 0),]$Group = 'RevLangRight-toMD'


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


###RESP JOKES-CUSTOM with paramfun #10/07 new thing for supp. materials

myResults = read.csv('NewToMfROIsrespNonlitJokesCustom_20161007.csv')%>%
  mutate(ROIName = ToMROI.Names[ROI]) %>%
  mutate(contrastName = custom.contrasts[Contrast])%>%
  mutate(Group = 'ToMCustom')
allSigChange = rbind(allSigChange, myResults)

#View(allSigChange)

#New 10/12: Localizer analysis shows that VMPFC localizer doesn't come out in this dataset, so remove it from
#the joke-lit tests for ToM and ToM custom (but leave it for the localizer itself)

allSigChange = allSigChange %>%
  filter(!(Group == 'ToM' & ROIName =='VMPFC')) %>%
  filter(!(Group == 'ToMCustom' & ROIName =='VMPFC'))


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
  mutate(p.adj = p.adjust(p, method="fdr", n=familySize[1]))%>%
  ungroup()

#View(allTests)
setwd("~/Dropbox/_Projects/Jokes - fMRI/Jokes-Analysis Repository/Analyses_paper/reproducible analyses")
zz = file('localizer_t_tests_all.csv', 'w')
write.csv(allTests, zz, row.names=FALSE)
close(zz)

#And save out allSigChange to be ported over to the main/E2 analyses
yy = file('AllSigChange_Exp1.csv', 'w')
write.csv(allSigChange, yy, row.names=FALSE)
close(yy)

########
# Report those T tests like we want for the paper
########

#Do corrections ever matter?
allTests <- allTests %>%
  mutate(sig = p < 0.05) %>%
  mutate(sigCor = p.adj < 0.05) %>%
  mutate(mismatch = sig != sigCor)

View(filter(allTests,mismatch))

#Convention: when all tests go one way, report them together as follows:
reportTests <- function(ts, ps){
  if (all(ps > 0.05)){
    paste('all insig, ts <', max(ts), 'ps>', min(ps))
  } else if (all(ps < 0.05)){
    paste('all sig, ts >', min(ts), 'ps<', max(ps))
  } else {
    'explore...'
  }
}

###
#RESP LOCALIZER
allTests %>%
  filter(Group == 'LHLang-toLang', contrastName == 'sent-non') %>%
  summarise(n(), sum(sig), reportTests(t,p)) #Convention: when all significant, report the largest p

#allTests %>%
#  filter(Group == 'RHLang-toLang', contrastName == 'sent-non') %>%
#  summarise(n(), sum(sig), reportTests(t,p)) #found a surprise nonsig!
allTests %>%
  filter(Group == 'RHLang-toLang', contrastName == 'sent-non', sig) %>%
  summarise(n(), sum(sig), reportTests(t,p)) 
filter(allTests, Group == 'RHLang-toLang', contrastName == 'sent-non', !sig)

###MD localizer check
allTests %>%
  filter(Group == 'RevLangRight-toMD', contrastName == 'non-sent', sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))  #All sig!

allTests %>%
  filter(Group == 'RevLangLeft-toMD', contrastName == 'non-sent', sig) %>%
  summarise(n(), sum(sig), reportTests(t,p)) #All sig!

###ToM localizer check
allTests %>%
  filter(Group == 'ToM-toToM', contrastName == 'bel-pho', sig) %>%
  summarise(n(), sum(sig), reportTests(t,p)) 
filter(allTests, Group == 'ToM-toToM', contrastName == 'bel-pho', !sig)


###
#RESP JOKES

### RHLang
#Jokes and Nonjokes both activate, but no differences.

allTests %>%
  filter(Group == 'RHLang', contrastName == 'joke', sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'RHLang', contrastName == 'joke', !sig)

allTests %>%
  filter(Group == 'RHLang', contrastName == 'lit', sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'RHLang', contrastName == 'lit', !sig)

allTests %>%
  filter(Group == 'RHLang', contrastName == 'joke-lit') %>%
  summarise(n(), sum(sig), reportTests(t,p)) 


### LHLang
#Jokes and Nonjokes both activate, but no differences.

allTests %>%
  filter(Group == 'LHLang', contrastName == 'joke') %>%
  summarise(n(), sum(sig), reportTests(t,p))

allTests %>%
  filter(Group == 'LHLang', contrastName == 'lit') %>%
  summarise(n(), sum(sig), reportTests(t,p))

allTests %>%
  filter(Group == 'LHLang', contrastName == 'joke-lit', !sig) %>%
  summarise(n(), sum(sig), reportTests(t,p)) #ONLY ONE of the ROIs significant
filter(allTests, Group == 'LHLang', contrastName == 'joke-lit', sig)


### RHMD
# RH is pretty boring

allTests %>%
  filter(Group == 'MDRight', contrastName == 'joke', sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'MDRight', contrastName == 'joke', !sig)

allTests %>%
  filter(Group == 'MDRight', contrastName == 'lit',sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'MDRight', contrastName == 'lit', !sig)

allTests %>%
  filter(Group == 'MDRight', contrastName == 'joke-lit', !sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'MDRight', contrastName == 'joke-lit', sig)


###LHMD
# LH has some joke-lit differences

allTests %>%
  filter(Group == 'MDLeft', contrastName == 'joke', sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'MDLeft', contrastName == 'joke', !sig)

allTests %>%
  filter(Group == 'MDLeft', contrastName == 'lit',sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'MDLeft', contrastName == 'lit', !sig)

allTests %>%
  filter(Group == 'MDLeft', contrastName == 'joke-lit', !sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'MDLeft', contrastName == 'joke-lit', sig)



### ToM
# Interesting activations!
allTests %>%
  filter(Group == 'ToM', contrastName == 'joke',!sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'ToM', contrastName == 'joke', sig)

allTests %>%
  filter(Group == 'ToM', contrastName == 'lit', !sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'ToM', contrastName == 'lit', sig)

allTests %>%
  filter(Group == 'ToM', contrastName == 'joke-lit', !sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'ToM', contrastName == 'joke-lit', sig)

#10/14 Huh, where did the ToM paramfun test go? Here it is again...
allTests %>%
  filter(Group == 'ToMCustom', contrastName == 'paramfun',!sig) %>%
  summarise(n(), sum(sig), reportTests(t,p))
filter(allTests, Group == 'ToM', contrastName == 'joke-lit', sig)


###############Here be exploratory analyses######

#Let's try and do a power analysis on the Jokes results. (Considering a replication
#since a journal has asked for one) There are 4 regions we expect to 
#find differences in: RTPJ, LTPJ, MMPFC, PC.  How big are those differences and how
#well powered are we?

cohens_d <- function(x, y) {
  lx <- length(x)- 1
  ly <- length(y)- 1
  md  <- abs(mean(x) - mean(y))        ## mean difference (numerator)
  csd <- lx * var(x) + ly * var(y)
  csd <- csd/(lx + ly)
  csd <- sqrt(csd)                     ## common sd computation
  
  cd  <- md/csd                        ## cohen's d
}

forPower <- allSigChange %>%
  filter(Group == 'ToM', contrastName == 'joke-lit') %>%
  filter(ROIName %in% c('RTPJ','LTPJ','PC','MMPFC') ) %>%
  group_by(ROIName)%>%
  summarise(m = mean(sigChange), sd = sd(sigChange), t = t.test(sigChange, mu=0,alt='greater')$statistic, 
            p = t.test(sigChange, mu=0,alt='greater')$p.value)

forPower$n <- 12
forPower$cohens_d <- forPower$m / forPower$sd

ptests <- mapply(pwr.t.test, n=forPower$n, d=forPower$cohens_d, sig.level=0.05, alternative='greater')

#These effects are powered okay: range 0.587 - 0.856

#Assume the smallest effect in ToM regions is the true effect size
effect_est <- min(forPower$cohens_d)

#How many participants do we need for 80% power at p=0.05?
pwr.t.test(d=effect_est, sig.level=0.05, power = 0.80, alternative='greater')

#21 participants!