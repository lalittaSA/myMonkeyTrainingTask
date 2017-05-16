%% prepare to run AudiDeci_prior_HL task.
clear
close all;

topsDataLog.flushAllData();

% input = number of trials (per conditions)
[task list] = joystick_training_instruction(0);

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
meta_data.task = list{'meta'}{'task'};

hd = list{'Stimulus'}{'header'};
meta_data.loFreq = hd.loFreq;
meta_data.hiFreq = hd.hiFreq;
meta_data.fs = hd.fs;
nTrials = list{'Counter'}{'nTrials'};
meta_data.nTrials = nTrials;
meta_data.angleLimit = list{'Input'}{'angleLimit'};

stimTime = list{'Stimulus'}{'stimTime'};
freqStim = list{'Stimulus'}{'freq'};
isH = list{'Stimulus'}{'isH'};

moveStart = list{'Input'}{'moveTime'};
moveEnd = list{'Input'}{'endTime'};
joystickTraces = list{'Input'}{'joystickTraces'};
moveAngle = list{'Input'}{'moveAngle'};
freq = list{'Input'}{'freq'};

corrects = list{'Input'}{'corrects'};
choices = list{'Input'}{'choices'};
RTs = list{'Input'}{'RTs'};
MTs = list{'Input'}{'MTs'};

data_table = table((1:nTrials)',stimTime,freqStim,isH,moveStart,moveEnd,moveAngle,freq,joystickTraces,corrects,choices,RTs,MTs,'VariableNames',{'trialID','stimTime','stimFreq','isHigh','moveStartTime','moveEndTime','moveAngle','feedbackFreq','moveTraces','correct','choice','RT','MT'});

%% Saving
save([data_folder save_filename '_list.mat'], 'list');
save([data_folder save_filename '_table.mat'], 'data_table', 'meta_data'); %Secondary, redundant save

clear
close all;