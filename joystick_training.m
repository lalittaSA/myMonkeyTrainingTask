function [task, list] = joystick_training(dispInd)

% 20170315: included angle change limit

% 20170314: included angleLimit to train monkey to move only inward &
% outward (no feedback for intermediate angles: lower = angleLimit & upper = 180-angleLimit)
% + keyboard input: p for pause | r for resume | q for quit

% 20170307: created by Lalitta - joystick training task for monkeys - 
% the task generate auditory feedback: 
% outward move (upward in screen) - play high freq tone
% inward move (downward in screen) - play low freq tone
% stimulus-response combinations: high - left | low - right 
% using mouse or joystick (with usb port)

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

hd.loFreq = 500; %hz      312.5 |  625 | 1250 | 2500 |  5000
hd.hiFreq = 2000; %hz     625   | 1250 | 2500 | 5000 | 10000 

hd.fs = 100000;%384000;

% Feedback 
feedback = dotsPlayableFreq();
feedback.sampleFrequency = hd.fs;
feedback.duration = 2000;
% feedback.frequency = hd.hiFreq;
feedback.intensity = 0.5;

% STIMULUS
list{'Stimulus'}{'header'} = hd;
list{'Stimulus'}{'player'} = feedback;


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

list{'Input'}{'controller'} = joystick;

keyboard = dotsReadableHIDKeyboard();
isQuit = strcmp({keyboard.components.name}, 'KeyboardQ');
isPause = strcmp({keyboard.components.name}, 'KeyboardP');
isResume = strcmp({keyboard.components.name}, 'KeyboardR');
QKey = keyboard.components(isQuit);
PKey = keyboard.components(isPause);
RKey = keyboard.components(isResume);
keyboard.setComponentCalibration(QKey.ID, [], [], [0 +2]);
keyboard.setComponentCalibration(PKey.ID, [], [], [0 +3]);
keyboard.setComponentCalibration(RKey.ID, [], [], [0 +4]);
IDs = keyboard.getComponentIDs();
for ii = 1:numel(IDs)
    keyboard.undefineEvent(IDs(ii));
end

keyboard.defineEvent(QKey.ID, 'quit',  0, 0, true);
keyboard.defineEvent(PKey.ID, 'pause',  0, 0, true);
keyboard.defineEvent(RKey.ID, 'resume',  0, 0, true);

keyboard.clockFunction = @GetSecs;
keyboard.isAutoRead = 1;
list{'Input'}{'controller_kb'} = keyboard;
%% add to the list

nTrials = 10;

% COUNTER
list{'Counter'}{'trial'} = 0;

list{'Counter'}{'nTrials'} = nTrials;

list{'Counter'}{'isQuit'} = 0;
list{'Counter'}{'isPause'} = 0;

% INPUT
list{'Input'}{'joystickTraces'} = cell(nTrials,1);
list{'Input'}{'startTime'} = nan(nTrials,1);
list{'Input'}{'endTime'} = nan(nTrials,1);

list{'Input'}{'angleLimit'} = 30;

list{'Input'}{'moveAngle'} = nan(nTrials,1);
list{'Input'}{'freq'} = nan(nTrials,1);


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
list{'control'}{'trial calls'} = trialCalls;

%% STATE MACHINE

% State Machine, for use in maintask
mainMachine = topsStateMachine();
mainStates = {'name', 'entry', 'input', 'exit', 'timeout', 'next';
                 'WaitFormove', {@startTrial list}, {}, {@MoveMarkerAndPlayFeedback list}, 0.1, 'Exit';
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

list{'control'}{'mainTree'} = mainTree;

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
joystick = list{'Input'}{'controller'};
joystick.flushData();
keyboard = list{'Input'}{'controller_kb'};
keyboard.flushData();

isPause = list{'Counter'}{'isPause'};
jtTraces = list{'Input'}{'joystickTraces'};

while isPause
    read(keyboard);
    [~, ~, eventname, ~] = keyboard.getHappeningEvent();
    if any(~isempty(eventname)) && strcmp(eventname{1},'resume') 
        isPause = 0;
        break
    end
end

list{'Counter'}{'isPause'} = isPause;

ensemble = list{'Graphics'}{'ensemble'};
cursor = list{'Graphics'}{'cursor'};
ensemble.setObjectProperty('isVisible', true, cursor);

counter = list{'Counter'}{'trial'};
counter = counter + 1;
list{'Counter'}{'trial'} = counter;

end


function MoveMarkerAndPlayFeedback(list)
joystick = list{'Input'}{'controller'};
keyboard = list{'Input'}{'controller_kb'};

mouseMarker = list{'Graphics'}{'mouseMarker'};
screen = list{'Graphics'}{'screen'};

jtTraces = list{'Input'}{'joystickTraces'};
startTime = list{'Input'}{'startTime'};
endTime = list{'Input'}{'endTime'};
counter = list{'Counter'}{'trial'};

moveAngle = list{'Input'}{'moveAngle'};
freq = list{'Input'}{'freq'};

maxDir = rad2deg(pi);
angleLimit = list{'Input'}{'angleLimit'};

scaleFac = screen.pixelsPerDegree;
mXprev = 0;
mYprev = 0;
sensitivityFac = 0.6*0.9; %.6*0.9; -- might want to lower this for motor error
mouseMarker.x=0;
mouseMarker.y=0;

isSoundOn = 0;
lastTenMoves = zeros(10,1);
ii = 1;
joystick.read();
cur_trace = [];
cur_angle = [];
if joystick.x == 0 && joystick.y == 0
    while 1
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
        feedback = list{'Stimulus'}{'player'};
        if any(lastTenMoves) % if joystick is moved
            %transform -90deg x (0) -> -y (-90) and y (90) -> x (0) so it becomes 0-180 deg from buttom to top
            rotatedAngle = abs(rad2deg(cart2pol(-dy,dx))); % range 0-180 deg: 0-low|180-high
            
            if ~isSoundOn    
                if rotatedAngle > maxDir - angleLimit|| rotatedAngle < angleLimit
                    freqRange = hd.hiFreq-hd.loFreq;
                    freqList = hd.loFreq:freqRange/maxDir:hd.hiFreq; % 181 steps of freq
                    feedback.freq = round(freqList(round(rotatedAngle)+1));
                    feedback.prepareToPlay;
                    feedback.play;
                    isSoundOn = 1;
                    freq(counter) = feedback.freq;
                    startTime(counter) = feedback.playTime;
                end
                moveAngle(counter) = rotatedAngle;
            end
            cur_trace = [cur_trace,[joystick.x;-joystick.y]];
            cur_angle = [cur_angle,rotatedAngle];
        end
        
        if length(cur_angle) > 1
            diff_angle = cur_angle - cur_angle(1);
        else
            diff_angle = 0;
        end
        if sqrt((mouseMarker.x)^2+(mouseMarker.y)^2) > 15 || all(~lastTenMoves)% || any(diff_angle > 91)
            jtTraces{counter} = cur_trace;
            joystick.flushData;
            mouseMarker.x = 0;
            mouseMarker.y = 0;
            if isSoundOn
                feedback.stop;
                endTime(counter) = feedback.stopTime;
                break
            end
        end
%         if any(diff_angle > 91)
%             jtTraces{counter} = cur_trace;
%             if isSoundOn
%                 feedback.stop;
%                 endTime(counter) = feedback.stopTime;
%             end
%         end
        
        read(keyboard);
        [~, ~, eventname, ~] = keyboard.getHappeningEvent();
        if any(~isempty(eventname))
            cur_event = eventname{1};
            switch cur_event
                case 'quit'
                    list{'Counter'}{'isQuit'} = 1;
                    timestamp = keyboard.history;
                    timestamp = timestamp(timestamp(:, 2) > 1, :); %Just to make sure I get a timestamp from a pressed key/button
                    list{'meta'}{'endTime'} = timestamp(end);
                case 'pause'
                    list{'Counter'}{'isPause'} = 1;
            end
            break
        end
    end
end

list{'Input'}{'joystickTraces'} = jtTraces;
list{'Input'}{'startTime'} = startTime;
list{'Input'}{'endTime'} = endTime;

list{'Input'}{'moveAngle'} = moveAngle;
list{'Input'}{'freq'} = freq;
end

function finishTrial(list)
ensemble = list{'Graphics'}{'ensemble'};
cursor = list{'Graphics'}{'cursor'};
ensemble.setObjectProperty('isVisible', false, cursor);
isQuit = list{'Counter'}{'isQuit'};

nTrials = list{'Counter'}{'nTrials'};
counter = list{'Counter'}{'trial'};
mainTree = list{'control'}{'mainTree'};

jtTraces = list{'Input'}{'joystickTraces'};
startTime = list{'Input'}{'startTime'};
endTime = list{'Input'}{'endTime'};
moveAngle = list{'Input'}{'moveAngle'};
freq = list{'Input'}{'freq'};

if isQuit
    mainTree.iterations = counter;
    nTrials = counter;
    jtTraces = jtTraces(1:counter,1);
    startTime = startTime(1:counter,1);
    endTime = startTime(1:counter,1);
    moveAngle = moveAngle(1:counter,1);
    freq = freq(1:counter,1);
    
elseif mainTree.iterations == counter
    nTrials = nTrials*2;
    mainTree.iterations = nTrials;
    jtTraces = [jtTraces;cell(nTrials,1)];
    startTime = [startTime;nan(nTrials,1)];
    endTime = [endTime;nan(nTrials,1)];
    moveAngle = [moveAngle;nan(nTrials,1)];
    freq = [freq;nan(nTrials,1)];
end

fprintf('Trial %d complete. Move angle: %d .\n', counter, moveAngle(counter));

list{'Counter'}{'nTrials'} = nTrials;
list{'control'}{'mainTree'} = mainTree;

list{'Input'}{'joystickTraces'} = jtTraces;
list{'Input'}{'startTime'} = startTime;
list{'Input'}{'endTime'} = endTime;
list{'Input'}{'moveAngle'} = moveAngle;
list{'Input'}{'freq'} = freq;

end



