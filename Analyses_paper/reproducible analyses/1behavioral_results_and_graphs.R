#Analyzing the behavioral results from the jokes paper!
rm(list=ls(all=TRUE))

library(tidyr)
library(dplyr)
library(lme4)
library(ggplot2)
library(bootstrap)

#(set your own wd first)
setwd("~/Dropbox/_Projects/Jokes - fMRI/Jokes-Analysis Repository/Analyses_paper/reproducible analyses")
mywd <- getwd()
setwd("indsubjs_behavioral_data")
myfi <- list.files(pattern='*data\\.csv')

mydata <- data.frame(NULL)

for(f in myfi) {
  tmp <- read.csv(f, header=T)
  tmp$filename <- f
  mydata <- rbind(mydata, tmp)
}

#Subjs 6 onward have oddly formatted TR info at the top of files, remove it
mydata <- mydata[grep("KAN",mydata$subj),]

#Drop nonresponding trials
mydata$RT <- as.numeric(as.character(mydata$RT))
mydata <- mydata[!is.na(mydata$RT),]

#Relable subject data from filenames!
mydata <- mydata %>%
  mutate(newSubjectName = substr(filename,1,15))


####
# RT
####
#Get average RTs per category per participant
avgRT <- mydata %>%
  group_by(newSubjectName, category) %>%
  summarise(meanRT = mean(RT))

#T test
t.test(meanRT ~ category, data=avgRT)
#Response times are not different by condition


####
# Ratings
####

#Get average ratings per category per participant
mydata$response <- as.numeric(as.character(mydata$response))
avgResponse <- mydata %>%
  group_by(newSubjectName, category) %>%
  summarise(meanResponse = mean(response))

t.test(meanResponse ~ category, data=avgResponse)
#Responses are different by condition! The jokes are funny!


####
# Graphs!
####

#sterr <- function(mylist){
#  my_se = sd(mylist)/sqrt(length(mylist)) 
#  
#  return(my_se)
#}

#Edit! We should be doing bootstrapped 95% confidence intervals instead! calculate them from allSigChange
#then merge into mystats

bootup <- function(mylist){
  foo <- bootstrap(mylist, 1000, mean)
  return(quantile(foo$thetastar, 0.975)[1])
}
bootdown <- function(mylist){
  foo <- bootstrap(mylist, 1000, mean)
  return(quantile(foo$thetastar, 0.025)[1])
}

#Make the organized data for ggplot
avgRT <- ungroup(avgRT)
avgResponse <- ungroup(avgResponse)

#plot millisecnds
avgRT$meanRT <- avgRT$meanRT * 1000
#rename categories
avgRT$categoryLabel <- ""
avgRT[avgRT$category == "joke",]$categoryLabel <- "Jokes"
avgRT[avgRT$category == "nonjoke",]$categoryLabel <- "Non-Jokes"
avgResponse$categoryLabel <- ""
avgResponse[avgResponse$category == "joke",]$categoryLabel <- "Jokes"
avgResponse[avgResponse$category == "nonjoke",]$categoryLabel <- "Non-Jokes"

toPlotRT = avgRT %>%
  group_by(categoryLabel)%>%
  summarise(mean = mean(meanRT))

tobootUp = avgRT %>%
  group_by(categoryLabel)%>%
  summarise(bootup = bootup(meanRT))
tobootDown = avgRT %>%
  group_by(categoryLabel)%>%
  summarise(bootdown = bootdown(meanRT))

#toPlotRT = merge(toPlotRT, toStr)
#toPlotRT$se_up <- toPlotRT$mean + toPlotRT$sterr
#toPlotRT$se_down <- toPlotRT$mean - toPlotRT$sterr
toPlotRT = merge(toPlotRT, tobootUp)
toPlotRT = merge(toPlotRT, tobootDown)

toPlotResp = avgResponse %>%
  group_by(categoryLabel)%>%
  summarise(mean = mean(meanResponse))

#toStr = avgResponse %>%
#  group_by(categoryLabel)%>%
#  summarise(sterrRes = sterr(meanResponse))

#toPlotResp = merge(toPlotResp, toStr)
#toPlotResp$se_up <- toPlotResp$mean + toPlotResp$sterr
#toPlotResp$se_down <- toPlotResp$mean - toPlotResp$sterr

tobootUp = avgResponse %>%
  group_by(categoryLabel)%>%
  summarise(bootup = bootup(meanResponse))
tobootDown = avgResponse %>%
  group_by(categoryLabel)%>%
  summarise(bootdown = bootdown(meanResponse))

toPlotResp = merge(toPlotResp, tobootUp)
toPlotResp = merge(toPlotResp, tobootDown)

setwd(mywd)

ggplot(data=toPlotRT, aes(y=mean, x=categoryLabel)) + 
  geom_bar(position=position_dodge(), stat="identity") +
  geom_errorbar(aes(ymin=bootdown, ymax=bootup), colour="black", width=.1, position=position_dodge(.9)) +
  coord_cartesian(ylim=c(0,1200)) +
  scale_y_continuous(breaks = seq(0, 1200, 200))+
  xlab('Stimulus type') +
  ylab('Response time (milliseconds)') +
  scale_fill_manual(name="", values=c("gray35", "gray60")) +
  theme_bw() +
  theme(legend.key = element_blank()) +
  theme(strip.background = element_blank()) +
  # Optional, remove for RHLang and ToMCustom since we want the legend there...
  theme(legend.position="none")  
ggsave(filename="behavioralrt.jpg", width=3, height=3)
  
ggplot(data=toPlotResp, aes(y=mean, x=categoryLabel)) + 
  geom_bar(position=position_dodge(), stat="identity") +
  geom_errorbar(aes(ymin=bootdown, ymax=bootup), colour="black", width=.1, position=position_dodge(.9)) +
  coord_cartesian(ylim=c(1,4)) +
  scale_y_continuous(breaks = seq(1, 4, 1))+
  xlab('Stimulus type') +
  ylab('Average funny-ness rating') +
  scale_fill_manual(name="", values=c("gray35", "gray60")) +
  theme_bw() +
  theme(legend.key = element_blank()) +
  theme(strip.background = element_blank()) +
  # Optional, remove for RHLang and ToMCustom since we want the legend there...
  theme(legend.position="none")  
ggsave(filename="behavioral.jpg", width=3, height=3)

