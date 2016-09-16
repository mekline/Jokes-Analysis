#This paper recalculates T tests based on %-signal-change, per-participant, per-parcel, per-contrast,
#just so I can see more clearly what's going on. Those %-signal-change calculations are
#produced by the awesome toolbox analyses, and represent a single overall calculation
#derived for the whole region (not individual voxels, as mk sometimes forgets)
#

library(dplyr)
library(tidyr)

myResults = read.csv("sig change files/LangfROIsrespNonlitJokes.csv") #this reads from
myName = "LangfROIsrespNonlitJokes"
myContrast = "Jokes > Nonjokes"

#For everything except ToMCustom, we only care about contrast 3, "Joke-Lit"
myResults <- myResults %>%
  filter(Contrast == 3)

#Special stuffs for ToMCustom
#myResults <- myResults %>%
#  filter((Contrast == 3) | (Contrast == 1)) %>%
#  spread(Contrast, sigChange)

#names(myResults) <- c(names(myResults[,1:5]), "low","high")
#myResults <- mutate(myResults, sigChange = high-low)

##### BELOW SHOULDN"T NEED CHANGES


myTests = data.frame(System= character(0), Contrast= character(0), ROI = integer(0), t=numeric(0), p=numeric(0), stringsAsFactors = FALSE)

#For each ROI, conduct a significance test. 

for (fr in 1:length(unique(myResults$ROI))){
  thisROI = unique(myResults$ROI)[fr]
  theseResults <- myResults %>%
    filter(ROI == thisROI)
  myt <- t.test(theseResults$sigChange, mu=0, alt='greater')
  myTests[nrow(myTests)+1,] <- c(myName, myContrast, thisROI, myt$statistic, myt$p.value )
}

#Average signal changes for each person, then do another test!
myAvgResults <- myResults %>%
  group_by(SubjectNumber)%>%
  summarise(avSigChange = mean(sigChange))

myt <- t.test(myAvgResults$avSigChange, mu=0, alt='greater')

myTests[nrow(myTests)+1,] <- c(myName, myContrast, 'average over ROIs', myt$statistic, myt$p.value )


#Some optional monkey business for adding ROInames

#Lang
myTests <-arrange(myTests, ROI=c(6,4,5,2,1,3,7))
#myTests$ROI.Names = c('LPostTemp', 'LAntTemp', 'LAngG', 'LIFG',      'LMFG',     'LIFGorb', 'average over ROIs');
myTests$ROI.Names = c('RPostTemp', 'RAntTemp', 'RAngG', 'RIFG',      'RMFG',     'RIFGorb', 'average over ROIs');

#MD
myTests$ROI.Names = c('LIFGop',  'RIFGop', 'LMFG',    'RMFG',    'LMFGorb',
                      'RMFGorb', 'LPrecG', 'RPrecG',  'LInsula', 'RInsula',
                      'LSMA',    'RSMA',   'LParInf', 'RParInf', 'LParSup',
                      'RParSup', 'LACC',   'RACC', 'average over ROIs');

#ToM
myTests$ROI.Names = c('DMPFC', 'LTPJ',  'MMPFC', 'PC',
                     'RTPJ',  'VMPFC', 'RSTS','average over ROIs');


#For putting together the whole set!
toPrint = rbind(toPrint, myTests)

#Do some corrections on that whole set of tests!!!! (Note, for correctness do this without average values...)
toPrint <- mutate(toPrint, p.Adjust = p.adjust(as.numeric(p), method = "fdr"))

#write it out

zz = file('some_t_tests.csv', 'w')
write.csv(toPrint, zz, row.names=FALSE)
close(zz)


