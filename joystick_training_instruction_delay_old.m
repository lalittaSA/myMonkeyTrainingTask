function [task, list] = joystick_training_instruction_delay(dispInd)

% 20170707: created by Lalitta - joystick training task for monkeys - 
% the task gives auditive instruction and generates auditory feedback for joystick movement: 
% high freq instruction requires outward movement (upward for cursor on the screen) - play high freq tone during movement (adjustable level)
% low freq instruction requires inward movement (downward in screen) - play low freq tone during movement (adjustable)
% stimulus-response combinations: high - left | low - right 
% using mouse or joystick (with usb port)
% + keyboard input: p for pause | r for resume | q for quit
% + blockwise / random options: h for high | l for low | number(1-9) for blocksizes | m for intermixed (random) 
% + soundlevel: f for higher feedback (movement sound) | d for lower feedback | s for higher reward sound | a for lower reward sound

% Returns a a topsTreeNode object which organizes tasks and trials.
% the object's run() method will start the task.  The object's gui() method
% will launch a graphical interface for viewing the organization of the
% task.

% Also returns as a second output a topsGroupedList object which holds all
% the objects and data needed to run the task, including tree.  The list's
% gui() method will launch a graphical interface for viewing the objects
% and data.

%%
% if nargin < 1
%     disp_ind = 0;
%     isClient = false;
% elseif nargin < 2
    isClient = false;
% end

%% Setting up the screen
screen = dotsTheScreen.theObject;
screen.reset('displayIndex', dispInd); %change display index to 0 for debug (small screen). 1 for full screen. Use >1 for external monitors.

%Call GetSecs just to load up the Mex files for getting time, so no delays later
GetSecs;

% get subject id
subj_id = input('Subject ID: ','s');
cur_date = datestr(now,'yymmdd');
cur_time = datestr(now,'HHMM');
cur_task = mfilename;
save_filename = [cur_task '_' subj_id '_' cur_date '_' cur_time];

%% Setting up a list structure
list = topsGroupedList(cur_task);

% SUBJECT
list{'meta'}{'subjID'} = subj_id;
list{'meta'}{'date'} = cur_date;
list{'meta'}{'startTime'} = cur_time;
list{'meta'}{'task'} = cur_task;
list{'meta'}{'saveFilename'} = save_filename;


%% audio settings
if subj_id == 'miya'
    hd.loFreq = 500; %hz   4000 | 2000 | 1000 |  500 | 250
    hd.hiFreq = 4000; %hz  8000 | 4000 | 2000 | 1000 | 500
elseif subj_id == 'cass'
    hd.loFreq = 500;   % 4000 | 2000 | 1000 |  500 | 250
    hd.hiFreq = 4000;   % 8000 | 4000 | 2000 | 1000 | 500
else
    hd.loFreq = 500;   % 4000 | 2000 | 1000 |  500 | 250
    hd.hiFreq = 4000;   % 8000 | 4000 | 2000 | 1000 | 500
end

hd.fs = 44100;%384000;


% Instruction
instruct = dotsPlayableFreq();
instruct.sampleFrequency = hd.fs;
instruct.duration = 2000;
% instruct.frequency = hd.hiFreq;
instruct.intensity = 0.5;

% Feedback 
feedback = dotsPlayableFreq();
feedback.sampleFrequency = hd.fs;
feedback.duration = 5000;
% feedback.frequency = hd.hiFreq;
feedback.intensity = 0.4;

% Feedback 
pos_feedback = dotsPlayableFile();
pos_feedback.fileName = 'Coin.wav';
pos_feedback.intensity = 0.2;
neg_feedback = dotsPlayableFile();
neg_feedback.fileName = 'beep-02.wav';
neg_feedback.intensity = 0.2;

% STIMULUS
list{'Stimulus'}{'header'} = hd;
list{'Stimulus'}{'instruct'} = instruct;
list{'Stimulus'}{'feedback'} = feedback;
list{'Stimulus'}{'pos_feedback'} = pos_feedback;
list{'Stimulus'}{'neg_feedback'} = neg_feedback;


%% Input
joystick = dotsReadableHIDMouse(); %Set up gamepad object
prefs.VendorID = 2289;
prefs.ProductID = 2;
prefs.VersionNumber = 256;
joystick.devicePreference = prefs;
% undefine any default events
IDs = joystick.getComponentIDs();
for ii = 1:numel(IDs)
    joystick.undefineEvent(IDs(ii));
end

%Making sure the UI is running on the same clock as everything else!
%Using Operating System Time as absolute clock, from PsychToolbox
joystick.clockFunction = @GetSecs;

%Storing ui in a List bin to access from functions!
joystick.isAutoRead = 1;

joystick.isExclusive = 1;
joystick.flushData;
joystick.initialize();

list{'Input'}{'Controller'} = joystick;

keyboard = dotsReadableHIDKeyboard();

isMix = strcmp({keyboard.components.name}, 'KeyboardM');
isLow = strcmp({keyboard.components.name}, 'KeyboardL');
isHigh = strcmp({keyboard.components.name}, 'KeyboardH');
MKey = keyboard.components(isMix);
LKey = keyboard.components(isLow);
HKey = keyboard.components(isHigh);
% keyboard.setComponentCalibration(MKey.ID, [], [], [0 +2]);
% keyboard.setComponentCalibration(LKey.ID, [], [], [0 +3]);
% keyboard.setComponentCalibration(HKey.ID, [], [], [0 +4]);

isNum = cell(9,1);
numKey = cell(9,1);
for nn = 1:9
    isNum{nn} = strcmp({keyboard.components.name}, ['Keyboard' num2str(nn)]);
    numKey{nn} = keyboard.components(isNum{nn});
%     keyboard.setComponentCalibration(numKey{nn}.ID, [], [], [0 +2]);
end

isQuit = strcmp({keyboard.components.name}, 'KeyboardQ');
isPause = strcmp({keyboard.components.name}, 'KeyboardP');
isResume = strcmp({keyboard.components.name}, 'KeyboardR');
QKey = keyboard.components(isQuit);
PKey = keyboard.components(isPause);
RKey = keyboard.components(isResume);
% keyboard.setComponentCalibration(QKey.ID, [], [], [0 +2]);
% keyboard.setComponentCalibration(PKey.ID, [], [], [0 +3]);
% keyboard.setComponentCalibration(RKey.ID, [], [], [0 +4]);

feedBackUp = strcmp({keyboard.components.name}, 'KeyboardF');
feedBackDown = strcmp({keyboard.components.name}, 'KeyboardD');
rewardSoundUp = strcmp({keyboard.components.name}, 'KeyboardS');
rewardSoundDown = strcmp({keyboard.components.name}, 'KeyboardA');
FKey = keyboard.components(feedBackUp);
DKey = keyboard.components(feedBackDown);
SKey = keyboard.components(rewardSoundUp);
AKey = keyboard.components(rewardSoundDown);


IDs = keyboard.getComponentIDs();
for ii = 1:numel(IDs)
    keyboard.undefineEvent(IDs(ii));
end

keyboard.defineEvent(MKey.ID, 'mixed',  0, 0, true);
keyboard.defineEvent(LKey.ID, 'low',  0, 0, true);
keyboard.defineEvent(HKey.ID, 'high',  0, 0, true);

for nn = 1:9
    keyboard.defineEvent(numKey{nn}.ID, ['num' num2str(nn)],  0, 0, true);
end

keyboard.defineEvent(QKey.ID, 'quit',  0, 0, true);
keyboard.defineEvent(PKey.ID, 'pause',  0, 0, true);
keyboard.defineEvent(RKey.ID, 'resume',  0, 0, true);

keyboard.defineEvent(FKey.ID, 'feedBackUp',  0, 0, true);
keyboard.defineEvent(DKey.ID, 'feedBackDown',  0, 0, true);
keyboard.defineEvent(SKey.ID, 'rewardSoundUp',  0, 0, true);
keyboard.defineEvent(AKey.ID, 'rewardSoundDown',  0, 0, true);

keyboard.clockFunction = @GetSecs;
keyboard.isAutoRead = 1;
list{'Input'}{'Controller_kb'} = keyboard;

%% add to the list

nTrials = 5000;

% COUNTER
list{'Counter'}{'trial'} = 0;
list{'Counter'}{'nTrials'} = nTrials;

list{'Counter'}{'isQuit'} = 0;
list{'Counter'}{'isPause'} = 0;

list{'Stimulus'}{'isHigh'} = rand > 0.5;
list{'Stimulus'}{'isMixed'} = 0;
list{'Stimulus'}{'isBlock'} = 0;
list{'Stimulus'}{'blockSize'} = 0;
list{'Counter'}{'nTrialsInBlock'} = 0;

list{'Stimulus'}{'stimTime'} = nan(nTrials,1);
list{'Stimulus'}{'freq'} = nan(nTrials,1);
list{'Stimulus'}{'isH'} = nan(nTrials,1);

% INPUT
list{'Input'}{'joystickTraces'} = cell(nTrials,1);

list{'Input'}{'moveTime'} = nan(nTrials,1);
list{'Input'}{'endTime'} = nan(nTrials,1);

list{'Input'}{'corrects'} = nan(nTrials,1);
list{'Input'}{'choices'} = nan(nTrials,1);
list{'Input'}{'RTs'} = nan(nTrials,1);
list{'Input'}{'MTs'} = nan(nTrials,1);

list{'Input'}{'angleLimit'} = 30;

list{'Input'}{'moveAngle'} = nan(nTrials,1);
list{'Input'}{'freq'} = nan(nTrials,1);

%% 
list{'Timing'}{'delayFix'} = 0.1;
list{'Timing'}{'delayVar'} = 0.1;
list{'Timing'}{'responsewindow'} = 3;
list{'Timing'}{'itiSucc'} = 1;
list{'Timing'}{'itiErr'} = 5;
list{'Timing'}{'fixTime'} = nan(nTrials,1);

%% Graphics

mouseMarker = dotsDrawableVertices();
mouseMarker.colors = [0.5 0.5 0.5];
mouseMarker.x = 0;
mouseMarker.y = 0;
mouseMarker.pixelSize = 10;
mouseMarker.isVisible = true;
list{'Graphics'}{'mouseMarker'} = mouseMarker;

%Graphical ensemble
ensemble = dotsEnsembleUtilities.makeEnsemble('drawables', isClient);
cursorInd = ensemble.addObject(mouseMarker);

list{'Graphics'}{'ensemble'} = ensemble;
list{'Graphics'}{'cursor'} = cursorInd;


% tell the ensembles how to draw a frame of graphics
% the static drawFrame() takes a cell array of objects
ensemble.automateObjectMethod(...
    'draw', @dotsDrawable.drawFrame, {}, [], true);

% also put dotsTheScreen into its own ensemble
scId = dotsEnsembleUtilities.makeEnsemble('screen', isClient);
scId.addObject(screen);
list{'Graphics'}{'screen'} = screen;
list{'Graphics'}{'scId'} = scId;

% automate the task of flipping screen buffers
scId.automateObjectMethod('flip', @nextFrame);

%% Control:

% a batch of function calls that apply to all the trial types below
%   start- and finishFevalable get called once per trial
%   addCall() accepts fevalables to be called repeatedly during a trial
trialCalls = topsCallList();
trialCalls.addCall({@read, joystick}, 'read input');
list{'Control'}{'trial calls'} = trialCalls;

%% STATE MACHINE

% State Machine, for use in maintask
mainMachine = topsStateMachine();
mainStates = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                 'CheckReady', {@startTrial list}, {}, {@checkJoystick list}, 0, 'Stimulus';
                 'Stimulus', {@playstim list}, {}, {}, 0, 'CheckResponse';
                 'CheckResponse', {@MoveMarkerAndPlayFeedback list}, {}, {}, 0, 'Exit';
                 'Exit',{@finishTrial list}, {}, {}, 0.1,''};
mainMachine.addMultipleStates(mainStates);

mainConcurrents = topsConcurrentComposite();
mainConcurrents.addChild(ensemble);
mainConcurrents.addChild(trialCalls);
mainConcurrents.addChild(mainMachine);
mainConcurrents.addChild(scId);

mainTree = topsTreeNode();
mainTree.iterations = nTrials;
mainTree.addChild(mainConcurrents);

list{'Control'}{'mainTree'} = mainTree;

% Top Level Runnables
task = topsTreeNode();
task.startFevalable = {@callObjectMethod, scId, @open};
task.finishFevalable = {@callObjectMethod, scId, @close};
task.addChild(mainTree);

list{'outline'}{'task'} = task;
end

%% Accessory Functions

function startTrial(list)
% clear data from the last trial
joystick = list{'Input'}{'Controller'};
joystick.flushData();
keyboard = list{'Input'}{'Controller_kb'};
keyboard.flushData();

isPause = list{'Counter'}{'isPause'};

while isPause
    read(keyboard);
    [~, ~, eventname, ~] = keyboard.getHappeningEvent();
    if any(~isempty(eventname)) && strcmp(eventname{1},'resume') 
        isPause = 0;
        disp('task is resumed')
        break
    end
end

list{'Counter'}{'isPause'} = isPause;

ensemble = list{'Graphics'}{'ensemble'};
cursor = list{'Graphics'}{'cursor'};
ensemble.setObjectProperty('isVisible', true, cursor);
ensemble.setObjectProperty('isVisible', true, cursor);
ensemble.setObjectProperty('colors', [0.5 0.5 0.5], cursor);

counter = list{'Counter'}{'trial'};
counter = counter + 1;
list{'Counter'}{'trial'} = counter;

end

function checkJoystick(list)
joystick = list{'Input'}{'Controller'};
fixTimes = list{'Timing'}{'fixTime'};
counter = list{'Counter'}{'trial'};
delay = list{'Timing'}{'delayFix'} + rand(1)*list{'Timing'}{'delayVar'};
% check if joystick is in the middle
joystick.read();
screen = list{'Graphics'}{'screen'};
scaleFac = screen.pixelsPerDegree;
mXprev = 0;
mYprev = 0;
sensitivityFac = 0.6*0.9; %.6*0.9; -- might want to lower this for motor error
lastTenMoves = ones(10,1);
ii = 1;
fixOn = 0;
while 1
    joystick.read();
    mXcurr = joystick.x/scaleFac; mYcurr = -joystick.y/scaleFac;
    dx = sensitivityFac*(mXcurr-mXprev);
    dy = sensitivityFac*(mYcurr-mYprev);
    isMove = ~(dy == 0 && dx == 0);
    lastTenMoves(mod(ii,10)+1) = isMove;
    ii = ii+1;
    mXprev = mXcurr;
    mYprev = mYcurr;
    if all(~lastTenMoves) 
        if fixOn == 0
            joystick.flushData();
            fixOn = 1;
            tic
        end
    else
        fixOn = 0;
    end
    % wait - fixation time
    if fixOn == 1
        if toc >= delay
            break;
        end
    end
        
    pause(0.005)
end

fixTime = toc;
fixTimes(counter) = fixTime;
list{'Timing'}{'fixTime'} = fixTimes;
end

function playstim(list)
isH = list{'Stimulus'}{'isH'};
freq = list{'Stimulus'}{'freq'};
stimTime = list{'Stimulus'}{'stimTime'};
instruct = list{'Stimulus'}{'instruct'};

counter = list{'Counter'}{'trial'};
hd = list{'Stimulus'}{'header'};
isHigh = list{'Stimulus'}{'isHigh'};
isMixed = list{'Stimulus'}{'isMixed'};
isBlock = list{'Stimulus'}{'isBlock'};
nTrialsInBlock = list{'Counter'}{'nTrialsInBlock'};
blockSize = list{'Stimulus'}{'blockSize'};

if isMixed
    if rand > 0.5
        tmp_isH = 1;
    else
        tmp_isH = 0;
    end
elseif isBlock && counter > 1
    if nTrialsInBlock < blockSize
        tmp_isH = isH(counter-1);       % stay
    else
        tmp_isH = 1 - isH(counter-1);   % switch if the block size is reached
        list{'Counter'}{'nTrialsInBlock'} = 0;
    end
else
    if isHigh
        tmp_isH = 1;
    else
        tmp_isH = 0;
    end
end

if tmp_isH
    cur_freq = hd.hiFreq;
else
    cur_freq = hd.loFreq;
end
instruct.freq = cur_freq;

% play stimulus
instruct.prepareToPlay;
instruct.play


%Logging timestamps/frequecy of the stimulus
stimTime(counter) = instruct.playTime;
list{'Stimulus'}{'stimTime'} = stimTime;

freq(counter) = cur_freq;
list{'Stimulus'}{'freq'} = freq;

isH(counter) = tmp_isH;
list{'Stimulus'}{'isH'} = isH;

end


function MoveMarkerAndPlayFeedback(list)
joystick = list{'Input'}{'Controller'};
keyboard = list{'Input'}{'Controller_kb'};

mouseMarker = list{'Graphics'}{'mouseMarker'};
screen = list{'Graphics'}{'screen'};

jtTraces = list{'Input'}{'joystickTraces'};
moveTime = list{'Input'}{'moveTime'};
endTime = list{'Input'}{'endTime'};
stimTime = list{'Stimulus'}{'stimTime'};

moveAngle = list{'Input'}{'moveAngle'};
freq = list{'Input'}{'freq'};

corrects = list{'Input'}{'corrects'};
choices = list{'Input'}{'choices'};
RTs = list{'Input'}{'RTs'};
MTs = list{'Input'}{'MTs'};

maxDir = rad2deg(pi);

isH = list{'Stimulus'}{'isH'};
counter = list{'Counter'}{'trial'};

scaleFac = screen.pixelsPerDegree;
mXprev = 0;
mYprev = 0;
sensitivityFac = 0.6*0.9; %.6*0.9; -- might want to lower this for motor error
mouseMarker.x=0;
mouseMarker.y=0;

isMoving = 0;
lastTenMoves = zeros(10,1);
ii = 1;
joystick.read();
cur_trace = [];
isCorrect = 0;
errRT = 0;

ini_choice = 0;
def_choice = 0;

choice = 0;
rt = NaN;
mt = NaN;


responsewindow = list{'Timing'}{'responsewindow'};
whatsNext = '';

tic 
while sqrt((mouseMarker.x)^2+(mouseMarker.y)^2) < 20
    if toc > responsewindow %This was previously Playsecs
        instruct.stop;
        break
    end
    joystick.read();
    mXcurr = joystick.x/scaleFac; mYcurr = -joystick.y/scaleFac;
    dx = sensitivityFac*(mXcurr-mXprev);
    dy = sensitivityFac*(mYcurr-mYprev);
    mouseMarker.x = mouseMarker.x+dx;
    mouseMarker.y = mouseMarker.y+dy;
    mouseMarker.draw
    screen.nextFrame();
    isMove = ~(dy == 0 && dx == 0);
    lastTenMoves(mod(ii,10)+1) = isMove;
    ii = ii+1;
    mXprev = mXcurr;
    mYprev = mYcurr;
    
    hd = list{'Stimulus'}{'header'};
    feedback = list{'Stimulus'}{'feedback'};
    instruct = list{'Stimulus'}{'instruct'};
    if any(lastTenMoves) % if joystick is moved
        %transform -90deg x (0) -> -y (-90) and y (90) -> x (0) so it becomes 0-180 deg from buttom to top
        rotatedAngle = abs(rad2deg(cart2pol(-dy,dx))); % range 0-180 deg: 0-low|180-high
        
        if ~isMoving
            instruct.stop;
%             if rotatedAngle > maxDir - angleLimit|| rotatedAngle < angleLimit
                freqRange = hd.hiFreq-hd.loFreq;
                freqList = hd.loFreq:freqRange/maxDir:hd.hiFreq; % 181 steps of freq
                feedback.freq = round(freqList(round(rotatedAngle)+1));
                feedback.prepareToPlay;
                feedback.play;
                isMoving = 1;
                freq(counter) = feedback.freq;
                moveTime(counter) = instruct.stopTime;
%             end
            moveAngle(counter) = rotatedAngle;
            if rotatedAngle < 90
                ini_choice = 1; % low - choice 1
            elseif rotatedAngle >= 90
                ini_choice = 2; % high - choice 2
            end
                
            rt = moveTime(counter) - stimTime(counter);
        end
        cur_trace = [cur_trace,[joystick.x;-joystick.y]];
    end
    
    if abs(mouseMarker.y) > 3
        switch sign(mouseMarker.y)
            case -1,    def_choice = 1; % low - choice 1
            case 1,     def_choice = 2; % high - choice 2
        end
    end
    
    if def_choice > 0 || (all(~lastTenMoves) && isMoving)
        jtTraces{counter} = cur_trace;
        joystick.flushData;
        mouseMarker.x = 0;
        mouseMarker.y = 0;
        if def_choice == ini_choice
            choice = def_choice;
        end
        if choice > 0
            if isH(counter) && choice == 2, isCorrect = 1; end
            if ~isH(counter) && choice == 1, isCorrect = 1; end
            if rt<0.1, isCorrect = 0; errRT = 1; end
        end
        
        feedback.stop;
        endTime(counter) = feedback.stopTime;
        mt = endTime(counter) - moveTime(counter);
        break

    end
    
    read(keyboard);
    [~, ~, eventname, ~] = keyboard.getHappeningEvent();
    if any(~isempty(eventname))
        cur_event = eventname{1};
        switch cur_event
            case 'quit'
                list{'Counter'}{'isQuit'} = 1;
                whatsNext = 'task is ended';
            case 'pause'
                list{'Counter'}{'isPause'} = 1;
                whatsNext = 'task is paused';
            case 'high'
                list{'Stimulus'}{'isHigh'} = 1;
                list{'Stimulus'}{'isMixed'} = 0;
                whatsNext = 'HIGH TONE BLOCK';
            case 'low'
                list{'Stimulus'}{'isHigh'} = 0;
                list{'Stimulus'}{'isMixed'} = 0;
                whatsNext = 'LOW TONE BLOCK';
            case 'mixed'
                list{'Stimulus'}{'isMixed'} = 1;
                whatsNext = 'HIGH-LOW INTERLEAVED';
            case 'feedBackUp'
                feedback = list{'Stimulus'}{'feedback'};
                feedback.intensity = feedback.intensity + 0.1;
                if feedback.intensity >= 1
                    feedback.intensity = 1; % ceiling at 1
                    whatsNext = 'Feedback level is maximum';
                else
                    whatsNext = 'Feedback level is increased';
                end
                tmp_feedback = feedback.intensity;
                list{'Stimulus'}{'feedback'} = feedback;
            case 'feedBackDown'
                feedback = list{'Stimulus'}{'feedback'};
                feedback.intensity = feedback.intensity - 0.1;
                if feedback.intensity <= 0
                    feedback.intensity = 0; % floor at 0
                    whatsNext = 'Feedback level is minimum';
                else
                    whatsNext = 'Feedback level is decreased';
                end
                tmp_feedback = feedback.intensity;
                list{'Stimulus'}{'feedback'} = feedback;
                
            case 'rewardSoundUp'
                feedbackPos = list{'Stimulus'}{'pos_feedback'};
                feedbackPos.intensity = feedbackPos.intensity + 0.1;
                if feedbackPos.intensity >= 1
                    feedbackPos.intensity = 1; % ceiling at 1
                    whatsNext = 'Feedback level is maximum';
                else
                    whatsNext = 'Feedback level is increased';
                end
                list{'Stimulus'}{'pos_feedback'} = feedbackPos;
                feedbackNeg = list{'Stimulus'}{'neg_feedback'};
                feedbackNeg.intensity = feedbackNeg.intensity + 0.1;
                if feedbackNeg.intensity >= 1
                    feedbackNeg.intensity = 1; % ceiling at 1
                    whatsNext = 'Feedback level is maximum';
                else
                    whatsNext = 'Feedback level is increased';
                end
                list{'Stimulus'}{'neg_feedback'} = feedbackNeg;
            case 'rewardSoundDown'
                feedbackPos = list{'Stimulus'}{'pos_feedback'};
                feedbackPos.intensity = feedbackPos.intensity - 0.1;
                if feedbackPos.intensity <= 0
                    feedbackPos.intensity = 0; % floor at 0
                    whatsNext = 'Reward sound level is minimum';
                else
                    whatsNext = 'Reward sound level is decreased';
                end
                list{'Stimulus'}{'pos_feedback'} = feedbackPos;
                
                feedbackNeg = list{'Stimulus'}{'neg_feedback'};
                feedbackNeg.intensity = feedbackNeg.intensity - 0.1;
                if feedbackNeg.intensity <= 0
                    feedbackNeg.intensity = 0; % floor at 0
                    whatsNext = 'Reward sound level is minimum';
                else
                    whatsNext = 'Reward sound level is decreased';
                end
                list{'Stimulus'}{'neg_feedback'} = feedbackNeg;
        end
        if strfind(cur_event,'num')
            list{'Stimulus'}{'isBlock'} = 1;
            list{'Stimulus'}{'isMixed'} = 0;
            list{'Stimulus'}{'blockSize'} = str2double(cur_event(end));
            list{'Counter'}{'nTrialsInBlock'} = 0;
            whatsNext = ['Block of ' cur_event(end)];
        else
            list{'Stimulus'}{'isBlock'} = 0;
        end
        keyboard.flushData();
    end
end

if isCorrect
    feedback2 = list{'Stimulus'}{'pos_feedback'};
    mouseMarker = list{'Graphics'}{'mouseMarker'};
    mouseMarker.colors = [0 1 0];  
else
    feedback2 = list{'Stimulus'}{'neg_feedback'};
    mouseMarker = list{'Graphics'}{'mouseMarker'};
    if errRT
        mouseMarker.colors = [0.5 0.5 0];
    else
        mouseMarker.colors = [1 0 0];
    end
end
mouseMarker.draw
screen.nextFrame();

feedback2.prepareToPlay;
feedback2.play;

if ~isempty(whatsNext)
    disp(whatsNext)
end

corrects(counter) = isCorrect;
choices(counter) = choice;
RTs(counter) = rt;
MTs(counter) = mt;

correct_text = {'incorrect';'correct'};
choice_text = {'none';'low';'high'};

fprintf('Trial %d complete. Choice: %s (%s).\n', counter,choice_text{choice+1},correct_text{isCorrect+1});


if isCorrect && list{'Stimulus'}{'isBlock'}
    nTrialsInBlock = list{'Counter'}{'nTrialsInBlock'};
    nTrialsInBlock = nTrialsInBlock + 1;
    list{'Counter'}{'nTrialsInBlock'} = nTrialsInBlock;
end

list{'Input'}{'joystickTraces'} = jtTraces;
list{'Input'}{'moveTime'} = moveTime;
list{'Input'}{'endTime'} = endTime;

list{'Input'}{'moveAngle'} = moveAngle;
list{'Input'}{'freq'} = freq;

list{'Input'}{'corrects'} = corrects;
list{'Input'}{'choices'} = choices;
list{'Input'}{'RTs'} = RTs;
list{'Input'}{'MTs'} = MTs;

end

function finishTrial(list)
ensemble = list{'Graphics'}{'ensemble'};
cursor = list{'Graphics'}{'cursor'};
ensemble.setObjectProperty('isVisible', false, cursor);

isQuit = list{'Counter'}{'isQuit'};

nTrials = list{'Counter'}{'nTrials'};
counter = list{'Counter'}{'trial'};
mainTree = list{'Control'}{'mainTree'};
corrects = list{'Input'}{'corrects'};

if isQuit || counter == mainTree.iterations
    fixTime = list{'Timing'}{'fixTime'};
    stimTime = list{'Stimulus'}{'stimTime'};
    freqStim = list{'Stimulus'}{'freq'};
    isH = list{'Stimulus'}{'isH'};
    
    jtTraces = list{'Input'}{'joystickTraces'};
    moveTime = list{'Input'}{'moveTime'};
    endTime = list{'Input'}{'endTime'};
    moveAngle = list{'Input'}{'moveAngle'};
    freq = list{'Input'}{'freq'};

    choices = list{'Input'}{'choices'};
    RTs = list{'Input'}{'RTs'};
    MTs = list{'Input'}{'MTs'};
    
    if isQuit
        mainTree.iterations = counter;
        nTrials = counter;
        
        fixTime = fixTime(1:counter,1);
        stimTime = stimTime(1:counter,1);
        freqStim = freqStim(1:counter,1);
        isH = isH(1:counter,1);
        
        jtTraces = jtTraces(1:counter,1);
        moveTime = moveTime(1:counter,1);
        endTime = endTime(1:counter,1);
        moveAngle = moveAngle(1:counter,1);
        freq = freq(1:counter,1);
        
        corrects = corrects(1:counter,1);
        choices = choices(1:counter,1);
        RTs = RTs(1:counter,1);
        MTs = MTs(1:counter,1);
        
    elseif counter == mainTree.iterations
        nTrials = nTrials*2;
        mainTree.iterations = nTrials;
        
        fixTime = [fixTime;nan(nTrials,1)];
        stimTime = [stimTime;nan(nTrials,1)];
        freqStim = [freqStim;nan(nTrials,1)];
        isH = [isH;nan(nTrials,1)];
        
        jtTraces = [jtTraces;cell(nTrials,1)];
        moveTime = [moveTime;nan(nTrials,1)];
        endTime = [endTime;nan(nTrials,1)];
        moveAngle = [moveAngle;nan(nTrials,1)];
        freq = [freq;nan(nTrials,1)];
        
        corrects = [corrects;nan(nTrials,1)];
        choices = [choices;nan(nTrials,1)];
        RTs = [RTs;nan(nTrials,1)];
        MTs = [MTs;nan(nTrials,1)];
    end
    
    list{'Counter'}{'nTrials'} = nTrials;
    list{'Control'}{'mainTree'} = mainTree;
    
    list{'Timing'}{'fixTime'} = fixTime;
    list{'Stimulus'}{'stimTime'} = stimTime;
    list{'Stimulus'}{'freq'} = freqStim;
    list{'Stimulus'}{'isH'} = isH;
    
    list{'Input'}{'joystickTraces'} = jtTraces;
    list{'Input'}{'moveTime'} = moveTime;
    list{'Input'}{'endTime'} = endTime;
    list{'Input'}{'moveAngle'} = moveAngle;
    list{'Input'}{'freq'} = freq;
    
    list{'Input'}{'corrects'} = corrects;
    list{'Input'}{'choices'} = choices;
    list{'Input'}{'RTs'} = RTs;
    list{'Input'}{'MTs'} = MTs;
end

data_folder = '/Research/uPenn_auditoryDecision/data/monkeyTraining/';
save_filename = list{'meta'}{'saveFilename'};
save([data_folder save_filename '_list.mat'], 'list');

% pause(1)

if corrects(counter)
    pause(list{'Timing'}{'itiSucc'})
else
    pause(list{'Timing'}{'itiErr'})
end
end



