library(tidyr)
library(dplyr)
rois <- read.csv("roi sizes.csv")

#Let's do a series of Wilcoxon rank sum (unpaired!) tests to see if systems have different sized ROIs

MD <- filter(rois, System == "MD")
TM <- filter(rois, System == "ToM")
LA <- filter(rois, System == "Language") #RH and LH are same bc RH is just the reflection
MDL <- filter(MD, ROI.number %% 2 == 1)
MDR <- filter(MD, ROI.number %% 2 == 0)

wilcox.test(MD$Size.in.voxels, TM$Size.in.voxels, paired=FALSE)
wilcox.test(MD$Size.in.voxels, LA$Size.in.voxels, paired=FALSE)
wilcox.test(TM$Size.in.voxels, LA$Size.in.voxels, paired=FALSE)

#try just RH md...
wilcox.test(MDR$Size.in.voxels, TM$Size.in.voxels, paired=FALSE)
wilcox.test(MDR$Size.in.voxels, LA$Size.in.voxels, paired=FALSE)

summarise(MD, mean(Size.in.voxels))
summarise(TM, mean(Size.in.voxels))
summarise(LA, mean(Size.in.voxels))
