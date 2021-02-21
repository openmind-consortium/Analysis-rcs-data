% This is the first attempt at preprocessing RC+S data using the new deserialization pipeline
% This will create combined MAT files for all recording sessions and create
% a database index of all files
%
% MUST USE MATLAB 2019a or earlier (given JSON issue)
%
% Prasad Shirvalkar Nov 11, 2020

clear
clc

PATIENTID = 'CPRCS01'
% 'RCS02R'
% 'CPRCS01';
rootdir = '/Volumes/Prasad_X5/' ;
github_dir = '/Users/pshirvalkar/Documents/GitHub/UCSF-rcs-data-analysis';


%%
localrootdir = fullfile(rootdir,char(regexp(PATIENTID,'\w*\d\d','match'))); %match the PATIENTID up to 2 digits: ie RCS02
scbsdir = fullfile(localrootdir,'/SummitData/SummitContinuousBilateralStreaming/', PATIENTID);
aDBSdir = fullfile(localrootdir, '/SummitData/StarrLab/', PATIENTID);

cd(github_dir)
addpath(genpath(github_dir))

%% make database of all files
D = makeDataBaseRCSdata(scbsdir,aDBSdir);

%%  LOAD Database
load(fullfile(scbsdir,[PATIENTID 'database_summary.mat'])) 
D = sorted_database;

%% Process and load all data - skip if mat already exists

dirsdata = findFilesBVQX(scbsdir,'Sess*',struct('dirs',1,'depth',1));

% find out if a mat file was already created in this folder
% if so, just an update is needed and will not recreate mat file
dbout = [];
for d = 1:numel(dirdata)
    diruse = findFilesBVQX(dirsdata{d},'Device*',struct('dirs',1,'depth',1));
    
    fprintf('\n \n Reading Session Folder %d of %d  \n',d,length(dirsdata))
    if isempty(diruse) % no data exists inside
        fprintf('No data...\n');
%         
%     elseif exist(fullfile(diruse{1},'combinedDataTable.mat')) == 2
%         fprintf('combinedDataTable mat file already exists... skipping \n');
        
    else % process the data
        try
            [combinedDataTable, debugTable, timeDomainSettings,powerSettings,...
                fftSettings,eventLogTable, metaData,stimSettingsOut,stimMetaData,stimLogSettings,...
                DetectorSettings,AdaptiveStimSettings,AdaptiveRuns_StimSettings] = DEMO_ProcessRCS(diruse{1});
        catch
        end
    end
end

    disp('DONE!')
%%  Get files from DB load raw data and concatenate 
load(fullfile(scbsdir,[PATIENTID 'database_summary.mat'])) 
D = database_out;

% find the rec # to load 
% recs_to_load = (381:392);
recs_to_load= 401




for r = recs_to_load

DT = load(fullfile(database_out.path{r},'combinedDataTable.mat'))
    
    
end
  
%%  plot power bands

% get rid of nans
% ~isnan(DT.combinedDataTable.Power_Band1)

plot(DT.combinedDataTable.localTime(~isnan(DT.combinedDataTable.Power_Band1)), DT.combinedDataTable.Power_Band1(~isnan(DT.combinedDataTable.Power_Band1)))


%%   Kurtosis find periods of stim

close all
winsize = 3000
noverlap = 0.1
d = data.key1;

k = movwin(d,winsize,noverlap,@kurtosis);
plot(linspace(1,numel(k),numel(d)),d)
hold on
plot(k)
%find periods of stimulation
[p,l]= findpeaks(k,'threshold',0.5,'MinPeakProminence',3)