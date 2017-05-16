%?lear
close all;

topsDataLog.flushAllData();

% input = number of trials (per conditions)
[task list] = joystick_training(0);

% visualize the task's structure
% tree.gui();
% list.gui();

% Run the task by invoking run() on the top-level object
% commandwindow();
% dotsTheScreen.openWindow()
task.run();
% dotsTheScreen.closeWindow();
%topsDataLog.gui();

% Post-Processing
data_folder = '/Research/uPenn_auditoryDecision/data/monkeyTraining/';
save_filename = list{'meta'}{'saveFilename'};

% create data table
meta_data.subject = list{'meta'}{'subjID'};
meta_data.date = list{'meta'}{'date'};
meta_data.startTime = list{'meta'}{'startTime'};
meta_data.endTime = list{'meta'}{'endTime'};
meta_data.task = list{'meta'}{'task'};

hd = list{'Stimulus'}{'header'};
meta_data.loFreq = hd.loFreq;
meta_data.hiFreq = hd.hiFreq;
meta_data.fs = hd.fs;
nTrials = list{'Counter'}{'trial'};
meta_data.nTrials = nTrials;
meta_data.angleLimit = list{'Input'}{'angleLimit'};

moveStart = list{'Input'}{'startTime'};
moveEnd = list{'Input'}{'endTime'};
joystickTraces = list{'Input'}{'joystickTraces'};
moveAngle = list{'Input'}{'moveAngle'};
freq = list{'Input'}{'freq'};

data_table = table((1:nTrials)',moveStart,moveEnd,moveAngle,freq,joystickTraces,'VariableNames',{'trialID','moveStartTime','moveEndTime','moveAngle','feedbackFreq','moveTraces'});

%% Saving
save([data_folder save_filename '_list.mat'], 'list');
save([data_folder save_filename '_table.mat'], 'data_table', 'meta_data'); %Secondary, redundant save

clear
close all;