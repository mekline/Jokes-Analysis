#same thing again, just to report differences from fixation

library(dplyr)
library(tidyr)

myResults = read.csv("sig change files/RHLangfROIsrespNonlitJokes.csv") #this reads from
myName = "RHLangfROIsrespNonlitJokes"

#Get results to Jokes>fix and Non>fix
Jokes <- myResults %>%
  filter(Contrast == 1)
Nonjokes <- myResults %>%
  filter(Contrast == 2)


##### BELOW SHOULDN"T NEED CHANGES


myTests = data.frame(System= character(0), Contrast= character(0), ROI = integer(0), t=numeric(0), p=numeric(0), stringsAsFactors = FALSE)

#For each ROI and each contrast, conduct a significance test. 

myContrast = "Jokes"
for (fr in 1:length(unique(Jokes$ROI))){
  thisROI = unique(Jokes$ROI)[fr]
  theseResults <- Jokes %>%
    filter(ROI == thisROI)
  myt <- t.test(theseResults$sigChange, mu=0, alt='greater')
  myTests[nrow(myTests)+1,] <- c(myName, myContrast, thisROI, myt$statistic, myt$p.value )
}

myContrast = "Nonjokes"
for (fr in 1:length(unique(Nonjokes$ROI))){
  thisROI = unique(Nonjokes$ROI)[fr]
  theseResults <- Nonjokes %>%
    filter(ROI == thisROI)
  myt <- t.test(theseResults$sigChange, mu=0, alt='greater')
  myTests[nrow(myTests)+1,] <- c(myName, myContrast, thisROI, myt$statistic, myt$p.value )
}




#Some optional monkey business for adding ROInames

#Lang (L or R)
myTests <-arrange(myTests, ROI=c(6,4,5,2,1,3, 12,10,11,8,7,9))
myTests$ROI.Names = c('LPostTemp', 'LAntTemp', 'LAngG', 'LIFG',      'LMFG',     'LIFGorb', 'LPostTemp', 'LAntTemp', 'LAngG', 'LIFG',      'LMFG',     'LIFGorb');
myTests$ROI.Names = c('RPostTemp', 'RAntTemp', 'RAngG', 'RIFG',      'RMFG',     'RIFGorb','RPostTemp', 'RAntTemp', 'RAngG', 'RIFG',      'RMFG',     'RIFGorb');

#MD
myTests$ROI.Names = c('LIFGop',  'RIFGop', 'LMFG',    'RMFG',    'LMFGorb',
                      'RMFGorb', 'LPrecG', 'RPrecG',  'LInsula', 'RInsula',
                      'LSMA',    'RSMA',   'LParInf', 'RParInf', 'LParSup',
                      'RParSup', 'LACC',   'RACC','LIFGop',  'RIFGop', 'LMFG',    'RMFG',    'LMFGorb',
                      'RMFGorb', 'LPrecG', 'RPrecG',  'LInsula', 'RInsula',
                      'LSMA',    'RSMA',   'LParInf', 'RParInf', 'LParSup',
                      'RParSup', 'LACC',   'RACC');

#ToM
myTests$ROI.Names = c('DMPFC', 'LTPJ',  'MMPFC', 'PC',
                     'RTPJ',  'VMPFC', 'RSTS','DMPFC', 'LTPJ',  'MMPFC', 'PC',
                     'RTPJ',  'VMPFC', 'RSTS');


#For putting together the whole set!
toPrint = myTests #OR
toPrint = rbind(toPrint, myTests)

#Do some corrections on that whole set of tests!!!! (Note, for correctness do this without average values...)
toPrint <- mutate(toPrint, p.Adjust = p.adjust(as.numeric(p), method = "fdr"))

#write it out

zz = file('some_t_tests.csv', 'w')
write.csv(toPrint, zz, row.names=FALSE)
close(zz)


