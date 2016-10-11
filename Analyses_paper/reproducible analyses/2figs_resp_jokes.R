#This file reads in ALL the %-signal-change values, per-participant, per-parcel, per-contrast,
# Those %-signal-change calculations are produced by the awesome toolbox analyses, and represent a single overall calculation
#derived for the whole parcel region (not individual voxels, as mk sometimes forgets)

rm(list = ls())
library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)

setwd("~/Dropbox/_Projects/Jokes - fMRI/Jokes-Analysis Repository/Analyses_paper/contrasts/")

########
#READ IN DATA
########
#Here, we read in all those files, calculate a whole passle of mean and standard error bars, and then make graphs

# Add in the contrast and ROI names so it's not just numbers!!!!! (This ordering comes from the 
# standard ordering produced by the 2nd level analyses; we'll arrange differently in the plots)

RHLangROI.Names = c('RPost Temp', 'RAnt Temp', 'RAngG', 'RIFG',      'RMFG',     'RIFG orb');
LangROI.Names = c('LPost Temp', 'LAnt Temp', 'LAngG', 'LIFG',      'LMFG',     'LIFG orb');

MDROI.Names = c('LIFG op',  'RIFG op', 'LMFG',    'RMFG',    'LMFG orb',
                      'RMFG orb', 'LPrecG', 'RPrecG',  'LInsula', 'RInsula',
                      'LSMA',    'RSMA',   'LPar Inf', 'RPar Inf', 'LPar Sup',
                      'RPar Sup', 'LACC',   'RACC');

ToMROI.Names = c('DM PFC', 'LTPJ',  'MM PFC', 'PC',
                      'RTPJ',  'VM PFC', 'RSTS');

normal.contrasts = c('joke', 'lit', 'joke-lit')
custom.contrasts = c('low','med','high','other')


myResults = read.csv('RHLangfROIsrespNonlitJokes.csv')%>%
  mutate(ROIName = RHLangROI.Names[ROI]) %>%
  mutate(contrastName = normal.contrasts[Contrast])%>%
  mutate(Group = 'RHLang')
allSigChange = myResults

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

#Little extra for ToM: Remove the VMPFC because it did not replicate the basic localizer finding.
myResults = read.csv('NewToMfROIsrespNonlitJokes.csv')%>%
  mutate(ROIName = ToMROI.Names[ROI]) %>%
  mutate(contrastName = normal.contrasts[Contrast]) %>%
  mutate(Group = 'ToM') %>%
  filter(ROIName !="VM PFC")
allSigChange = rbind(allSigChange, myResults)

myResults = read.csv('NewToMfROIsresCustomJokes.csv')%>%
  mutate(ROIName = ToMROI.Names[ROI]) %>%
  mutate(contrastName = custom.contrasts[Contrast])%>%
  mutate(Group = 'ToMCustom')%>%
  filter(ROIName !="VM PFC")
allSigChange = rbind(allSigChange, myResults)



#########
# TRANSFORMATIONS
#########

#First, in addition to the by-region signal changes, we are going to give each person an average signal change value for each localizer 
avgSigChange = aggregate(allSigChange$sigChange, by=list(allSigChange$Group,allSigChange$SubjectNumber,allSigChange$contrastName), mean)
names(avgSigChange) = c('Group','SubjectNumber', 'contrastName','sigChange')
avgSigChange$ROIName = 'LocalizerAverage'
avgSigChange$ROI = 0

allSigChange <- allSigChange %>%
  select(one_of('Group','ROIName', 'ROI','SubjectNumber', 'contrastName','sigChange'))

allSigChange <- rbind(allSigChange, avgSigChange)

#Drop the contrasts we're not interested in...
toGraph = allSigChange %>%
  filter(contrastName %in% c('joke','lit','high','med','low'))

#Next, get the table that we'll be making the graphs from: for each region (including the average region), take all 
#the individual signal changes and calculate a mean and a standard error
sterr <- function(mylist){
  my_se = sd(mylist)/sqrt(length(mylist)) 
  
  return(my_se)
}

mystats = aggregate(toGraph$sigChange, by=list(toGraph$Group, toGraph$ROIName, toGraph$ROI,toGraph$contrastName), mean)
names(mystats) = c('Group','ROIName', 'ROI','contrastName', 'themean')
myster = aggregate(toGraph$sigChange, by=list(toGraph$Group, toGraph$ROIName, toGraph$ROI,toGraph$contrastName), sterr)
names(myster) = c('Group','ROIName', 'ROI','contrastName', 'sterr')

mystats = merge(mystats,myster)
mystats$se_up = mystats$themean + mystats$sterr
mystats$se_down = mystats$themean - mystats$sterr


#########
# Graphs!
#########

#Now we can use the information stored in mystats to make pretty graphs! This could be done in excel too by printing mystats
#Change to figs output folder
setwd("~/Dropbox/_Projects/Jokes - fMRI/Jokes-Analysis Repository/Analyses_paper/reproducible analyses/figs")


#Select the rows we want for each graph, and order them how we want! For now, localizerAverage will just come first in all sets
mystats$contNo <- 1
mystats[mystats$contrastName == 'joke',]$contNo <- 1
mystats[mystats$contrastName == 'lit',]$contNo <- 2
mystats[mystats$contrastName == 'high',]$contNo <- 1
mystats[mystats$contrastName == 'med',]$contNo <- 2
mystats[mystats$contrastName == 'low',]$contNo <- 3
#mystats = arrange(mystats, ROI)
mystats = arrange(mystats, contNo)

#Add a new col grouping to separate out the localizer average
mystats$ROIGroup <- ""
mystats[mystats$ROIName == "LocalizerAverage",]$ROIGroup <- "across fROIs"
mystats = arrange(mystats, desc(ROIGroup))

#Changes for prettiness
mystats[mystats$ROIName=="LocalizerAverage",]$ROIName <- "average across fROIs"
mystats$ROIName <- str_wrap(mystats$ROIName, width = 4)

mystats$contrastLabel <- mystats$contrastName
mystats[mystats$contrastName == "joke",]$contrastLabel <- "Jokes\n  "
mystats[mystats$contrastName == "lit",]$contrastLabel <- "Non-jokes\n   "
mystats[mystats$contrastName == "high",]$contrastLabel <- "high\n  "
mystats[mystats$contrastName == "med",]$contrastLabel <- "med\n   "
mystats[mystats$contrastName == "low",]$contrastLabel <- "low\n  "



#Subsets & Ordering (elaborate code, probably can condense these; ggplot is finicky at orders)
RHLang = filter(mystats, Group == 'RHLang')
RHLang <- RHLang[order(RHLang$ROI),]
RHLang$PresOrder = c(13,14, 9,10, 7,8, 11,12, 3,4,5,6,1,2) #Reorder for standard presentation!
RHLang <- RHLang[order(RHLang$PresOrder),]
RHLang = arrange(RHLang, desc(ROIGroup))


LHLang = filter(mystats, Group == 'LHLang')
LHLang <- LHLang[order(LHLang$ROI),]
LHLang$PresOrder = c(13,14, 9,10, 7,8, 11,12, 3,4,5,6,1,2)
LHLang <- LHLang[order(LHLang$PresOrder),]
LHLang = arrange(LHLang, desc(ROIGroup))


MDLeft = filter(mystats, Group == 'MDLeft')
MDLeft <- MDLeft[order(MDLeft$ROI),]
MDLeft = arrange(MDLeft, desc(ROIGroup))

MDRight = filter(mystats, Group == 'MDRight')
MDRight <- MDRight[order(MDRight$ROI),]
MDRight = arrange(MDRight, desc(ROIGroup))

ToM = filter(mystats, Group == 'ToM')
ToM <- ToM[order(ToM$ROI),]
ToM$PresOrder = c(1,2,3,4,9,10,5,6,7,8,11,12,13,14)
ToM <- ToM[order(ToM$PresOrder),]
ToM = arrange(ToM, desc(ROIGroup))

ToMCustom = filter(mystats, Group == 'ToMCustom')
ToMCustom <- arrange(ToMCustom, contNo)
ToMCustom <- ToMCustom[order(ToMCustom$ROI),]
ToMCustom$PresOrder = c(1,2,3,4,5,6,13,14,15,7,8,9,10,11,12,16,17,18,19,20,21)
ToMCustom <- ToMCustom[order(ToMCustom$PresOrder),]
ToMCustom = arrange(ToMCustom, desc(ROIGroup))


#Graphing function!

makeBar = function(plotData,ylow=-0.5,yhigh=2.5, mycolors = c("gray35", "gray60")) {

  #freeze factor orders
  plotData$ROIName <- factor(plotData$ROIName, levels = unique(plotData$ROIName))
  plotData$ROIGroup <- factor(plotData$ROIGroup, levels = unique(plotData$ROIGroup))
  plotData$contrastLabel <- factor(plotData$contrastLabel, levels = unique(plotData$contrastLabel))
  myfi = paste(plotData$Group[1], '.jpg', sep="")#filename
  print(myfi)

ggplot(data=plotData, aes(x=ROIName, y=themean, fill=contrastLabel)) + 
  geom_bar(position=position_dodge(), stat="identity") +
  geom_errorbar(aes(ymin=se_down, ymax=se_up), colour="black", width=.1, position=position_dodge(.9)) +
  coord_cartesian(ylim=c(ylow,yhigh)) +
  scale_y_continuous(breaks = seq(-0.5, 2.5, 0.5))+
  xlab('') +
  ylab(str_wrap('% signal change over fixation', width=18)) +
  scale_fill_manual(name="", values=mycolors) +
  theme_bw() +
  theme(legend.key = element_blank()) +
  theme(text = element_text(size = 40)) +
  facet_grid(~ROIGroup, scale='free_x', space='free_x') +
  theme(strip.background = element_blank()) +
  theme(strip.text = element_blank()) 
  # Optional, remove for RHLang and ToMCustom since we want the legend there...
  #+ theme(legend.position="none")
 

  ggsave(filename=myfi, width=length(unique(plotData$ROIName))*2.2, height=6.1)
  
}

makeBar(LHLang)
makeBar(RHLang)
makeBar(MDLeft)
makeBar(MDRight)
makeBar(ToM, -0.5, 1)
makeBar(ToMCustom, -0.5, 1, c("high\n  "= "gray35", "med\n   "= "gray50", "low\n  "= "gray65"))
