#Relating behavioral and contrast data by subjects!
rm(list=ls(all=TRUE))

library(tidyr)
library(dplyr)
library(lme4)
library(ggplot2)

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
# Ratings
####

#Get average ratings per category per participant
mydata$response <- as.numeric(as.character(mydata$response))
avgResponse <- mydata %>%
  group_by(newSubjectName, category) %>%
  summarise(meanResponse = mean(response))


####
# Now go to the contrast files and get the jokes-lit average activation per subj.
setwd("~/Dropbox/_Projects/Jokes - fMRI/Jokes-Analysis Repository/Analyses_paper/contrasts")

ToMROI.Names = c('DMPFC', 'LTPJ',  'MMPFC', 'PC',
                 'RTPJ',  'VMPFC', 'RSTS');
normal.contrasts = c('joke', 'lit', 'joke-lit')

myfMRIResults = read.csv('NewToMfROIsrespNonlitJokes.csv')%>%
  mutate(ROIName = ToMROI.Names[ROI]) %>%
  mutate(contrastName = normal.contrasts[Contrast]) %>%
  mutate(Group = 'ToM') %>%
  filter(contrastName == 'joke-lit') %>%
  filter(ROIName !='VMPFC')%>% #New! This fROI is not reliable in teh localizer data
  group_by(SubjectNumber)%>%
  summarize(meanSigChange = mean(sigChange))

myRatingResults <- mydata %>%
  mutate(SubjectNumber = as.numeric(as.factor(newSubjectName))) %>%
  group_by(SubjectNumber, newSubjectName, category) %>%
  summarise(meanResponse = mean(response)) %>%
  spread(category, meanResponse) %>%
  mutate(meanResponseChange = joke-nonjoke)


#Merge the datasets!
bb <- merge(myRatingResults, myfMRIResults)

## REPORT STATS
cor(bb$meanResponseChange, bb$meanSigChange)

## Added an LM (no random slopes/intercepts! just 1 value/person)
m1 <- lm(meanSigChange ~ meanResponseChange, data = bb)
m0 <- lm(meanSigChange ~ 1, data = bb)
anova(m1,m0)

## MAKE PRETTY GRAPH
setwd("~/Dropbox/_Projects/Jokes - fMRI/Jokes-Analysis Repository/Analyses_paper/reproducible analyses/figs")
coef(lm(meanResponseChange ~ meanSigChange, data = bb))

ggplot(data=bb, aes(y=meanSigChange, x=meanResponseChange)) + 
  geom_point() +
  geom_smooth(method="lm", se=FALSE) + 
  scale_y_continuous(limits = c(-0.25, 0.50), breaks = seq(-0.25, 0.50, 0.25)) + 
  scale_x_continuous(limits = c(0, 1.75), breaks = seq(0, 2, 0.5)) +
  xlab('average rating response \n(Jokes - Non-jokes)') +
  ylab('avg. % signal change \n(Jokes - Non-jokes)') +
  theme_bw() +
ggsave(filename="behav_activation.jpg", width=3, height=3)
  
