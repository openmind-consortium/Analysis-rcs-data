% Run all patients databases and textlogs. 
% First compile all these together using all available data on external drive and then process each
% individually to plot / do analysis with  RCS_pain_preproces  


% COMPILE ALL DATABASES

clear
clc


ALLPATIENTS =  {'RCS02R','RCS04L','RCS04R','RCS05L', 'RCS05R','RCS06L','RCS06R','RCS07L','RCS07R'};
rootdir = '/Volumes/PrasadX5/spiritdata/raw' ;
github_dir = '/Users/pshirvalkar/Documents/GitHub/UCSF-rcs-data-analysis';

cd(github_dir)
addpath(genpath(github_dir))
 
for x = 1


PATIENTIDside  = ALLPATIENTS{x};


% patientrootdir = fullfile(rootdir,char(regexp(PATIENTIDside,'\w*\d\d','match'))); %match the PATIENTID up to 2 digits: ie RCS02


% make database of all files
% [database_out,badsessions] = makeDataBaseRCSdata(patientrootdir,PATIENTIDside); % can add AdaptiveData.Ld0_output (but not necessary for database per se) 


% compile text logs of all Adaptive/ Stim changes
%CHANGE THE SAVE FILE LOCATION TO PROCESSED FOLDER
[textlog] = RCS_logs(rootdir,PATIENTIDside);


end

% %%  LOAD Database and Textlogs
% load(fullfile(patientrootdir,[PATIENTIDside '_database.mat']))
% load(fullfile(patientrootdir,[PATIENTIDside '_textlogs.mat']))
% %% Import Painscores
% painscores = RCS_redcap_painscores([],1);
% pain.VAS = painscores.(PATIENTIDside(1:5)).painVAS;
% pain.NRS = painscores.(PATIENTIDside(1:5)).mayoNRS;
% pain.time = painscores.(PATIENTIDside(1:5)).time;
% pain.time.TimeZone = 'America/Los_Angeles';
