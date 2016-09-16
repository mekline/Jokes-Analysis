#Same as the other one, for averages over all ROIs in a localizer!
#

library(dplyr)
library(tidyr)


myName = "RHLangfROIsrespNonlitJokes"
myHemisphere = "Right"
myResults = read.csv("sig change files/RHLangfROIsrespNonlitJokes.csv") %>%
  #filter((Contrast == 3) | (Contrast == 1)) %>% #Just for ToMCustom
  spread(Contrast, sigChange)

#names(myResults) <- c(names(myResults[,1:5]), "low","high") #For ToM
#myResults <- mutate(myResults, hilow = high-low)

names(myResults) <- c(names(myResults[,1:5]),"Jokes", "Nonjokes","Jokes > Nonjokes") #For everything else

#And re-form to long for actual calculations!
myResults <- gather(myResults, "contrastName", "sigChange", 6:ncol(myResults))

#A silly thing to fix up the MD results...
myResults$Hemisphere <-myHemisphere
#myResults[myResults$ROI %%2 == 1,]$Hemisphere <- "Left" #just for MD

myAvgResults <- myResults %>%
  group_by(SubjectNumber, contrastName, Hemisphere)%>%
  summarise(avSigChange = mean(sigChange))

########
myTests = data.frame(System= character(0), Hemisphere = character(0), Contrast= character(0),  t=numeric(0), p=numeric(0), stringsAsFactors = FALSE)

lh <- filter(myAvgResults, Hemisphere == "Left")
rh <- filter(myAvgResults, Hemisphere == "Right")

for (c in 1:length(unique(lh$contrastName))){
  thisCon = unique(lh$contrastName)[c]
  theseResults <- lh %>%
    filter(contrastName == thisCon)
  myt <- t.test(theseResults$avSigChange, mu=0, alt='greater')
  myTests[nrow(myTests)+1,] <- c(myName, "Left", thisCon, myt$statistic, myt$p.value )
}

for (c in 1:length(unique(rh$contrastName))){
  thisCon = unique(rh$contrastName)[c]
  theseResults <- rh %>%
    filter(contrastName == thisCon)
  myt <- t.test(theseResults$avSigChange, mu=0, alt='greater')
  myTests[nrow(myTests)+1,] <- c(myName, "Right", thisCon, myt$statistic, myt$p.value )
}



#For putting together the whole set!
toPrint = rbind(toPrint, myTests)


#write it out

zz = file('some_t_tests.csv', 'w')
write.csv(toPrint, zz, row.names=FALSE)
close(zz)


