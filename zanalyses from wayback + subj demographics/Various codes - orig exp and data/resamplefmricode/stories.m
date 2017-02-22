function stories(subjid, story_number, USE_TTL)

%%% This function is for running the experiment while scanning in fMRI %%% 
% SUBJID: subject id
% STORY_NUMBER: integer representing which story is used. 
%
% USE_TTL: (default: true), (0/1) 0 -> no TTL; 1-> TTL pulses activated.
% Author: Eyal Dechter
% Date: 8/27/2010
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% FOR TESTING:
%clear all
%subjid = 'test_subject01';
%story_number = 5; 
%USE_TTL = 0;

%% Initialize Variables
% STORIES_DIRECTORY = 'STORIES';
STORIES_DIRECTORY = 'AudioFiles';

% durations:
PRETRIAL_FIXATION_DUR = 16.00; % in seconds
POSTTRIAL_FIXATION_DUR = 16.00; % in seconds
QUESTION_DUR = 4.00; % in seconds

% other variables
FIXATION_SIZE = 2; % in degrees
RESPONSE_MAP.Left = '1';
RESPONSE_MAP.Right = '2';
STIMULUS_FONT_SIZE = .4; % in degrees
INSTRUCTION_FONT_SIZE = .7;

% TTL variables
TRIGGER_DUR = .010; % in seconds
INTER_TRIGGER_DUR = .100; % in seconds
NUM_TRIG_BEGIN_RUN = 4; % pulses
NUM_TRIG_AUDIO_START = 1; % pulses
NUM_TRIG_EVERY_5_SECONDS = 1; % pulses
NUM_TRIG_AUDIO_END = 2; % pulses
% NUM_TRIG_QUESTION_START = 3; 
NUM_TRIG_END_RUN = 4;
if ~exist('USE_TTL')
    USE_TTL = 1;
end


% Initialize USB Device
if USE_TTL
    PORT = 0;
    USB_DEVICE_NAME = 'USB-1208FS';
    [DEVICE_INDEX, DEVICE] = initialize_trigger();
end

% pixels per degrees
PIX_PER_DEG = 60;

% screen variables
SCREEN_NUM = 0;



% QUESTIONS
questions_per_story = 6;
QUESTIONS_FILE = 'questions_clean.txt';
ANSWERS1_FILE = 'answers1.txt';
ANSWERS2_FILE = 'answers2.txt';
fid_q = fopen(QUESTIONS_FILE);
fid_a1 = fopen(ANSWERS1_FILE);
fid_a2 = fopen(ANSWERS2_FILE);
Line = 0;
QUESTIONS = {};
ANSWERS = {};
line_num = 0;
question_numbers = (questions_per_story * (story_number - 1) + 1) : (questions_per_story * story_number);
question = 0;
while question ~= -1
    question = fgets(fid_q);
    answer1 = fgets(fid_a1);
    answer2 = fgets(fid_a2);
    line_num = line_num + 1;
    if ~isempty(find(question_numbers==line_num,1))
        QUESTIONS{end + 1} = strtrim(question);
        ANSWERS(end + 1, :) = strtrim({answer1, answer2});

    end
end

NUM_QUESTIONS = length(QUESTIONS);

% Escape Key
ESCAPE_KEY = KbName('ESCAPE');

% Set up datafile name
DATADIR = './data';
DATAFILE = [DATADIR '/' subjid 'story' num2str(story_number) '_data.txt'];


PULSE_DIR = './pulses';
PULSE_FILE = [PULSE_DIR '/' subjid 'story' num2str(story_number) '_pulses.txt'];

%% Initialize Pulse Recorder
PULSE_FID = fopen(PULSE_FILE, 'w');

% if ~USE_TTL
%     fprintf(PULSE_FID, '%s\n', 'No pulses recorded, since USB DEVICE disconnected.' )
% end


%% Load any mex files by calling them once (to eliminate loading time
%% later)
WaitSecs(0);

%% Initialize some arrays
RESPONSES = cell(NUM_QUESTIONS, 1);
RTs = nan(NUM_QUESTIONS, 1);

%% Get filename of audio file
wavfilename = sprintf('./%s/%d.wav', STORIES_DIRECTORY, story_number);

%% Load in audio file and initialize audio
[y, freq, nbits] = wavread(wavfilename);
wavedata = y';
nrchannels = size(wavedata,1); % Number of rows == number of channels.
AUDIO_DUR = length(y)/freq;


% PAD AUDIO_DUR to be multiple of 2 seconds
AUDIO_DUR = AUDIO_DUR + rem((2.0-rem(AUDIO_DUR,2)),2);

% Perform basic initialization of the sound driver:
InitializePsychSound;

% Open the default audio device [], with default mode [] (==Only playback),
% and a required latencyclass of zero 0 == no low-latency mode, as well as
% a frequency of freq and nrchannels sound channels.
% This returns a handle to the audio device:
pahandle = PsychPortAudio('Open', [], [], 0, freq, nrchannels);

% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', pahandle, wavedata);



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

audio_stim = struct();
t2 = t + AUDIO_DUR;
audio_stim.start_time = t;
audio_stim.end_time = t2;
t = t2;
audio_stim.takes_response = 0;
audio_stim.type = 'audio';
STIMULUS_SET{end+1} = audio_stim;

posttrial_stim = struct();
t2 = t + POSTTRIAL_FIXATION_DUR;
posttrial_stim.start_time = t;
posttrial_stim.end_time = t2;
t = t2;
posttrial_stim.takes_response = 0;
posttrial_stim.type = 'posttrial';
STIMULUS_SET{end+1} = posttrial_stim;

for i=1:NUM_QUESTIONS
    question_stim = struct();
    t2 = t + QUESTION_DUR;
    question_stim.start_time = t;
    question_stim.end_time = t2;
    t = t2;
    question_stim.takes_response = 1;
    question_stim.question = QUESTIONS{i};
    question_stim.answers = abs([0 1] - (rand>.5));
    I = find(question_stim.answers);
    options = ['1', '2'];
    question_stim.correct_response = options(I);
    question_stim.choices = ANSWERS(i, question_stim.answers + 1);
    question_stim.type = 'question';
    question_stim.question_number = i;
    STIMULUS_SET{end+1} = question_stim;
end

final_stim = struct();
t2 = t;
final_stim.start_time = t;
final_stim.end_time = t2;
final_stim.type = 'end run';
STIMULUS_SET{end+1} = final_stim;

NUM_STIMULI = length(STIMULUS_SET);


%% Initialize Data Recorder
fid = fopen(DATAFILE, 'w');
fprintf(fid, 'subject, story number, onset time (ms), question number, question, response, correct response, accuracy, RT (ms) \n');
DATA_FORMAT_STRING = '%s,%d,%f, %d,%s,%s, %s, %d, %f\n';


%% Initialize Window
[WINDOW_PTR,rect]=Screen('OpenWindow',SCREEN_NUM);
Screen('TextFont',WINDOW_PTR, 'Helvetica');
Screen('TextSize',WINDOW_PTR, STIMULUS_FONT_SIZE*PIX_PER_DEG);


%% Wait for trigger
TRIGGER_KEY = [KbName('=+'), KbName('+'), KbName('=')]; % ** AK changed this 081612 % if this doesn't work, change to '=+'
DrawFormattedText(WINDOW_PTR, 'Waiting for trigger.', 'center', 'center', 0);
Screen('Flip', WINDOW_PTR);
while 1
    [ keyIsDown, seconds, keyCode ] = KbCheck(-3);  % -3 = check input from ALL devices
    if keyCode(ESCAPE_KEY)
        Screen('CloseAll');
        fprintf('Experiment quit by pressing ESCAPE\n');
        break;
    elseif ismember(find(keyCode,1), TRIGGER_KEY) % used to be: keyCode(KbName(TRIGGER_KEY))
        break
    end
end


%% Start Experiment
% send out start ttl pulse to notify experiment is starting
EXPERIMENT_START_TIME = GetSecs();
tic
% if USE_TTL; send_trigger('run start'); end;

%% show stimuli
N = 1;
current_question = 1;
current = 1;
question_number = 0;

while current <= NUM_STIMULI
    if GetSecs() - EXPERIMENT_START_TIME > STIMULUS_SET{N}.start_time
        current = N;
        switch STIMULUS_SET{current}.type
            case 'pretrial'
                
                DrawFormattedText(WINDOW_PTR, '+', 'center', 'center', 0);
                if USE_TTL;send_trigger('run start');end;
                Screen('Flip',WINDOW_PTR);
            case 'audio'
                DrawFormattedText(WINDOW_PTR, '+', 'center', 'center', 0);
                Screen('Flip',WINDOW_PTR);
                if USE_TTL;send_trigger('audio start');end;

                audio_start_time = PsychPortAudio('Start', pahandle, 1, 0, 1);
                num_rep = 1;
            case 'posttrial'

                PsychPortAudio('Stop', pahandle);
                if USE_TTL;send_trigger('audio end');end;
                Screen('Flip',WINDOW_PTR);

            case 'question'
                question_number = STIMULUS_SET{current}.question_number;
                waiting_for_response = 1;
                
                boundrect_choice1 = Screen('TextBounds', WINDOW_PTR, STIMULUS_SET{current}.choices{1});
                boundrect_choice2 = Screen('TextBounds', WINDOW_PTR, STIMULUS_SET{current}.choices{2});
   
                choice_y = 1/2 * rect(4);

                DrawFormattedText(WINDOW_PTR, STIMULUS_SET{current}.question, ...
                    'center', rect(4) * 1/3, 0);
                DrawFormattedText(WINDOW_PTR, [ '(1): ' STIMULUS_SET{current}.choices{1} ], ...
                    rect(3)/2 - boundrect_choice1(3)/2, choice_y,  0);
                DrawFormattedText(WINDOW_PTR, [ '(2): ' STIMULUS_SET{current}.choices{2} ], ...
                    rect(3)/2 - boundrect_choice2(3)/2, choice_y + 40, 0);
                Screen('Flip',WINDOW_PTR);
%                 if USE_TTL;send_trigger('question start');end;
                
            case 'end run'
                record_data_row();
                if USE_TTL;send_trigger('end run');end;
                fprintf('Total Run Time in Seconds: %f\n', toc);
                Screen('CloseAll');
                return;
        end
        N = N + 1;
        
        record_data_row();
    end
    
    if USE_TTL; 
       if strcmp(STIMULUS_SET{current}.type, 'audio')
           if GetSecs-audio_start_time > 5*num_rep 
                send_trigger('audio rep')
                num_rep = num_rep + 1;
           end
       end
    end
    
    % Record user responses
    % Check the state of the keyboard.
    [ keyIsDown, seconds, keyCode ] = KbCheck(-3);  % -3 = check input from ALL devices
    
    
    % If the user is pressing a key, then display its code number and name.
    if keyIsDown
        % Note that we use find(keyCode) because keyCode is an array.
        % See 'help KbCheck'
        key_name = KbName(keyCode);

        if strcmp(STIMULUS_SET{current}.type,'question') && waiting_for_response == 1
            if strcmp(key_name(1),RESPONSE_MAP.Left)
                RESPONSES{STIMULUS_SET{current}.question_number} = '1';
                RTs(STIMULUS_SET{current}.question_number) = seconds - (EXPERIMENT_START_TIME + STIMULUS_SET{current}.start_time);
                waiting_for_response = 0;
            elseif strcmp(key_name(1), RESPONSE_MAP.Right)
                RESPONSES{STIMULUS_SET{current}.question_number} = '2';
                RTs(STIMULUS_SET{current}.question_number) = seconds - (EXPERIMENT_START_TIME + STIMULUS_SET{current}.start_time);
                waiting_for_response = 0;
            end
        end
        if keyCode(ESCAPE_KEY)
            Screen('CloseAll');
            PsychPortAudio('Close' );
            fprintf('Experiment quit by pressing ESCAPE\n');
            break;
        end

    end
end

fclose(PULSE_FID)

Screen('CloseAll')


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
        t = GetSecs - EXPERIMENT_START_TIME;
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
            case 'audio start'
                trig_reps = NUM_TRIG_AUDIO_START; 
            case 'audio rep'
                trig_reps = NUM_TRIG_EVERY_5_SECONDS;
            case 'audio end'
                trig_reps = NUM_TRIG_AUDIO_END;
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

%% Record Data row
    function record_data_row()
        DATA_FORMAT_STRING = '%s,%d,%f, %d,%s,%s, %s, %d, %f\n';
            % record data row of last trial if this is a new trial
        if current >1 && strcmp(STIMULUS_SET{current-1}.type, 'question')
            fprintf(fid, DATA_FORMAT_STRING, ...
            subjid, ...
            story_number, ...
            audio_start_time - EXPERIMENT_START_TIME, ...
            STIMULUS_SET{current-1}.question_number, ...
            STIMULUS_SET{current-1}.question, ...
            RESPONSES{STIMULUS_SET{current-1}.question_number}, ...
            STIMULUS_SET{current-1}.correct_response, ...
            strcmp(RESPONSES{STIMULUS_SET{current-1}.question_number}, STIMULUS_SET{current-1}.correct_response), ...
            RTs(STIMULUS_SET{current-1}.question_number) ...
            )
        end


    end


end
    

   
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    