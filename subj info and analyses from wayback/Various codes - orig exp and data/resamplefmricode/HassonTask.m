function HassonTask(subjid, condInd)
% SUBJID: subject id
% CondInd: integer representing which condition is used. 
%
% USE_TTL: (default: true), (0/1) 0 -> no TTL; 1-> TTL pulses activated.
% Author: Eyal Dechter, edited by Idan Blank
% Date: 8/27/2010, edited 12/14/2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize Variables
Screen('Preference', 'SkipSyncTests', 1)
stimDirectory = 'STIMULI';
fileNames = {'PM_IntactStoryMRI.wav';
    'PM_ReverseStoryMRI.wav';
    'PM_ScrambledParagraphsMRI_edited.wav';
    'PM_ScrambledSentencesMRI.wav';
    'PM_ScrambledWordsMRI.wav'};

% durations:
pretrialFixationDur = 0; % in seconds (stimuli already have silence incorporated)
posttrialFixationDur = 0; % in seconds (stimuli already have silence incorporated)

% pixels per degrees
pixPerDeg = 60;
stimulusFontSize = .4; % in degrees


% screen variables
screenNum = 0;

% Escape Key
escapeKey = KbName('ESCAPE');

%% Load any mex files by calling them once (to eliminate loading time later)
WaitSecs(0);

%% Get filename of audio file
wavfilename = fileNames{condInd};

%% Load in audio file and initialize audio
[y, freq, nbits] = wavread(['./', stimDirectory, filesep, wavfilename]);
wavedata = y';
nrchannels = size(wavedata,1); % Number of rows == number of channels.
audioDur = length(y)/freq;

% PAD AUDIO_DUR to be multiple of 2 seconds (because TR = 2s)
audioDur = audioDur + rem((2.0-rem(audioDur,2)),2);

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

if pretrialFixationDur > 0
    pretrial_stim = struct();
    t2 = t + pretrialFixationDur;
    pretrial_stim.start_time = t;
    pretrial_stim.end_time = t2;
    t = t2;
    pretrial_stim.takes_response = 0;
    pretrial_stim.type = 'pretrial';
    STIMULUS_SET{end+1} = pretrial_stim;
end

audio_stim = struct();
t2 = t + audioDur;
audio_stim.start_time = t;
audio_stim.end_time = t2;
t = t2;
audio_stim.takes_response = 0;
audio_stim.type = 'audio';
STIMULUS_SET{end+1} = audio_stim;

if posttrialFixationDur > 0
    posttrial_stim = struct();
    t2 = t + posttrialFixationDur;
    posttrial_stim.start_time = t;
    posttrial_stim.end_time = t2;
    t = t2;
    posttrial_stim.takes_response = 0;
    posttrial_stim.type = 'posttrial';
    STIMULUS_SET{end+1} = posttrial_stim;
end

final_stim = struct();
t2 = t;
final_stim.start_time = t;
final_stim.end_time = t2;
final_stim.type = 'end run';
STIMULUS_SET{end+1} = final_stim;

NUM_STIMULI = length(STIMULUS_SET);


%% Initialize Window
[WINDOW_PTR,rect]=Screen('OpenWindow',screenNum);
Screen('TextFont',WINDOW_PTR, 'Helvetica');
Screen('TextSize',WINDOW_PTR, stimulusFontSize*pixPerDeg);


%% Wait for trigger
triggerKey = [KbName('=+'), KbName('+'), KbName('=')];
DrawFormattedText(WINDOW_PTR, 'Waiting for trigger.', 'center', 'center', 0);
Screen('Flip', WINDOW_PTR);
while 1
    [ keyIsDown, seconds, keyCode ] = KbCheck(-3);    % -3 = check input from ALL devices
    if keyCode(escapeKey)
        Screen('CloseAll');
        fprintf('Experiment quit by pressing ESCAPE\n');
        break;
    elseif ismember(find(keyCode,1), triggerKey); % used to be: keyCode(KbName(TRIGGER_KEY))
        break
    end
    WaitSecs('YieldSecs', 0.0001); % Wait for yieldInterval to prevent system overload.
end


%% Start Experiment
% send out start ttl pulse to notify experiment is starting
EXPERIMENT_START_TIME = GetSecs();
tic

%% show stimuli
N = 1;
current = 1;

while current <= NUM_STIMULI
    if GetSecs() - EXPERIMENT_START_TIME > STIMULUS_SET{N}.start_time
        current = N;
        switch STIMULUS_SET{current}.type
            case 'pretrial'
                DrawFormattedText(WINDOW_PTR, '+', 'center', 'center', 0);
                Screen('Flip',WINDOW_PTR);
            
            case 'audio'
                DrawFormattedText(WINDOW_PTR, '+', 'center', 'center', 0);
                Screen('Flip',WINDOW_PTR);
                audio_start_time = PsychPortAudio('Start', pahandle, 1, 0, 1);
                num_rep = 1;
            
            case 'posttrial'
                PsychPortAudio('Stop', pahandle);
                Screen('Flip',WINDOW_PTR);
            
            case 'end run'
                if posttrialFixationDur == 0
                    PsychPortAudio('Stop', pahandle);
                end
                fprintf('Total Run Time in Seconds: %f\n', toc);
                Screen('CloseAll');
                return;
        end
        N = N + 1;
        
    end
    
    % Check the state of the keyboard.
    [ keyIsDown, seconds, keyCode ] = KbCheck(-3);    % -3 = check input from ALL devices
    
    
    % If the user is pressing a key, then display its code number and name.
    if keyIsDown
        % Note that we use find(keyCode) because keyCode is an array.
        % See 'help KbCheck'
        key_name = KbName(keyCode);
        if keyCode(escapeKey)
            Screen('CloseAll');
            PsychPortAudio('Close' );
            fprintf('Experiment quit by pressing ESCAPE\n');
            break;
        end

    end
end

Screen('CloseAll');
ShowCursor;