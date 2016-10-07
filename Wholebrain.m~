% second level (RFX) analysis

rerun_firstlevel_contrasts      = 0*[0,0,1];
rerun_secondlevel_analyses      = 1*[0,0,1];

%% define experiment structures
experiments(1)=struct(...
    'name','langloc',...% localizer expt
    'pwd1','/mindhive/nklab/projects/langsyntax/data/',...
    'pwd2','firstlevel_langloc',...
    'data',{{'KAN_syntax_01', 'KAN_syntax_02', 'KAN_syntax_03', 'KAN_syntax_04', 'KAN_syntax_05', 'KAN_syntax_06', 'KAN_syntax_07', 'KAN_syntax_08', 'KAN_syntax_09', 'KAN_syntax_10','KAN_syntax_11','KAN_syntax_12','KAN_syntax_13'}});
experiments(2)=struct(...
    'name','DSFIN',...% non-language expt
    'pwd1','/mindhive/nklab/projects/langsyntax/data/',...
    'pwd2','firstlevel_DSFIN',...
    'data',{{'KAN_syntax_01', 'KAN_syntax_02', 'KAN_syntax_03', 'KAN_syntax_05', 'KAN_syntax_06', 'KAN_syntax_07', 'KAN_syntax_08', 'KAN_syntax_09', 'KAN_syntax_10','KAN_syntax_11','KAN_syntax_12','KAN_syntax_13'}});
experiments(3)=struct(...
    'name','nonlit_joke',...% non-language expt
    'pwd1','/users/evelina9/more_evelina_files/MEGADATA.now.on.evlabfs/',...
    'pwd2','firstlevel_nonlit_joke',...
    'data',{{'152_KAN_RHnonlit_01','138_KAN_RHnonlit_02','136_KAN_RHnonlit_03','194_KAN_RHnonlit_04','097_KAN_RHnonlit_05','135_KAN_RHnonlit_06','197_KAN_RHnonlit_07','198_KAN_RHnonlit_08','018_KAN_RHnonlit_09','049_KAN_RHnonlit_10','201_KAN_RHnonlit_11','175_KAN_RHnonlit_12'}});

%% first-level contrasts
existingcontrasts=[];
if any(rerun_firstlevel_contrasts),
    addpath('/users/evelina9/more_evelina_files/MEGAANALYSIS/');
    for exp=find(rerun_firstlevel_contrasts),
        for nsub=1:length(experiments(exp).data),
            subjectname=experiments(exp).data{nsub};
            foldername=fullfile(experiments(exp).pwd1,subjectname,experiments(exp).pwd2);
            load(fullfile(foldername,'SPM.mat'));
            SPM.swd = foldername;
            save(fullfile(foldername,'SPM.mat'),'SPM');
            jobs{1}.stats{1}.con.spmmat = {fullfile(foldername,'SPM.mat')};
            jobs{1}.stats{1}.con.consess = feval(['build_contrasts_',experiments(exp).name],subjectname,fullfile(foldername,'SPM.mat'));
            spm_jobman('run',jobs);
        end
    end
end


%% second-level analyses
if any(rerun_secondlevel_analyses),
    cwd=pwd;
    spm('Defaults','fmri');
    addpath('/users/evelina9/more_evelina_files/MEGAANALYSIS/');
    for exp=find(rerun_secondlevel_analyses),
        contrasts = eval(['build_contrasts_',experiments(exp).name]);
        foldername1=[experiments(exp).pwd1];
        ok=mkdir(foldername1,['secondlevel_',experiments(exp).name]);
        foldername1=fullfile(foldername1,['secondlevel_',experiments(exp).name]); %e.g. /groups/domspec/data/secondlevel_SWJN/
        for ncon=1:length(contrasts),
            if ~any(existingcontrasts==ncon),
                ok=mkdir(foldername1,contrasts{ncon}{1});
                foldername3=fullfile(foldername1,contrasts{ncon}{1});                   %e.g. /groups/domspec/data/secondlevel_SWJN/S-J/
                
                cd(foldername3);
                clear SPM;
                SPM.xX.X=ones(length(experiments(exp).data),1);
                SPM.xX.name={[contrasts{ncon}{1},' ',experiments(exp).name]};
                for nsub=1:length(experiments(exp).data),
                    filename=fullfile(experiments(exp).pwd1,experiments(exp).data{nsub},experiments(exp).pwd2,['con_',num2str(ncon,'%04d'),'.img']);
                    SPM.xY.VY(nsub,1)=spm_vol(filename);
                end
                save('SPM.mat','SPM');
                !rm SPM.mat
                !rm mask.img
                SPM=spm_spm(SPM);
                c=1;
                cname=SPM.xX.name{1};
                SPM.xCon = spm_FcUtil('Set',cname,'T','c',c',SPM.xX.xKXs);
                SPM=spm_contrasts(SPM,1:length(SPM.xCon));
                save('SPM.mat','SPM');
                cd(cwd);
            end
        end
    end
end
