function nonlit_fmri(idsub,r) 
% Inputs:
% idsub = sting with subject ID; 
% ***last 2 chars must be 2 digits with subject number (0-padded)***
% r = run number; scalar 1:4; 

%standard naming: KAN_evDB_20150223a
%% coding & debugging
dbmode = false; 
if dbmode
    dbstop if error
    fprintf('debugging mode \n')    
    idsub = 'EVLAB_nonlit-test_02'; 
    r = 4; 
end

%% navigation
%change for DAX
rootdir = '~/Documents/EvLab/nonlit_fmri'; 
behavdir = fullfile(rootdir,'behavioral'); 

%% some variables
subnum = str2double(idsub(end-1:end));

nitem = 96; 
ncatch = 8; 

nrun = 4; 

nyn = 2; ln = 2;                %yes,no %lit,nonlit
ncond = nyn*ln;                 %not including catch trial "condition"
nitemcond = nitem/ncond; 

tr = 2; 
ips = 227; 

fix1 = 12;                      %first fixation in sec

dqap = [2.7 3.8 3];             %display durations for q, a, probe, in sec
dpau = 0.25;                    %duration for small pauses b/w screens
dtrial = sum(dqap,2) + 2*dpau; 
%total trial duration = 10 sec: 2 x dpau + sum(dqap,2)

nitemrun = 24; 
ncatchrun = 2; 
ntrialrun = nitemrun+ncatchrun; 

neventrun = 52; 

%% get randseed for random number generator
hasharray = double(int8(idsub));
rng(hasharray(end),'twister');
hasharray = hasharray(randperm(length(hasharray))); 
hash = 0;
for v = 1:length(hasharray)
    hash = hash + hasharray(v)*(100^(v-1));
end
while hash > 2^32
    hash = floor(hash/(hasharray(end)+2));
end
rng(hash,'twister');

%% get stimuli
load(fullfile(rootdir,'nonlit_stim.mat'),'stim') 
% stim a 1x5 cell array with items:
% (1) nonlit-yes, (2) nonlit-no, (3) lit-yes, (4) lit-no, (5) catch trials
% cells 1:4 are 48(item)x2(q,a); cell 5 is 8(item)x3(q,a,correct_response)

if r == 1
    %% assign items to literal-nonliteral conditions
    %(nlists = 16; in 2 Ps, each item occurs as lit & nonlit once); 
    intervals = [1 2 3 4 6 8 12 24]; 
    nintervals = length(intervals)*2; 
    icolumn = [[1:2:nintervals]',[2:2:nintervals]'];
    for i = 1:length(intervals)
        condpicklist(:,icolumn(i,1)) = repmat([true(intervals(i),1); false(intervals(i),1)],intervals(end-i+1),1); 
        condpicklist(:,icolumn(i,2)) = repmat([false(intervals(i),1); true(intervals(i),1)],intervals(end-i+1),1); 
    end
    %pick an assignment order for this subject
    if subnum <= nintervals
        condpicklistPx = condpicklist(:,subnum); 
    else
        condpicklistPx = condpicklist(:,subnum-nintervals);
    end
    %get items per condition for this subject
    for i = 1:nyn
        stimPx{i} = stim{i}(condpicklistPx,:);        %literal conditions
        stimPx{i+2} = stim{i+2}(~condpicklistPx,:);   %non-literal conditions
    end
    stimPx{end+1} = stim{end};                        %add catch trials
    
    %% randomize item order & break up into runs
    %conditions
    for i = 1:ncond
        randord{1}(:,i) = randperm(size(stimPx{i},1)); 
        stimPxrun{i}(randord{1}(:,i),:) = stimPx{i}; 
        stimPxrun{i} = permute(reshape(stimPxrun{i}',[2,nitemcond/nrun,nrun]),[2 1 3]);
    end
    %catch trials
    %NOTE: I'm not balancing yes/no or lit/nonlit for catch trials
    randord{2} = randperm(size(stimPx{end},1)); 
    stimPxrun{end+1}(randord{2},:) = stimPx{end}; 
    stimPxrun{end} = permute(reshape(stimPxrun{end}',[3,ncatch/nrun,nrun]),[2 1 3]);
        
    %% counterbalance
    load(fullfile(rootdir,'nonlit_cb.mat'),'condords','runperms')
    %condords consists of 6 concatenated 4x4 latin squares, chosen to
    %maintain balanced n-1 relationships (here, conds precede self 3 times 
    %and each other cond 6 times across runs); the actual sequence used: 
    %condords = [1 4 2 3   3 2 1 4   2 3 4 1   1 4 3 2   3 2 4 1   2 3 1 4;
    %            2 1 3 4   1 3 4 2   4 2 1 3   3 1 2 4   4 3 1 2   1 2 4 3;
    %            3 2 4 1   4 1 2 3   1 4 3 2   2 3 4 1   1 4 2 3   4 1 3 2;
    %            4 3 1 2   2 4 3 1   3 1 2 4   4 2 1 3   2 1 3 4   3 4 2 1];
    
    %pick run order for this subject (i.e., order of rows 1:4 above)
    %(across 24 subjects, all orders will be presented once)
    if subnum <= length(runperms)
        icondord = runperms(subnum,:); 
    else
        icondord = runperms(subnum-length(runperms),:); 
    end
    condordPx = condords(icondord,:); 
    
    %% add catch trials & get final condition order
    %2 per run; inserted in random positions
    icatch = [true(ncatchrun,nrun); false(nitemrun,nrun)]; 
    designPx = zeros(nrun,ntrialrun); 
    for i = 1:nrun
        icatch(:,i) = icatch(randperm(ntrialrun),i);
        %update condordPx to include catch trials
        designPx(i,icatch(:,i)) = 5; 
        designPx(i,~icatch(:,i)) = condordPx(i,:); 
    end
    
    %% timing (generated with optseq2)
    % use 4 different lists (1 per run; same across subjects)
    load(fullfile(rootdir,'nonlit_timing.mat'),'schedules')
    %schedules is a 52(events)x3(onset,duration,trial/rest)x4(run) matrix
    %add first fixation
    schedules(:,1,:) = schedules(:,1,:) + fix1; 
    %add condition order for this subject
    schedPx = schedules; 
    for i = 1:nrun
        schedPx(schedPx(:,3,i) == 1,3,i) = designPx(i,:); 
    end
    
    %% interim save (crash-safe)
    save(fullfile(behavdir,sprintf('%s.prepvars.mat',idsub)),...
        'condpicklistPx','stimPx','randord','stimPxrun',...
        'icondord','condordPx','icatch','designPx','schedPx')
else
    load(fullfile(behavdir,sprintf('%s.prepvars.mat',idsub)))
end

%% keys & response variables
KbName('UnifyKeyNames');
keyresp = zeros(ntrialrun,1); 
rtresp = zeros(ntrialrun,1);

%% psychtoolbox setup
%find attached keyboard devices
PsychJavaTrouble; 
devices = PsychHID('devices');
[dev_names{1:length(devices)}] = deal(devices.usageName);
kbd_devs = find(ismember(dev_names, 'Keyboard') == 1);
%screen setup
displays = Screen('screens');   
screenRect = Screen('rect', displays(end));  
[~,~] = RectCenter(screenRect);  
window = Screen('OpenWindow', displays(end),[0 0 0], screenRect, 32);
HideCursor;

%% show instructions & wait for trigger
Screen(window,'TextSize',50); 
DrawFormattedText(window, 'Ready!','center','center',[255,255,255],40); 
Screen('Flip',window);

while 1
    FlushEvents;
    trig = GetChar;
    if trig == '+'
        break
    end
end

%% run experiment
runstart = GetSecs; 
%show first fixation
while GetSecs - runstart < fix1
    Screen(window,'TextSize',50); 
    [~,~,~] = DrawFormattedText(window, '+', 'center','center',[255,255,255],40);
    Screen('Flip',window);
end
%trials
condcount = [0 0 0 0 0];
trialcount = 0; 
trialdur = zeros(ntrialrun,1); 
restdur = zeros(ntrialrun,1); 
trialonset = zeros(ntrialrun,1); 
restonset = zeros(ntrialrun,1); 
for i = 1:neventrun
    if schedPx(i,3,r) ~= 0 %i.e., if a trial
        trialcount = trialcount + 1; 
        trialstart = GetSecs; 
        trialonset(trialcount) = trialstart - runstart; 
        condcount(schedPx(i,3,r)) = condcount(schedPx(i,3,r)) + 1; 
        thisQ = stimPxrun{schedPx(i,3,r)}{condcount(schedPx(i,3,r)),1,r};
        thisA = stimPxrun{schedPx(i,3,r)}{condcount(schedPx(i,3,r)),2,r};
        %show question
        qstart = GetSecs; 
        while GetSecs - qstart < dqap(1)
            Screen(window,'TextSize',50); 
            [~,~,~] = DrawFormattedText(window, thisQ, 'center','center',[255,255,255],40);
            Screen('Flip',window); 
        end
        %pause
        paustart = GetSecs; 
        while GetSecs - paustart < dpau
            Screen(window,'TextSize',50); 
            [~,~,~] = DrawFormattedText(window, ' ', 'center','center',[255,255,255],40);
            Screen('Flip',window); 
        end
        %show answer
        astart = GetSecs; 
        while GetSecs - astart < dqap(2)
            Screen(window,'TextSize',50); 
            [~,~,~] = DrawFormattedText(window, thisA, 'center','center',[255,255,255],40);
            Screen('Flip',window); 
        end
        %pause
        paustart = GetSecs; 
        while GetSecs-paustart < dpau
            Screen(window,'TextSize',50); 
            [~,~,~] = DrawFormattedText(window, ' ', 'center','center',[255,255,255],40);
            Screen('Flip',window); 
        end
        %display probe, get rt & key
        pstart = GetSecs;
        while GetSecs - pstart < dqap(3)
            %get rt & key
            [~,~,keycode] = KbCheck;
            button = find(keycode);
            if ~isempty(button)
                button = button(1);
                if button>29 && button<33
                    rtresp(trialcount) = GetSecs - pstart;
                    button_n1 = KbName(button);
                    keyresp(trialcount) = str2double(button_n1(1));
                end
            end
            %show probe
            Screen(window,'TextSize',50); 
            [~,~,~] = DrawFormattedText(window, 'Female                  Male', 'center','center',[255,0,0],40);
            Screen('Flip',window);
        end
        trialdur(trialcount) = GetSecs-trialstart;  %check total trial duration (for debugging)
    else %i.e., if rest
        %show fixation 
        %(until time when next trial should start rather than for fixed duration; to prevent drift)  
        reststart = GetSecs; 
        restonset(trialcount) = reststart - runstart; 
        if i < neventrun
            while GetSecs - runstart < schedPx(i+1,1,r)
                Screen(window,'TextSize',50); 
                [~,~,~] = DrawFormattedText(window, '+', 'center','center',[255,255,255],40);
                Screen('Flip',window);
            end
        else
            while GetSecs - runstart < ips*tr
                Screen(window,'TextSize',50); 
                [~,~,~] = DrawFormattedText(window, '+', 'center','center',[255,255,255],40);
                Screen('Flip',window);
            end
        end
        restdur(trialcount) = GetSecs-reststart; 
    end %trial + rest loop
end %run loop
rundur = GetSecs-runstart;

%% format SPM inputs 
%format onsets and durations
condnames = {'well_yes','well_no','lit_yes','lit_no','catch'}; 
%target trials
durcondtr = (dtrial/tr)*ones(nitemrun/ncond,1); 
onscondtr = zeros(nitemrun/ncond,ncond); 
spm_inputs = struct(); 
for i = 1:ncond
    %round (there's 0-10 msec delay per trial) & convert to TRs
    onscondtr(:,i) = floor(trialonset(designPx(r,:) == i))./2 + 1; 
    %prep for SPM
    spm_inputs(i).name = condnames{i}; 
    spm_inputs(i).ons = onscondtr(:,i); 
    spm_inputs(i).dur = durcondtr; 
end
%catch trials
onscatchtr = floor(trialonset(designPx(r,:) == 5))./2 + 1; 
durcatchtr = (dtrial/tr)*ones(ncatchrun,1); 
spm_inputs(end+1).name = condnames{end}; 
spm_inputs(end).ons = onscatchtr; 
spm_inputs(end).dur = durcatchtr; 

%specify contrasts of interest
con_info(1).name = 'well>lit'; 
con_info(1).val = [1 1 -1 -1 0]; 
con_info(2).name = 'lit>well'; 
con_info(2).val = [-1 -1 1 1 0]; 

%% save variables & close PTB window
save(fullfile(behavdir,sprintf('%s.%01d.mat',idsub,r)),...
    'rtresp','keyresp',...                                      %behavioral variables
    'trialonset','restonset','trialdur','restdur','rundur',...  %timing vars in sec
    'onscondtr','onscatchtr',...                                %timing vars in TRs
    'ips','spm_inputs','con_info')                              %info for SPM
ShowCursor;
Screen('CloseAll')

%% get behavioral results (at the end of run 4)
keycond = zeros(nitemrun/ncond,nrun,ncond); 
keycatch = zeros(ncatchrun,nrun); 
acccatch = zeros(ncatchrun,nrun); 
rtcond = zeros(nitemrun/ncond,nrun,ncond); 
rtcatch = zeros(ncatchrun,nrun); 
if r == 4
    cd(behavdir)
    for i = 1:nrun
        %load variables
        if exist(sprintf('%s.%01d.mat',idsub,i),'file') ~= 0
            load(sprintf('%s.%01d.mat',idsub,i),'rtresp','keyresp')
            %split responses & rts into conditions
            for j = 1:ncond
                keycond(:,i,j) = keyresp(designPx(i,:) == j); 
                rtcond(:,i,j) = rtresp(designPx(i,:) == j); 
            end
            keycatch(:,i) = keyresp(designPx(i,:) == 5); 
            rtcatch(:,i) = rtresp(designPx(i,:) == 5); 
        end
    end
    %replace 0s (no-response trials) with NaNs 
    keycond(keycond == 0) = NaN; 
    rtcond(rtcond == 0) = NaN; 
    keycatch(keycatch == 0) = NaN; 
    rtcatch(rtcatch == 0) = NaN; 
    %get % correct on catch trials
    corresp = squeeze(stimPxrun{5}(:,3,:)); 
    acccatch((~isnan(keycatch) & ((strcmp(corresp,'f') & keycatch == 1) | (strcmp(corresp,'f') & keycatch == 2)))) = 1; 
    acccatch(isnan(keycatch)) = NaN; 
    %concatenate runs
    keycond = reshape(keycond,nitemrun,nrun); 
    rtcond = reshape(rtcond,nitemrun,nrun); 
    rtcatch = rtcatch(:);
    acccatch = acccatch(:); 
    %get means
    propfcond = sum(keycond == 1)./sum(~isnan(keycond)); 
    avgrtcond = nanmean(rtcond); 
    avgrtcatch = nanmean(rtcatch);
    avgacccatch = nanmean(acccatch);
    %get RT std.errors (
    stertcond = nanstd(rtcond)./sqrt(sum(~isnan(rtcond))); 
    stertcatch = nanstd(rtcatch)./sqrt(sum(~isnan(rtcatch)));
    
    %% make bar graphs
    %format data
    bardata = {propfcond; avgacccatch; [avgrtcond; stertcond]; [avgrtcatch; stertcatch]}; 
    axes = [0.5 4.5 0 1; 
            0.5 1.5 0 1; 
            0.5 4.5 0 2; 
            0.5 1.5 0 2]; 
    xticks = {[1:4]; [1]; [1:4]; [1]}; 
    xticklabels = {{'well-yes','well-no','lit-yes','lit-no'},{'catch'},{'well-yes','well-no','lit-yes','lit-no'},{'catch'}}; 
    ylabels = {'proportion "female"','proportion correct','RT','RT'}; 
    %make figure with 4 subplots
    scrsz = get(0,'ScreenSize'); 
    h = figure('Position',[1 1 scrsz(3) scrsz(4)],'Color',[1 1 1]); 
    for i = 1:4
        subplot(2,2,i)
        if size(bardata{i},2) == 1
            bar(bardata{i}(1,:),'BarWidth',0.3)
            if size(bardata{i},1) == 2
                hold on
                errorbar(bardata{i}(1,:),bardata{i}(2,:),'xr')
            end
        else
            bar(bardata{i}(1,:))
            if size(bardata{i},1) == 2
                hold on
                errorbar(bardata{i}(1,:),bardata{i}(2,:),'xr')
            end
        end
        axis(axes(i,:))
        set(gca,'XTick',xticks{i})
        set(gca,'XTickLabel',xticklabels{i},'FontSize',8)
        ylabel(ylabels{i},'FontSize',8)
    end
    %save figure & close
    print(h,'-djpeg',sprintf('%s_behavior.jpg',idsub),'-painters','-r300')
    close(h)
end

end %main function