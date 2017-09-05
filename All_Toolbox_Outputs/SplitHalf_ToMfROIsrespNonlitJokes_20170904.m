
%Before running you should make sure that you are using the correct version of the
%SPM toolbox if it is something other than the standard. I've moved all the common parameters we 
%usually set up to the top of the script; anything else you want you can
%change in the big struct if you want something else. It also assumes you'll provide a parcel file
%(manual ROI option)

%On run, matlab asks you for some stuff; we usually set Minimal ROI-level overlap to 0 and 
%Explicit masking to None.  Those should really be specified somewhere below instead!!

%Note! This example will throw up a warning that your loc and crit are not orthogonal - that's expected, because we're using the same firstlevel info for both the localizer and the measured experiment. SPM automagically will create independent subsets (actually a fancy bootstrapping instead of odd/even) to avoid double-dipping.

%Some explanations:
%'swd' output folder for the results -DONT FORGET TO CHANGE THIS ABOVE!!
%'EffectOfInterest_contrasts' - All or anything of the first-level cons that were calculated before
%'Localizer_contrasts' - Usually just one! How are you finding the subject-specific region.
%'Localizer_thr_type' and 'Localizer_thr_p' Various choices here: 
%   For top 10% of voxels found in the parcels: 'percentile-ROI-level' and .1
%   For top N voxels: 'Nvoxels-ROI-level' and 50 (for 50 voxels)
%'type' and 'ManualROIs' - the parcels to find the subject-specific activations in!  Usually we
%set 'type'='mROI', and then specify the path to the parcel you want to use. It will be an img file.

%TODO in this file
% Any kind of asserts for well formed input
% Give the general case for fullfiling all the paths (this assumes all 1st level data
% is in the same place)
% Look up & add the 

%%%
%SET ALL FILEPATHS AND EXP INFO HERE 

MyDataFolder = '/mindhive/evlab/u/Shared/SUBJECTS/'; % path to the data directory

participant_sessions = {{'152_KAN_RHnonlit_01','138_KAN_RHnonlit_02','136_KAN_RHnonlit_03','194_KAN_RHnonlit_04','097_KAN_RHnonlit_05','135_KAN_RHnonlit_06','197_KAN_RHnonlit_07','198_KAN_RHnonlit_08','018_KAN_RHnonlit_09','049_KAN_RHnonlit_10','201_KAN_RHnonlit_11','175_KAN_RHnonlit_12'}}; %The subject IDs of individual subjects you'll analyze

MyOutputFolder = '/mindhive/evlab/u/mekline/Documents/Projects/Jokes_Study1/Jokes_Repo/All_Toolbox_Analyses/SplitHalf_ToMfROIsrespNonlitJokes_20170904_results'; %Where should the results wind up? For testing this script, this is all u need to change and it should just work! Note: usually the scripts are good about this but this one actually does break if you put a slash at the end of your dir name.

firstlevel_loc = 'firstlevel_ToMshort'; % path to the first-level analysis directory for the lang localizer or whatever
firstlevel_crit = 'firstlevel_nonlit_joke'; %path to 1st-level analysis directory for the critical task


loc_cons = {{'bel-pho'}}; %Which contrast used to localize issROIs?
crit_cons = {{'ODD_joke-lit','EVEN_joke-lit'}}; %Effect of interest contrasts: cons of the crit. experiment do we want to measure there? It could be the same as the loc! In that case SPM will make ur data independent for you :)

what_parcels = '/users/evelina9/fMRI_PROJECTS/ROIS/ToM_ROIs/CoreToMfROIs.img'; %specify the full path to the *img or *nii file that will constrain the search for top voxels

thresh_type = 'percentile-ROI-level'; %percentile-ROI-level or Nvoxels-ROI-level
thresh_p = .1; %Fun fact! In percentile mode, p=proportion (.1=%10), In top-n mode p = n voxels (eg 50)

%%%
%STANDARD TOOLBOX SPECS BELOW
%%%
%Specify the first level data that will be used for the loc (find the space) and crit (measure it)

experiments(1)=struct(...
    'name','loc',...% language localizer 
    'pwd1',MyDataFolder,...  % path to the data directory
    'pwd2',firstlevel_loc,...
    'data', participant_sessions); % subject IDs
experiments(2)=struct(...
    'name','crit',...% non-lang expt
    'pwd1',MyDataFolder,...
    'pwd2',firstlevel_crit,...  % path to the first-level analysis directory for the critical task
    'data', participant_sessions);
%%%

localizer_spmfiles={};
for nsub=1:length(experiments(1).data),
    localizer_spmfiles{nsub}=fullfile(experiments(1).pwd1,experiments(1).data{nsub},experiments(1).pwd2,'SPM.mat');
end

effectofinterest_spmfiles={};
for nsub=1:length(experiments(2).data),
    effectofinterest_spmfiles{nsub}=fullfile(experiments(2).pwd1,experiments(2).data{nsub},experiments(2).pwd2,'SPM.mat');
end

%%%%
%Specify the analysis that you will run. See above for a list of things
%definitely to check/modify!!!

ss=struct(...
    'swd', MyOutputFolder,...   % output directory
    'EffectOfInterest_spm',{effectofinterest_spmfiles},...
    'Localizer_spm',{localizer_spmfiles},...
	  'EffectOfInterest_contrasts', crit_cons,...    % contrasts of interest
    'Localizer_contrasts',loc_cons,...                     % localizer contrast 
    'Localizer_thr_type',thresh_type,...
    'Localizer_thr_p',thresh_p,... 
    'type','mROI',...                                       % can be 'GcSS', 'mROI', or 'voxel'
    'ManualROIs', what_parcels,...
    'model',1,...                                           % can be 1 (one-sample t-test), 2 (two-sample t-test), or 3 (multiple regression)
    'estimation','OLS',...
    'overwrite',true,...
    'ExplicitMasking',[],... %No explicit mapping and NO POPPUP in matlab :)
    'overlap_thr_vox',0,...
    'overlap_thr_roi',0,... %and the 2 mean we don't require Ss activation to overlap with each other (typically used for...excluding participants? can't remember)
    'ask','missing');                                       % can be 'none' (any missing information is assumed to take default values), 'missing' (any missing information will be asked to the user), 'all' (it will ask for confirmation on each parameter)

%%%
%mk addition! Add the version of spm that you intend to use right here, possibly
addpath('/users/evelina9/fMRI_PROJECTS/spm_ss_vE/') %The usual one
%addpath('users/evelina9/fMRI_PROJECTS/spm_ss_Jun18-2015/') %This one has the N-top-voxels options (?)

%%%
%...and now SPM actually runs!
ss=spm_ss_design(ss);                                          % see help spm_ss_design for additional information
ss=spm_ss_estimate(ss);

%%%
%USEFUL INFO!
%%%

% Parcels 
% '/users/evelina9/fMRI_PROJECTS/ROIS/LangParcels_n220_LH.img' - the standard Lang parcels, use contrast {{'S-N'}} 
% '/users/evelina9/fMRI_PROJECTS/ROIS/MDfROIs.img' - the standard MD parcels, use contrast {{'H-E'}}
% 



