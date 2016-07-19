function storiesVisual(subjid, story_number, USE_TTL)

%%% This function is for running the experiment while scanning in fMRI %%% 
% SUBJID: subject id
% STORY_NUMBER: integer representing which story is used. 
%
% USE_TTL: (default: true), (0/1) 0 -> no TTL; 1-> TTL pulses activated.
% Author: Eyal Dechter, 08/27/2010
% Edited for visual presentataion: Idan Blank, 06/28/2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% FOR TESTING:
%clear all
%subjid = 'test_subject01';
%story_number = 5; 
%USE_TTL = 0;

%% Initialize Variables
STORIES_DIRECTORY = 'STORIES_VISUAL';

% durations:
PRETRIAL_FIXATION_DUR = 16.00; % in seconds
POSTTRIAL_FIXATION_DUR = 16.00; % in seconds
QUESTION_DUR = 4.00; % in seconds
DURATION_SHORT_CONST = 1.0379212; % a constant to make presentation times shorter,
                                  % to make up for delays in the software

% other variables
RESPONSE_MAP.Left = '1';
RESPONSE_MAP.Right = '2';
STIMULUS_FONT_SIZE = 100;   % in pixels
QUESTION_FONT_SIZE = 24;    % in pixels
% FIXATION_SIZE = 2; % in degrees

% TTL variables
TRIGGER_DUR = .010; % in seconds
INTER_TRIGGER_DUR = .100; % in seconds
NUM_TRIG_BEGIN_RUN = 4; % pulses
NUM_TRIG_STORY_START = 1; % pulses
NUM_TRIG_EVERY_5_SECONDS = 1; % pulses
NUM_TRIG_STORY_END = 2; % pulses
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
is_repeat = input('Add a "b" suffix to filename? (0/1) ');
if is_repeat
    suffixStr = 'b';
else
    suffixStr = '';
end
DATADIR = './data';
WORDFILE = [DATADIR, '/', subjid, 'story', num2str(story_number), '_', suffixStr, '_visual_words.txt'];
QUESTIONFILE = [DATADIR, '/', subjid, 'story', num2str(story_number), '_', suffixStr, '_visual_questions.txt'];

PULSE_DIR = './pulses';
PULSE_FILE = [PULSE_DIR, '/', subjid, 'story', num2str(story_number), '_', suffixStr, '_visual_pulses.txt'];


%% Initialize Pulse Recorder
PULSE_FID = fopen(PULSE_FILE, 'w');
if ~USE_TTL
    fprintf(PULSE_FID, '%s\n', 'No pulses recorded, since USB DEVICE disconnected.' )
end


%% Load any mex files by calling them once (to eliminate loading time
%% later)
WaitSecs(0);

%% Get filename of stimulus file
storyFilename = [STORIES_DIRECTORY, '/story', num2str(story_number)];
load(storyFilename)
storyData.durations = cell2mat(storyData.durations);

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

for wInd=1:length(storyData.words)
    visual_stim = struct();
    t2 = t + storyData.durations(wInd)/DURATION_SHORT_CONST;
    visual_stim.start_time = t;
    visual_stim.end_time = t2;
    t = t2;
    visual_stim.takes_response = 0;
    visual_stim.type = 'visual';
    visual_stim.word = storyData.words{wInd};
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

for qInd=1:NUM_QUESTIONS
    question_stim = struct();
    t2 = t + QUESTION_DUR;
    question_stim.start_time = t;
    question_stim.end_time = t2;
    t = t2;
    question_stim.takes_response = 1;
    question_stim.question = QUESTIONS{qInd};
    question_stim.answers = abs([1 0] - (rand>.5));
    I = find(question_stim.answers);
    options = ['1', '2'];
    question_stim.correct_response = options(I);
    question_stim.choices = ANSWERS(qInd, abs(question_stim.answers-2));
    question_stim.type = 'question';
    question_stim.question_number = qInd;
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
word_fid = fopen(WORDFILE, 'w');
fprintf(word_fid, 'subject, story number, onset time (ms), word \n');
WORD_FORMAT_STRING = '%s \t %d \t %6.3f \t %s\n';

question_fid = fopen(QUESTIONFILE, 'w');
fprintf(question_fid, ...
    'subject, story number, onset time, question number, question, response, correct response, accuracy, RT (ms) \n');
QUESTION_FORMAT_STRING = '%s,%d,%f, %d,%s,%s, %s, %d, %f\n';

subj_data = struct();
subj_data.id = subjid;
subj_data.wordOnsets = zeros(length(storyData.words),1);
subj_data.questionOnsets = zeros(NUM_QUESTIONS,1);
subj_data.questions = cell(NUM_QUESTIONS,1);
subj_data.response = cell(NUM_QUESTIONS,1);
subj_data.correctResponse = cell(NUM_QUESTIONS,1);
subj_data.accuracy = zeros(NUM_QUESTIONS,1);
subj_data.RT = zeros(NUM_QUESTIONS,1);

% fid = fopen(DATAFILE, 'w');
% fprintf(fid, 'subject, story number, onset time (ms), question number, question, response, correct response, accuracy, RT (ms) \n');
% DATA_FORMAT_STRING = '%s,%d,%f, %d,%s,%s, %s, %d, %f\n';


%% Initialize Window
[WINDOW_PTR,rect]=Screen('OpenWindow',SCREEN_NUM);
Screen('TextFont',WINDOW_PTR,'Helvetica');
HideCursor;

%% Wait for trigger
TRIGGER_KEY = [KbName('=+'),KbName('+'),KbName('=')];; % ** AK changed this 081612 % if this doesn't work, change to '=+'
Screen('TextSize',WINDOW_PTR,QUESTION_FONT_SIZE);
DrawFormattedText(WINDOW_PTR, 'Waiting for trigger.', 'center', 'center', 0);
Screen('Flip', WINDOW_PTR);
while 1
    [keyIsDown, seconds, keyCode] = KbCheck(-3);
    if keyCode(ESCAPE_KEY)
        Screen('CloseAll');
        fprintf('Experiment quit by pressing ESCAPE\n');
        break;
    elseif ismember(find(keyCode,1),TRIGGER_KEY) %keyCode(KbName(TRIGGER_KEY))
        break
    end
    WaitSecs('YieldSecs', 0.0001); % Wait for yieldInterval to prevent system overload.
end


%% Start Experiment
% send out start ttl pulse to notify experiment is starting
experimentStartTime = GetSecs();    % used to be: EXPERIMENT_START_TIME = GetSecs();
tic
% if USE_TTL; send_trigger('run start'); end;


%% show stimuli
Screen('TextSize',WINDOW_PTR,STIMULUS_FONT_SIZE);
stimInd = 1;
current = 1;
storyStarted = 0;
wordInd = 1;
questionInd = 0;


while current <= NUM_STIMULI
    if GetSecs() - experimentStartTime > STIMULUS_SET{stimInd}.start_time
        current = stimInd;
        switch STIMULUS_SET{current}.type
            case 'pretrial'
                DrawFormattedText(WINDOW_PTR, '+', 'center', 'center', 0);
                if USE_TTL;send_trigger('run start');end;
                Screen('Flip',WINDOW_PTR);
                
            case 'visual'
                DrawFormattedText(WINDOW_PTR, STIMULUS_SET{current}.word, 'center', 'center', 0);
                if ~storyStarted
                    if USE_TTL; send_trigger('story start'); end
                    storyStarted = 1;
                    num_rep = 1;
                end
                Screen('Flip',WINDOW_PTR);
                subj_data.wordOnsets(wordInd) = GetSecs();
                wordInd = wordInd+1;
                
            case 'posttrial'
                DrawFormattedText(WINDOW_PTR, '+', 'center', 'center', 0);
                if USE_TTL;send_trigger('story end');end;
                Screen('Flip',WINDOW_PTR);

            case 'question'
                Screen('TextSize',WINDOW_PTR,QUESTION_FONT_SIZE);
                questionInd = STIMULUS_SET{current}.question_number;
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
                subj_data.questionOnsets(questionInd) = GetSecs();
                subj_data.questions{(STIMULUS_SET{current}.question_number)} = STIMULUS_SET{current}.question;
                subj_data.correctResponse{STIMULUS_SET{current}.question_number} = STIMULUS_SET{current}.correct_response;
%                 if USE_TTL;send_trigger('question start');end;
                
            case 'end run'
                if USE_TTL;send_trigger('end run');end;
                fprintf('Total Run Time in Seconds: %f\n', toc);
                Screen('CloseAll');
                break
        end
        stimInd = stimInd + 1;        
    end
    
    if USE_TTL; 
       if strcmp(STIMULUS_SET{current}.type, 'visual')
           if GetSecs-story_start_time > 5*num_rep 
                send_trigger('story rep')
                num_rep = num_rep + 1;
           end
       end
    end
    
    %% Record user responses
    % Check the state of the keyboard.
    [keyIsDown, seconds, keyCode] = KbCheck(-3);
    
    % If the user is pressing a key, then display its code number and name.
    if keyIsDown
        % Note that we use find(keyCode) because keyCode is an array.
        % See 'help KbCheck'
        key_name = KbName(keyCode);

        if strcmp(STIMULUS_SET{current}.type,'question') && waiting_for_response == 1
            if strcmp(key_name(1),RESPONSE_MAP.Left)
                subj_data.response{STIMULUS_SET{current}.question_number} = '1';
                subj_data.RT(STIMULUS_SET{current}.question_number) = ...
                    seconds - subj_data.questionOnsets(STIMULUS_SET{current}.question_number);
                waiting_for_response = 0;
            elseif strcmp(key_name(1), RESPONSE_MAP.Right)
                subj_data.response{STIMULUS_SET{current}.question_number} = '2';                
                subj_data.RT(STIMULUS_SET{current}.question_number) = ...
                    seconds - subj_data.questionOnsets(STIMULUS_SET{current}.question_number);
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

fclose(PULSE_FID)
Screen('CloseAll')
ShowCursor;


%% Record RTs and responses to questions in subj_data
subj_data.experimentStartTime = experimentStartTime;
for qInd = 1:length(subj_data.response)
    subj_data.questionOnsets(qInd) = subj_data.questionOnsets(qInd) - subj_data.experimentStartTime;
    subj_data.accuracy(qInd) = strcmp(subj_data.response{qInd}, subj_data.correctResponse{qInd});
end

for wInd = 1:length(subj_data.wordOnsets)
    subj_data.wordOnsets(wInd) = subj_data.wordOnsets(wInd) - subj_data.experimentStartTime;
end

for wInd = 1:length(subj_data.wordOnsets)
    fprintf(word_fid, WORD_FORMAT_STRING, ...
            subjid, ...
            story_number, ...
            subj_data.wordOnsets(wInd), ...
            storyData.words{wInd});
end
fclose(word_fid);

for qInd = 1:length(subj_data.response)
    fprintf(question_fid, QUESTION_FORMAT_STRING, ...
            subjid, ...
            story_number, ...
            subj_data.questionOnsets(qInd), ...
            qInd, ...
            subj_data.questions{qInd}, ...
            subj_data.response{qInd}, ...
            subj_data.correctResponse{qInd}, ...
            subj_data.accuracy(qInd), ...
            subj_data.RT(qInd));    
end
fclose(question_fid);

DATADIR = [pwd, '/data'];
fileName = [DATADIR, '/', subjid, 'story', num2str(story_number), '_', suffixStr, '_visual'];
save(fileName, 'subj_data');


%% Plot the difference between the intended and actual word onsets
intendedOnsets = (cell2mat(storyData.onsets))';
actualOnsets = subj_data.wordOnsets;
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