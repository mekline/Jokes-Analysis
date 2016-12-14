function fb_sad3(subjID, time, run)
% fb_sad(subjID, time, run)
%
% E.G., fb_sad('SAX_sad_01', 1, 1)
%
% subjID: 'SAX_sad_[#]'
% time: 1 for pre-treatment, 2 for post-treatment
% run: acquisition counter
%
% Conditions:
% 1 - Belief (1:24)
% 2 - Photo (25:48)
%
% NOTE: actual stories being used are [1:4 7:16 19:28 31:40 43:48]
%
% Run Timing:
% 10 * (12 + 14) + 12 = 272s | 136ips
%
% Directory Structure:
% - Folder on desktop named fb_sad required. Within that folder, another
% folder for behavioural and stimuli.
%
% DDF, 12/18/09
%% This is the optimized version of fb_sad.

%% Directories and Experiment Parameters
rootdir = '/Users/Shared/Experiments/ev/0_LOCALIZERS/fb_sad';
txt_dir = fullfile(rootdir,'text_files');
designs = [1 2 2 1 2 1 2 1 1 2; 2 1 2 1 1 2 2 1 2 1]; 
design = designs(run,:);
conds = {'belief','photo'};

if time == 1 
    stories_belief = [1 20 4 19 9]; %%If we want to use two runs then these matrices should be 2x5 instead of 1x5!!!!!
    stories_photo = [44 43 28 48 40];
else
    stories_belief = [2 14 24 21 3];
    stories_photo = [27 39 26 31 33];
end

fixDuration = 12;
storyDur = 10;
questDuration = 4;
trialsPerRun = 10;
key = zeros(trialsPerRun,1);
RT = zeros(trialsPerRun,1);
items = zeros(trialsPerRun,1);

%% PTB, Instructions and Trigger
% Identify attached keyboard devices:
%  devices=PsychHID('devices');
%  [dev_names{1:length(devices)}]=deal(devices.usageName);
%  kbd_devs = find(ismember(dev_names, 'Keyboard')==1);

cd(txt_dir);
HideCursor;
screens = Screen('Screens');
screenNumber = max(screens);  %Highest screen number is most likely correct display

Screen('Preference', 'SkipSyncTests', 1);
screenRect = Screen('rect',screenNumber);
[x0,y0] = RectCenter(screenRect); %sets Center for screenRect (x,y)
window=Screen(screenNumber, 'OpenWindow', [255 255 255], screenRect, 32);

Screen(window,'TextFont','Times New Roman');
Screen(window, 'TextSize', 50);
task = sprintf('True or False');
Screen(window, 'DrawText',task, x0-125, y0-60, [0]);
instr_1 = sprintf('Press left button (1) for "True"');
Screen(window, 'DrawText',instr_1, x0-300, y0, [0]);
instr_2 = sprintf('Press right button (2) for "False"');
Screen(window, 'DrawText',instr_2, x0-300, y0+60, [0]);
Screen('Flip',window);

while 1  % wait for the 1st trigger pulse
    FlushEvents;
    trig = GetChar;
    if trig == '+'
        break
    end
end

%% Main Experiment
counter = zeros(1,2);
experimentStart = GetSecs;

for trial = 1:trialsPerRun
    trialStart = GetSecs;
    cd(txt_dir);
    empty_text = ' ';
    Screen('DrawText',window, empty_text, x0, y0);
    Screen('Flip',window);
    counter(1,design(trial)) = counter(1,design(trial)) + 1;
    storyname = sprintf('%d_story.txt',eval(sprintf('stories_%s(%d,%d)',char(conds(design(trial))),run,counter(1,design(trial))))); %%Will not run run #2 b/c stories_xxx is only 1x5 and it wants to use the second row... 
    questname = sprintf('%d_question.txt',eval(sprintf('stories_%s(%d,%d)',char(conds(design(trial))),run,counter(1,design(trial)))));
    
    Screen(window, 'TextSize', 50);
    textfid = fopen(storyname); %opens story-file to read and puts that information in textfid
    lCounter = 1; % y-axis: where text is presented
    while 1 % Run to eof
        tline = fgetl(textfid); % gets line from textfile
        if ~ischar(tline), break, end
        Screen(window, 'DrawText',tline, x0-520, y0-160 + lCounter*45,[0]); %shows lines from textfile
        lCounter = lCounter + 1; %pushes to next line
    end
    fclose(textfid);
    while GetSecs - trialStart < fixDuration; end % fixation wait loop
    Screen('Flip',window);

    textfid = fopen(questname); %opens story-file to read and puts that information in textfid
    lCounter = 1; % y-axis: where text is presented
    while 1 %Run to eof
        tline = fgetl(textfid);
        Screen(window, 'DrawText',tline, x0-440, y0-160 + lCounter*45,[0]); %shows lines from textfile
        if isempty(tline)
            tline_q = sprintf('(1) True        (2) False'); 
            Screen(window, 'DrawText',tline_q, x0-440, y0-160 + (lCounter+1)*40,[0]); %shows lines from textfile
            break
        end
        lCounter = lCounter + 1; %pushes to next line
    end
    fclose(textfid);
    
    while GetSecs - trialStart < fixDuration + storyDur; end % story wait loop
    Screen('Flip',window);
    responseStart = GetSecs;
    
    % Collect Response
    while (GetSecs - responseStart) < questDuration
        [keyIsDown,secs,keyCode] = KbCheck; %1 for upstairs, end for the scanner
        button = intersect([97:100], find(keyCode)); % 89:92
        if(RT(trial,1) == 0) & button > 96 % 88
            RT(trial,1) = GetSecs - responseStart;
            key(trial,1) = str2num(KbName(button));
        end
    end

    items(trial,1) = eval(sprintf('stories_%s(%d,%d)',char(conds(design(trial))),run,counter(1,design(trial))));
    
    cd(fullfile(rootdir,'behavioural'));
    if time == 1
        save([subjID '.fb_sad_pre.' num2str(run) '.mat'],'subjID','run','design','items','stories_belief','stories_photo','key','RT');
    else
        save([subjID '.fb_sad_post.' num2str(run) '.mat'],'subjID','run','design','items','stories_belief','stories_photo','key','RT');
    end
	
end % trial loop

empty_text = ' ';
Screen('DrawText',window, empty_text, x0, y0);
Screen('Flip',window);

trials_End = GetSecs; % add an extra 12 sec fix
while GetSecs - trials_End < fixDuration
end

experimentEnd = GetSecs;
experimentDuration = experimentEnd - experimentStart;

%% SPM Inputs and Save
ips = 136;
numconds = 2;
condnames = {'belief','photo'};
realonsets = [7 20 33 46 59 72 85 98 111 124]';
sortedonsets = sortrows([[design]' realonsets]);
for index = 1:numconds
    spm_inputs(index).name = condnames{index};
    spm_inputs(index).ons = sortedonsets(find(sortedonsets(:,1)==index),2);
    spm_inputs(index).dur = ones(trialsPerRun / numconds,1) * ((storyDur + questDuration) / 2);
end

con_info(1).name = 'belief > photo';
con_info(1).vals = [1 -1];
con_info(2).name = 'photo > belief';
con_info(2).vals = [-1 1];

responses = sortrows([design' items key RT]);

cd(fullfile(rootdir,'behavioural'));
if time == 1
    save([subjID '.fb_sad_pre.' num2str(run) '.mat'],'subjID','time','run','design','items','stories_belief','stories_photo','key','RT','responses','experimentDuration','ips','spm_inputs','con_info');
else
    save([subjID '.fb_sad_post.' num2str(run) '.mat'],'subjID','time','run','design','items','stories_belief','stories_photo','key','RT','responses','experimentDuration','ips','spm_inputs','con_info');
end

ShowCursor;
Screen('CloseAll');
clear all
end  %main function
