function MOT_task(subjid,movieFile)

%%% This function is for running the MOT experiment while scanning in fMRI %%% 
% SUBJID: subject id
%
% Author: Yuhong Jiang, 2009; adapted from MOTdigits.m
% Edited for fMRI presentataion: Idan Blank, 06/30/2014
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize variables %%
% Durations, etc.:
pretrialFixDur = 16.00; % in seconds
posttrialFixDur = 16.00; % in seconds
movieTime = 15; 
cueTime = 2.5; 
theSpeed = 2.5; % [7 10.2 15 21.9 32];

nTrials = 12;

% Targets, etc.:
nTargets = 1;
nDistractors = 4;
nItems = nTargets + nDistractors;

% Colors:
white = [255 255 255];
black = [0 0 0];

% Fixation:
fixSize = 25;   % I think this is pixels
fixcolor = white;

% other variables
fontSize = 24;   % in pixels
responseMap.Left = '1';
responseMap.Right = '2';
pixelsPerDegree = 60;
rand('state', sum(100*clock));

% Escape Key
ESCAPE_KEY = KbName('ESCAPE');

% Set up datafile name
dataDir = './data';
timingFile = [dataDir '/' subjid '_MOT.txt'];

       
%% Screen variables and preparations %%
screenNum = 0;
Screen('Preference', 'SkipSyncTests',1);
[windowPtr,rect] = Screen('OpenWindow',screenNum);
HideCursor;
Screen('TextFont',windowPtr,'Helvetica');
Screen('TextSize',windowPtr,fontSize);
fliptime = Screen('GetFlipInterval', windowPtr);
nFrames = ceil(movieTime/fliptime);

screenRect = Screen('Rect', windowPtr);
screenCenter = screenRect(3:4)./2;
fixrect = CenterRectOnPoint([0 0 fixSize fixSize],screenCenter(1),screenCenter(2));

theSpeedPF = (theSpeed.* pixelsPerDegree) .* fliptime;
        % Changeing the speeds from deg/sec to pix/frame assuming that the distance
        % is 57 cm from the monitor so each degree will be roughly equal to one cm

        
%% load shapes %%
imName = 'blackCircle.jpg';
im = imread(imName);
blackCircleImage = Screen('MakeTexture', windowPtr, im);

imName = 'redCircle.jpg';
im = imread(imName);
redCircleImage = Screen('MakeTexture', windowPtr, im);

imName = 'greenCircle.jpg' ;
im = imread(imName);
greenCircleImage = Screen('MakeTexture', windowPtr, im);


%% ONLY DO THIS ONCE: generate motion coordinates for each trial %%
% generateMOT(movieTime, fliptime, nTrials, theSpeedPF, nItems, fixSize, windowPtr, movieFile)
load(movieFile)


%% Initialize Data Recorder
% timing_fid = fopen(timingFile, 'w');
% fprintf(timing_fid, 'subject, trial, trial start time, trial end time, response \n');
% timingFormatString = '%s \t %d \t %6.3f \t %6.3f \t %s\n';
subj_data = struct();
subj_data.id = subjid;
subj_data.trialOnsets = zeros(nTrials,1);
subj_data.motionOnsets = zeros(nTrials,1);
subj_data.motionDur = zeros(nTrials,1);
subj_data.response = cell(nTrials,1);


%% Wait for trigger %%
TRIGGER_KEY = [KbName('=+'),KbName('+'),KbName('=')];  % if this doesn't work, change to '=+'
DrawFormattedText(windowPtr, 'Waiting for trigger.', 'center', 'center', 0);
Screen('Flip', windowPtr);
while 1
    [~, ~, keyCode] = KbCheck(-3);
    if keyCode(ESCAPE_KEY)
        Screen('CloseAll');
        fprintf('Experiment quit by pressing ESCAPE\n');
        break;
    elseif ismember(find(keyCode,1),TRIGGER_KEY)
        break
    end
    WaitSecs('YieldSecs', 0.0001); % Wait for yieldInterval to prevent system overload.
end


%% EXPERIMENT: Pre-task Fixation %%
experimentStartTime = GetSecs();
DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
Screen('Flip',windowPtr);
while GetSecs() - experimentStartTime <= pretrialFixDur
    doNothing = 1;
    WaitSecs('YieldSecs', 0.0001); % Wait for yieldInterval to prevent system overload.
end
clear doNothing;


%% Experiment: trials %%
Priority(1); % setting the priority
targetInds = (1:nTargets); % defining the tergets

for trialInd = 1:nTrials
    eval(['H_ARRAY = H_ARRAY_', num2str(trialInd), ';']);
    eval(['V_ARRAY = V_ARRAY_', num2str(trialInd), ';']);
    
    %% DRAWING THE FRAMES: (1) Start Cue, targets appear in red %%
    Screen('FillRect',windowPtr,fixcolor,fixrect);
    Screen('Flip', windowPtr);

    frame = 1;
    X = H_ARRAY(frame,:);
    Y = V_ARRAY(frame,:);

    for idraw = 1:nItems
        xc = X(idraw);
        yc = Y(idraw);
        if ~isempty(find(targetInds == idraw ,1))
            Screen('DrawTexture', windowPtr, redCircleImage, [], [xc-fixSize,yc-fixSize,xc+fixSize,yc+fixSize]);
        else
            Screen('DrawTexture', windowPtr, blackCircleImage, [], [xc-fixSize,yc-fixSize,xc+fixSize,yc+fixSize]);
        end
    end
    DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
    trialStartTime = Screen('Flip', windowPtr);

    while GetSecs()-trialStartTime < cueTime
        doNothing = 1;
        WaitSecs('YieldSecs', 0.0001);  % to prevent system overload
    end
    clear doNothing

    for idraw = 1:nItems % drawing all the dots again for starting the motion (removing the cue)
        xc = X(idraw);
        yc = Y(idraw);
        Screen('DrawTexture', windowPtr, blackCircleImage, [], [xc-fixSize,yc-fixSize,xc+fixSize,yc+fixSize]);
    end
    DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
    motionStartTime = Screen('Flip', windowPtr);


    %% DRAWING THE FRAMES: (2) moving objects %%
    while frame <= nFrames    
        X=H_ARRAY(frame,:);
        Y=V_ARRAY(frame,:);
        for idraw = 1:nItems
            xc = X(idraw);
            yc = Y(idraw);
            Screen('DrawTexture', windowPtr, blackCircleImage, [], [xc-fixSize,yc-fixSize,xc+fixSize,yc+fixSize]);
        end
        DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
        Screen('Flip',windowPtr);
        frame = frame+1;
    end;


    %% DRAWING THE FRAMES: (3) End cue, targets appear in green %%
    while GetSecs() - motionStartTime < movieTime
        doNothing = 1;
        WaitSecs('YieldSecs', 0.0001);  % to prevent system overload
    end
    clear doNothing

    % Define the final positions
    Final_X = H_ARRAY(length(H_ARRAY),:);
    Final_Y = V_ARRAY(length(V_ARRAY),:);

    for idraw = 1:nItems
        xc = Final_X(idraw);
        yc = Final_Y(idraw);
        if ~isempty(find(targetInds == idraw, 1))
            Screen('DrawTexture', windowPtr, greenCircleImage, [], [xc-fixSize,yc-fixSize,xc+fixSize,yc+fixSize]);
        else
            Screen('DrawTexture', windowPtr, blackCircleImage, [], [xc-fixSize,yc-fixSize,xc+fixSize,yc+fixSize]);
        end
    end
    DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
    motionEndTime = Screen('Flip', windowPtr);
    waitingForResponse = 1;

    
    while GetSecs() - motionEndTime < cueTime
        %% Wait for response %%
        if waitingForResponse

            [ keyIsDown, seconds, keyCode ] = KbCheck(-3);
            % [keyIsDown, ~, keyCode] = KbCheck; % Check the state of the keyboard.
            if keyIsDown
                key_name = KbName(keyCode);
                        % Note that we use find(keyCode) because keyCode is an array.
                        % See 'help KbCheck'

                if strcmp(key_name(1),responseMap.Left)
                    subj_data.response{trialInd} = 'Tracked successfully (1)';
                    waitingForResponse = 0;
                elseif strcmp(key_name(1), responseMap.Right)
                    subj_data.response{trialInd} = 'Failed (2)';                
                    waitingForResponse = 0;
                end
            end
            if keyCode(ESCAPE_KEY)
                Screen('CloseAll');
                fprintf('Experiment quit by pressing ESCAPE\n');
                break;
            end
        end
        WaitSecs('YieldSecs', 0.0001);  % to prevent system overload
    end
    
    subj_data.trialOnsets(trialInd) = trialStartTime-experimentStartTime;
    subj_data.motionOnsets(trialInd) = motionStartTime-experimentStartTime;
    subj_data.motionDur(trialInd) = motionEndTime-motionStartTime;
end

%% EXPERIMENT: Post-task Fixation %%
taskEndTime = GetSecs();
DrawFormattedText(windowPtr, '+', 'center', 'center', 0);
Screen('Flip',windowPtr);
while GetSecs() - taskEndTime <= posttrialFixDur
    doNothing = 1;
    WaitSecs('YieldSecs', 0.0001); % Wait for yieldInterval to prevent system overload.
end
experimentEndTime = Screen('Flip',windowPtr);
clear doNothing;
Priority(0);
Screen('CloseAll')
ShowCursor;

subj_data.expStartTime = experimentStartTime;
subj_data.expEndTime = experimentEndTime;

fileName = [dataDir, '/', subjid, '_' movieFile];
save(fileName, 'subj_data'); 