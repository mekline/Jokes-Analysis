library("reshape")
library("ggplot2")

#set directory
setwd("~/Documents/MIT/UROP-Ev/data_nonlit_joke/R_data/")
f <- list.files()

#combine all data files in d
d <- NULL
for (i in 1:length(f)) {
  d <- rbind(d,read.csv(f[i],header=T))
}



d.melt <- melt(d, measure.vars=c("RT","response"))
d.rt <- d.melt[d.melt$variable=="RT",]
d.resp <- d.melt[d.melt$variable=="response",]


subj <- cast(d.resp, subj~category, mean, na.rm=T)

########### behavioral summary ###########

GraphMeans <- function(d,value) {
  #get subject means
  subj.m <- cast(d, subj~category, mean, na.rm=T)
  #t-test
  print(t.test(subj.m$joke, subj.m$nonjoke, paired=TRUE))
  
  #get condition means
  group.m <- apply(subj.m, 2, mean, na.rm=T)
  group.sd <- apply(subj.m, 2, sd, na.rm=T)
  group.l <- colSums(!is.na(subj.m[,-c(1)]))
  group.sterr <- group.sd/sqrt(group.l)

  #plot 
  df <- data.frame(v = group.m, sterr = group.sterr, type = names(group.m))
  
  write.csv(df, paste("jokes_",value,".csv"))
  limits <- aes(ymax = v + sterr, ymin = v-sterr)
  g <- ggplot(df, aes(fill = type, x = type, y = v))+
    geom_bar(position = "dodge", width = 0.8, stat = "identity")+
    geom_errorbar(limits, position = position_dodge(width = 0.8), width = 0.5)+
    scale_fill_manual(values = c("mediumvioletred","royalblue"))+#c("violetred1", "turquoise3"))+
    ggtitle(paste("average",value,"by subject"))+
    theme_bw() + ylab(value)
  
  if (value=="rating") {
    g <- g+scale_y_continuous(limits=c(0,4.00))
  }
  g
}

#save pdf of plots
pdf("../behav_summary.pdf", width=6, height=4)
GraphMeans(d.rt,"RT")
GraphMeans(d.resp,"rating")
dev.off()

########### response tally ###########

counts <- cast(d.resp, subj+category~value,length)

write.csv(counts,"../counts.csv",row.names=FALSE)





a <- read.csv("../subj_rating_tom_corr.csv",header=T)
c <- cor(a$joke.contrast, a$average.ToM)

df <- data.frame(rating = a$joke.contrast,
                 activation = a$average.ToM)

g<-ggplot(df, aes(x=rating, y=activation)) + 
  geom_point() +
  scale_x_continuous(limits=c(0,2)) +
  scale_y_continuous(limits=c(-0.25,0.75)) +
  geom_smooth(method=lm, se=FALSE) +
  ylab("average activation (jokes - control)") +
  xlab("average rating (jokes - control)") +
  theme(text = element_text(size=20))

postscript("../corr_ToM.eps",horizontal=FALSE,width=5,height=5)
g
dev.off()








b <- read.csv("../subj_rating_lmd_corr.csv",header=T)
c <- cor(b$joke.contrast, b$average.L_MD)

df <- data.frame(rating = b$joke.contrast,
                 activation = b$average.L_MD)

g<-ggplot(df, aes(x=rating, y=activation)) + 
  geom_point() + 
  scale_x_continuous(limits=c(0,2)) +
  scale_y_continuous(limits=c(-0.25,0.75)) +
  geom_smooth(method=lm, se=FALSE) +
  ylab("average activation (jokes - control)") +
  xlab("average rating (jokes - control)") +
  theme(text = element_text(size=20))

postscript("../corr_LMD.eps",horizontal=FALSE,width=5,height=5)
g
dev.off()



u <- read.csv("../subject_activations_corr.csv", header=TRUE)

cor(u$MROI.7,u$MROI.9)


