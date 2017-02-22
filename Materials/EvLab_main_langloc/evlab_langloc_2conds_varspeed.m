function evlab_langloc_2conds_varspeed_nobuttonpress(subj_id, run, do_rev_order,speed)

% THIS IS THE SAME AS THE CODE WITHOUT THE "IDAN" SUFFIX, BUT HERE NO HAND-BUTTON-PRESS ICON IS PRESENTED
% ev changed _idan to _nobuttonpress

% Created By: Terri Scott (tlscott@mit.edu)
% Date: 4/8/13

% This is a language localizer experiment with two conditions - sentences
% and nonwords. In each trial, 12 words sequences will be displayed one
% word at a time followed by a prompt for the subject to push a button, just to make sure they are paying some
% attention. 
% The subject should be instructed to read each English word or nonword and
% press a button when then image of a hand pressing a button is displayed.
% Emphasis should be placed on paying attention to reading each sequence
% and not to
% be stressed out if the sequence seems fast. 

% The trial timings are as follows: 100 ms of blank screen, 450 ms *
% 12 words for 5400 ms of stimuli, 400 ms of the button press image, and
% 100 ms of blank screen. The entire trial lasts for 6000 ms. The subject's button press for a given trial will
% be recorded if it occurs after the button press image and before the
% same image of the subsequent trial.

% 3 trials of a given condition will be grouped into a block. A run will
% consist of 16 blocks in this sequence: Fix B1 B2 B3 B4 Fix B5 B6 B7 B8
% Fix B9 B10 B11 B12 Fix B13 B14 B15 B16 Fix. Each fixation period will
% last 14000 ms. Each run is 5 minutes, 58 secs.

% Argument definitions:

% subj_id: Should be a string designating the subject.

% run: The localizer is meant to be run twice. The run is the counter-balance number, and should have the value 1
% or 2 delineating the first or second run of the experiment. The sequence
% of conditions are:
% run = 1 : SNNS - NSNS - SNSN - NSSN
% run = 2 : NSSN - SNSN - NSNS - SNNS

% do_rev_order: So that each patient doesn't see the exact same ordering of the stimuli
% do_rev_order can be specified to be 0 (use original order) or 1 (reverse
% the order. If you use 0 for the first run, be sure to keep it 0 for the
% second run.

% A structure 'subj_data' is created and saved to the pwd unless otherwise
% specified. It will be saved as a .mat in the format:
% <subj_id>_fmri_run<run#>_data.mat. 

% I've set up this script so that all the stimuli should live in the same
% directory as the script, and the saved subject data will live in a
% sub-directory called 'data'. Of course, feel free to change this however you like. 

% 5/15/13 Modified to make it easy to change the stimuli font size. See
% "Stuff to change" below. - TLS


%% Stuff to change
Screen('Preference', 'SkipSyncTests', 1)
screensAll = Screen('Screens');
screenNum = max(screensAll); % Which screen you want to use. "1" is external monitor, "0" is this screen.
my_key = '1!'; % What key gives a response.
my_trigger = '=+'; % What key triggers the script from the scanner.
do_suppress_warnings = 1; % You don't need to do this but I don't like the warning screen at the beginning.
DATA_DIR = [pwd filesep 'data']; % Where the subj_data will be saved.
STIM_DIR = [pwd]; % Where all the stimuli are.
stim_font_size = 100; % We started at 150, but that was too large on the 13" monitor.

%% Some checks to perform

file_to_save = ['kan_langloc_' subj_id '_fmri_run' num2str(run) '_data.mat']; 

% Error message if data file already exists.
if exist([DATA_DIR filesep file_to_save],'file');
    
    error('myfuns:kanwisher_langloc_2conds_main_fmri:DataFileAlreadyExists', ...
        'The data file already exists for this subject!');
end

% The second run should have the same value of do_rev_order as the first
% run for that subject and the second run should come after the first.
if run == 2,    
    if exist([DATA_DIR filesep 'kan_langloc_' subj_id '_fmri_run' num2str(1) '_data.mat'],'file'),        
        load([DATA_DIR filesep 'kan_langloc_' subj_id '_fmri_run' num2str(1) '_data.mat']);        
        if subj_data.reversed ~= do_rev_order,            
            error('myfuns:kanwisher_langloc_2conds_main_fmri:ReversalDoesntMatch',...
                'You must use the same value of do_rev_order for both runs.');
        end        
    else        
        error('myfuns:kanwisher_langloc_2conds_main_fmri:Run1DoesntExist',...
            'Run 1 does not yet exist.');
    end   
end

clear subj_data

num_of_trials = 48;
num_of_fix = 5;

%% Start experiment

% Choose speed

switch speed
    case 'fast';
        word_time = 0.450;
        trial_time = 12*word_time + 0.600;
    case 'medium';
        word_time = 0.550;
        trial_time = 12*word_time + 0.600;
    case 'slow';
        word_time = 0.700;
        trial_time = 12*word_time + 0.600;
end


% Choose which stimuli set to use.

if run == 1,
    
    if do_rev_order == 0,

    stim = load([STIM_DIR filesep 'langloc_fmri_run1_stim_v1.mat']);
    stim = stim.stim;
    
    elseif do_rev_order == 1,
        
    stim = load([STIM_DIR filesep 'langloc_fmri_run1_stim_v2.mat']);
    stim = stim.stim;
    
    end
    
elseif run == 2,    

    if do_rev_order == 0,

    stim = load([STIM_DIR filesep 'langloc_fmri_run2_stim_v1.mat']);
    stim = stim.stim;
    
    elseif do_rev_order == 1,
        
    stim = load([STIM_DIR filesep 'langloc_fmri_run2_stim_v2.mat']);
    stim = stim.stim;
    
    end
    
end    

% Load up variables needed later. 

img=imread([STIM_DIR filesep 'hand-press-button-4.jpeg'], 'JPG');

did_subj_respond = 0;
r_count = 1;

trial_times = zeros(48,1);
for i = 1:num_of_trials,
    if ismember(i,[13 25 37]),
        trial_times(i) = trial_times(i-1) + 14.000 + trial_time;
    elseif i == 1,
        trial_times(i) = 0.000;
    else
        trial_times(i) = trial_times(i-1) + trial_time;
    end
end

subj_data.id = subj_id;
subj_data.did_respond = zeros(num_of_trials,1);
subj_data.probe_onset = zeros(num_of_trials,1);
subj_data.probe_response = zeros(num_of_trials,1);
subj_data.trial_onsets = zeros(num_of_trials,1);
subj_data.fix_onsets = zeros(num_of_fix,1);
subj_data.run = run;
subj_data.reversed = do_rev_order;
subj_data.speed = speed;

% Save all data to current folder.
save([DATA_DIR filesep file_to_save], 'subj_data');

% Screen preferences

% Setting this preference to 1 suppresses the printout of warnings.
oldEnableFlag = Screen('Preference', 'SuppressAllWarnings', do_suppress_warnings);
Screen('Preference', 'TextRenderer', 0);

% Open screen.

[wPtr,~]=Screen('OpenWindow',screenNum,1);
white=WhiteIndex(wPtr);
Screen('FillRect',wPtr,white);
Screen(wPtr, 'Flip');

HideCursor;

Screen('TextSize', wPtr , 100);
DrawFormattedText(wPtr,'Waiting for trigger...','center','center');
Screen(wPtr, 'Flip');

% Pre-draw button press image
textureIndex=Screen('MakeTexture', wPtr, double(img));

% Get trigger from scanner.


%%% In case the triggering doesn't work, try un-commenting this and
%%% commenting out the part below (Idan Blank, Jan 06 2014)
TRIGGER_KEY = [KbName('=+'),KbName('+'),KbName('=')];; % ** AK changed this 081612 % if this doesn't work, change to '=+'
while 1
    [keyIsDown, seconds, keyCode] = KbCheck(-3);
%     if keyCode(ESCAPE_KEY)
%         Screen('CloseAll');
%         fprintf('Experiment quit by pressing ESCAPE\n');
%         break;
    if ismember(find(keyCode,1),TRIGGER_KEY) %keyCode(KbName(TRIGGER_KEY))
        break
    end
    WaitSecs('YieldSecs', 0.0001); % Wait for yieldInterval to prevent system overload.
end

%%% If trigerring doesn't work, try commenting-out the part below and
%%% un-commenting the part above (Idan Blank, Jan 06 2014)
% while 1,
%     [keyIsDown,x,keyCode]=KbCheck;
%     if keyIsDown
%         response=find(keyCode);
%         if response==KbName(my_trigger);
%             break;
%         end
%     end
%     % Wait for yieldInterval to prevent system overload.
%     WaitSecs('YieldSecs', 0.0001);
% end

subj_data.run_onset = GetSecs;

%% Runs

try

% Fixation

Screen('TextSize', wPtr , 100);
DrawFormattedText(wPtr,'+','center','center');
Screen(wPtr, 'Flip');

subj_data.fix_onsets(1) = GetSecs;

% Calculate trial onsets:

subj_data.i_trial_onsets = (subj_data.run_onset+14.000) + trial_times;

while GetSecs<14.000+subj_data.run_onset
    WaitSecs('YieldSecs', 0.0001);
end

% Start trials

for i = 1:num_of_trials
    
    subj_data.trial_onsets(i) = GetSecs;
    
    stim_seq = stim(i,2:13);
    
    % White screen for 100 ms
    
    white=WhiteIndex(wPtr);
    Screen('FillRect',wPtr,white);
    Screen(wPtr, 'Flip');
    
    while GetSecs<0.100+subj_data.i_trial_onsets(i)
        if did_subj_respond == 0,
            did_subj_respond = getKeyResponse;           
        end
        WaitSecs('YieldSecs', 0.0001);
    end
    
    % Sequence presentation 12 * 450 ms
    
    Screen('TextSize', wPtr , stim_font_size);
    
    for j = 1:12,
       
        DrawFormattedText(wPtr,stim_seq{j},'center','center');
        Screen(wPtr, 'Flip');
        
        while GetSecs<word_time*j + 0.100 + subj_data.i_trial_onsets(i)
            if did_subj_respond == 0,
                did_subj_respond = getKeyResponse;           
            end
            WaitSecs('YieldSecs', 0.0001);
        end
    end
    
    % Present image for 400 ms
    
    subj_data.did_respond(r_count) = did_subj_respond;
    
    if i ~= 1,
         r_count = r_count + 1;
    end
    
    did_subj_respond = 0;
         
    Screen('DrawTexture', wPtr, textureIndex);
    Screen(wPtr, 'Flip');
    
    subj_data.probe_onset(i) = GetSecs;
    
    while GetSecs<0.400+(12*word_time)+0.100+subj_data.i_trial_onsets(i)
        if did_subj_respond == 0,
            did_subj_respond = getKeyResponse;
        end
        WaitSecs('YieldSecs', 0.0001);
    end
    
    % White screen for 100 ms
    
    Screen('FillRect',wPtr,white);
    Screen(wPtr, 'Flip');
    
    while GetSecs<0.100+0.400+(12*word_time)+0.100+subj_data.i_trial_onsets(i)
        if did_subj_respond == 0,
            did_subj_respond = getKeyResponse;
        end
        WaitSecs('YieldSecs', 0.0001);
    end
    
    if ismember(i,[12,24,36,48]), % Fixation occurs after every 12 trials or 4 blocks
        
        % Fixation
        
        Screen('TextSize', wPtr , 100);
        DrawFormattedText(wPtr,'+','center','center');
        Screen(wPtr, 'Flip');
        
        subj_data.fix_onsets(i/12+1) = GetSecs;
        
        while GetSecs<14.000+0.100+0.400+(12*word_time)+0.100+subj_data.i_trial_onsets(i)
            if did_subj_respond == 0,
                did_subj_respond = getKeyResponse;
            end
            WaitSecs('YieldSecs', 0.0001);
        end
        
    end   
end

subj_data.runtime = GetSecs - subj_data.run_onset;

subj_data.did_respond(r_count) = did_subj_respond;

Screen('CloseAll');
ShowCursor

% Get reaction time.
subj_data.rt = zeros(num_of_trials,1);
responses = find(subj_data.did_respond);
subj_data.rt(responses) = subj_data.probe_response(responses) - subj_data.probe_onset(responses);

% Save all data to current folder.
save([DATA_DIR filesep file_to_save], 'subj_data');

catch err
    
    subj_data.did_respond(r_count) = did_subj_respond;
    
    Screen('CloseAll');
    ShowCursor
    
    % Get reaction time.
    subj_data.rt = zeros(num_of_trials,1);
    responses = find(subj_data.did_respond);
    subj_data.rt(responses) = subj_data.probe_response(responses) - subj_data.probe_onset(responses);
    
    % Save all data to current folder.
    save([DATA_DIR filesep file_to_save], 'subj_data','err');
    
    
end

% At the end of your code, it is a good idea to restore the old level.
Screen('Preference','SuppressAllWarnings',oldEnableFlag);



%%
% % % % % % % %
% SUBFUNCTION %
% % % % % % % %

    function out = getKeyResponse
        KEY1=KbName(my_key);
        
        [keyIsDown,x,keyCode]=KbCheck;
        if keyIsDown
            response=find(keyCode);
            if response==KEY1
                out = 1;
                subj_data.probe_response(r_count) = x;
            else
                out = 0;
            end
        else
            out = 0;
        end
    end
end