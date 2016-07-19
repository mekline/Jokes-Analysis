function arithmeticTask(subjid)

%%% This function is for running the experiment while scanning in fMRI %%% 
% SUBJID: subject id
% Author of original code (story experiment): Eyal Dechter, 08/27/2010
% Edited (arithmetic task): Idan Blank, 06/28/2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% FOR TESTING:
%clear all
%subjid = 'test_subject01';
%story_number = 5; 

%% Initialize Variables
STIM_DIRECTORY = 'Arithmetic_July2014';
STIM_NAME = 'arithmeticData';

% durations:
PRETRIAL_FIXATION_DUR = 16.00; % in seconds
POSTTRIAL_FIXATION_DUR = 16.00; % in seconds

% other variables
RESPONSE_MAP.Left = '1';
RESPONSE_MAP.Right = '2';
STIMULUS_FONT_SIZE = 100;   % in pixels
% FIXATION_SIZE = 2; % in degrees

% pixels per degrees
PIX_PER_DEG = 60;

% screen variables
SCREEN_NUM = 0;

% Escape Key
ESCAPE_KEY = KbName('ESCAPE');

% Set up datafile name
DATADIR = './data';
DATAFILE = [DATADIR '/' subjid '_arithmeticStim.txt'];
RESPONSEFILE = [DATADIR '/' subjid '_arithmeticResponses.txt'];

%% Load any mex files by calling them once (to eliminate loading time later)
WaitSecs(0);

%% Get filename of stimulus file
load(STIM_NAME)
stimuli.durations = cell2mat(stimuli.durations);

%% generate stimulus sets
STIMULUS_SET = {};
t = 0;
pretrial_stim = struct();
t2 = t + PRETRIAL_FIXATION_DUR;
pretrial_stim.start_time = t;
pretrial_stim.end_time = t2;
t = t2;
pretrial_stim.takes_response = 0;
pretrial_stim.type = 'pretrial';
STIMULUS_SET{end+1} = pretrial_stim;

nTrials = stimuli.trial{end};
for nInd=1:length(stimuli.numbers)
    visual_stim = struct();
    t2 = t + stimuli.durations(nInd);
    visual_stim.start_time = t;
    visual_stim.end_time = t2;
    t = t2;
    if sum(stimuli.color{nInd} == [0 255 0]) == 3
        visual_stim.takes_response = 1;
    else
        visual_stim.takes_response = 0;
    end
    visual_stim.color = stimuli.color{nInd};
    visual_stim.trial = stimuli.trial{nInd};
    visual_stim.type = 'visual';
    visual_stim.stim = stimuli.numbers{nInd};
    STIMULUS_SET{end+1} = visual_stim;
end

posttrial_stim = struct();
t2 = t + POSTTRIAL_FIXATION_DUR;
posttrial_stim.start_time = t;
posttrial_stim.end_time = t2;
t = t2;
posttrial_stim.takes_response = 0;
posttrial_stim.type = 'posttrial';
STIMULUS_SET{end+1} = posttrial_stim;

final_stim = struct();
t2 = t;
final_stim.start_time = t;
final_stim.end_time = t2;
final_stim.type = 'end run';
STIMULUS_SET{end+1} = final_stim;

NUM_STIMULI = length(STIMULUS_SET);


%% Initialize Data Recorder
data_fid = fopen(DATAFILE, 'w');
fprintf(data_fid, 'subject, onset time (ms), stimulus \n');
DATA_FORMAT_STRING = '%s \t %6.3f \t %s\n';

response_fid = fopen(RESPONSEFILE, 'w');
fprintf(response_fid, ...
    'subject, Trial end time, trial number, response, RT (ms) \n');
RESPONSE_FORMAT_STRING = '%s, %f, %d, %s, %6.3f\n';

subj_data = struct();
subj_data.id = subjid;
subj_data.stimOnsets = zeros(NUM_STIMULI-3,1);
subj_data.trialEndTimes = zeros(nTrials,1);
subj_data.response = cell(nTrials,1);
subj_data.RT = zeros(nTrials,1);


%% Initialize Window
[WINDOW_PTR,rect]=Screen('OpenWindow',SCREEN_NUM);
Screen('TextFont',WINDOW_PTR,'Helvetica');
HideCursor;

%% Wait for trigger
TRIGGER_KEY = [KbName('=+'), KbName('+'), KbName('=')]; % ** AK changed this 081612 % if this doesn't work, change to '=+'
Screen('TextSize',WINDOW_PTR,STIMULUS_FONT_SIZE);
DrawFormattedText(WINDOW_PTR, 'Waiting for trigger.', 'center', 'center', 0);
Screen('Flip', WINDOW_PTR);
% while 1
%     [keyIsDown, seconds, keyCode] = KbCheck(-3);    % -3 = check input from ALL devices
%     if keyCode(ESCAPE_KEY)
%         Screen('CloseAll');
%         fprintf('Experiment quit by pressing ESCAPE\n');
%         break;
%     elseif ismember(find(keyCode,1), TRIGGER_KEY); % used to be: keyCode(KbName(TRIGGER_KEY))
%         break
%     end
%     WaitSecs('YieldSecs', 0.0001); % Wait for yieldInterval to prevent system overload.
% end


%% Start Experiment
experimentStartTime = GetSecs();    % used to be: EXPERIMENT_START_TIME = GetSecs();
tic


%% show stimuli
Screen('TextSize',WINDOW_PTR,STIMULUS_FONT_SIZE);
stimInd = 1;
current = 1;
taskStarted = 0;
numberInd = 1;

while current <= NUM_STIMULI
    if GetSecs() - experimentStartTime > STIMULUS_SET{stimInd}.start_time
        current = stimInd;
        switch STIMULUS_SET{current}.type
            case 'pretrial'
                DrawFormattedText(WINDOW_PTR, '+', 'center', 'center', 0);
                Screen('Flip',WINDOW_PTR);
                
            case 'visual'
                DrawFormattedText(WINDOW_PTR, STIMULUS_SET{current}.stim, 'center', 'center', STIMULUS_SET{current}.color);
                if ~taskStarted
                    taskStarted = 1;
                end
                if STIMULUS_SET{current}.takes_response
                    waiting_for_response = 1;
                else
                    waiting_for_response = 0;
                end
                Screen('Flip',WINDOW_PTR);
                subj_data.stimOnsets(numberInd) = GetSecs();
                if STIMULUS_SET{current}.takes_response
                    subj_data.trialEndTimes(STIMULUS_SET{current}.trial) = GetSecs();
                end
                numberInd = numberInd+1;
                
            case 'posttrial'
                DrawFormattedText(WINDOW_PTR, '+', 'center', 'center', 0);
                Screen('Flip',WINDOW_PTR);

            case 'end run'
                fprintf('Total Run Time in Seconds: %f\n', toc);
                Screen('CloseAll');
                break
        end
        stimInd = stimInd + 1;        
    end
    
    
    %% Record user responses
    % Check the state of the keyboard.
    [keyIsDown, seconds, keyCode] = KbCheck(-3);    % -3 = check input from ALL devices
    
    % If the user is pressing a key, then display its code number and name.
    if keyIsDown
        % Note that we use find(keyCode) because keyCode is an array.
        % See 'help KbCheck'
        key_name = KbName(keyCode);

        if strcmp(STIMULUS_SET{current}.type,'visual') && waiting_for_response == 1
            if strcmp(key_name(1),RESPONSE_MAP.Left)
                subj_data.response{STIMULUS_SET{current}.trial} = '1';
                subj_data.RT(STIMULUS_SET{current}.trial) = ...
                    seconds - subj_data.trialEndTimes(STIMULUS_SET{current}.trial);
                waiting_for_response = 0;
            elseif strcmp(key_name(1), RESPONSE_MAP.Right)
                subj_data.response{STIMULUS_SET{current}.trial} = '2';                
                subj_data.RT(STIMULUS_SET{current}.trial) = ...
                    seconds - subj_data.trialEndTimes(STIMULUS_SET{current}.trial);
                waiting_for_response = 0;
            end
        end
        if keyCode(ESCAPE_KEY)
            Screen('CloseAll');
            fprintf('Experiment quit by pressing ESCAPE\n');
            break;
        end

    end
    WaitSecs('YieldSecs', 0.0001);
end

Screen('CloseAll')
ShowCursor;


%% Record RTs and responses in subj_data
subj_data.experimentStartTime = experimentStartTime;
for tInd = 1:nTrials
    subj_data.trialEndTimes(tInd) = subj_data.trialEndTimes(tInd) - subj_data.experimentStartTime;
end

for nInd = 1:length(subj_data.stimOnsets)
    subj_data.stimOnsets(nInd) = subj_data.stimOnsets(nInd) - subj_data.experimentStartTime;
end

for nInd = 1:length(subj_data.stimOnsets)
    fprintf(data_fid, DATA_FORMAT_STRING, ...
            subjid, ...
            subj_data.stimOnsets(nInd), ...
            stimuli.numbers{nInd});
end

for tInd = 1:length(subj_data.response)
    fprintf(response_fid, RESPONSE_FORMAT_STRING, ...
            subjid, ...
            subj_data.trialEndTimes(tInd), ...
            tInd, ...
            subj_data.response{tInd}, ...
            subj_data.RT(tInd));    
end

fclose(data_fid)
fclose(response_fid)

DATADIR = [pwd, '/data'];
fileName = [DATADIR, '/', subjid, '_arithmetic'];
save(fileName, 'subj_data');


%% Plot the difference between the intended and actual stimulus onsets
intendedOnsets = (cell2mat(stimuli.onsets))';
actualOnsets = subj_data.stimOnsets;
cnst = actualOnsets(1)-intendedOnsets(1);
intendedOnsets = intendedOnsets+cnst;
figure(1)
clf reset
plot(intendedOnsets, actualOnsets, '.b');
hold on
plot([min(intendedOnsets), max(intendedOnsets)], [min(intendedOnsets), max(intendedOnsets)], '-r');
xlabel('intended word Onsets');
ylabel('actual word Onsets');



%% Function definitions for sending trigger pulses

    function [device_index, device] = initialize_trigger()
        Devices = PsychHID('Devices');
        for i = 1:length(Devices)
            D = Devices(i);
            if strcmp(D.product,USB_DEVICE_NAME)
                device = D;
                device_index = i;
                DaqDConfigPort(i, PORT, 0); % configure device on port to be output
                break
            end            
        end
    end

    function send_one_trigger()
        t = GetSecs - experimentStartTime;
        DaqDOut(DEVICE_INDEX, PORT, 1);
        WaitSecs(TRIGGER_DUR);
        DaqDOut(DEVICE_INDEX, PORT, 0);
        
        % record trigger
        fprintf(PULSE_FID, '%f\n', t)  
    end

    function send_trigger(condition)
        switch condition
            case 'run start'
                trig_reps = NUM_TRIG_BEGIN_RUN;
            case 'story start'
                trig_reps = NUM_TRIG_STORY_START; 
            case 'story rep'
                trig_reps = NUM_TRIG_EVERY_5_SECONDS;
            case 'story end'
                trig_reps = NUM_TRIG_STORY_END;
            case 'question start'
                trig_reps = NUM_TRIG_QUESTION_START; 
            case 'end run'
                trig_reps = NUM_TRIG_END_RUN;
        end
        for T = 1:trig_reps
            send_one_trigger()
            WaitSecs(INTER_TRIGGER_DUR);
        end
    end

end    