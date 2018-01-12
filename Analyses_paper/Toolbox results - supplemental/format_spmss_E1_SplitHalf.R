#load_spmss_results
#
#This file loads the output of one of the results.csv files produced by the (mean signal) toolbox scripts into R.
#If I knew more about the mat file produced you could probably get all of this stuff out of
#there too.  But anyway this gets the mROI_data.csv file, sorts out its structure
#and reorganizes the data into proper longform. Take your analysis from there or save the result in a csv.
#Here, the csvs get saved back to the mean_signal folder for tidyness


library(dplyr)
library(tidyr)
library(stringr)
requireNamespace(plyr)

####
#Stuff to change!
myResultsPath = '/Users/mekline/Dropbox/_Projects/Jokes - fMRI/Jokes-Analysis Repository/Analyses_paper/Toolbox results - supplemental/'
myOutputPath = '/Users/mekline/Dropbox/_Projects/Jokes - fMRI/Jokes-Analysis Repository/Analyses_paper/Toolbox results - supplemental/'

whichResults = c('RevLangfROIsrespMD_20171220_results');

toSave = 1

  ####
  #Leave the rest alone unless you're feeling fancy

all_mean_signal = data.frame(NULL)

for (result in whichResults){
  setwd(paste(myResultsPath,result, sep=""))
  
  #Open the weirdly formatted files and get just the table we want. 
  myfile  = read.csv('spm_ss_mROI_data.csv',sep=',', skip=1)
  lastsub = ncol(myfile) 
  myfile= myfile[complete.cases(myfile[,lastsub]),]#drop things past the individual % changes....
  
  #To add: Look at the # of ROI parcels and their sizes, declare this to be a particular 
  #localizer, provide names for parcels. Also could add all that as an optional function arg. 
  #(this happens in 2_figs etc. now, but we do read the filenames to make that easier...)
  
  #Add details about what this analysis is by splitting up the filename (requires regular filenames!)
  rundetails = str_split_fixed(result, '_', 4)
  myfROIs = rundetails[[1]]
  myTask = rundetails[[3]]
  myMethod = 'Top10Percent'
  if(str_detect(rundetails[[4]], 'Top50')){myMethod = 'Top50Voxels'}
  
  extract_val <- function(mystring, mynum){# fn to extract subject & contrast numbers
    foo = str_split(mystring, "\\.")
    myval = unlist(foo[[1]][mynum])
    return(myval)
    
  }
  
  #Make the data beautiful and longform.
  myfile[] <- lapply(myfile, as.character) #(Everything's a string, no factors)
  myfile <- myfile %>% 
    gather("Subject_and_Cont", "sigChange", Subject.1.1.:ncol(myfile)) %>%
    rowwise() %>% 
    mutate(SubjectNumber = extract_val(Subject_and_Cont, 2)) %>%
    mutate(Contrast = extract_val(Subject_and_Cont, 3)) %>%
    select(-Subject_and_Cont) %>%
    rename(ROI = ROI.) %>%
    mutate(filename = result)%>%
    mutate(fROIs = myfROIs)%>%
    mutate(task = myTask)%>%
    mutate(ind_selection_method = myMethod)%>%
    plyr::rename(replace = c(average.ROI.size="ROI.size"), warn_missing = FALSE)
  
  
  
  #if string contains 'Top50'
  #'LangFrois' etc.
  #(rename critical)
  #'Jokes'
  #'JokesCustom'
  
    
  
  #Optional: print back out a nice file with a more informative name.
  if(toSave){
    setwd(myOutputPath)
    myFileName = paste(result,'.csv', sep="")
    zz <- file(myFileName, "w")
    write.csv(myfile, zz, row.names=FALSE)
    close(zz)
  }

  #And add it to the giant dataframe
  if (nrow(all_mean_signal) == 0){
    all_mean_signal = myfile
  }else{
  all_mean_signal = rbind(all_mean_signal, myfile)
  }
  
}

setwd(myOutputPath)
write.csv(all_mean_signal, 'SigChange_SplitHalf_E1.csv', row.names = FALSE)