% This is the first attempt at preprocessing RC+S data using the new deserialization pipeline
% This will create combined MAT files for all recording sessions and create
% a database index of all files
%
% MUST USE MATLAB 2019a or earlier (given JSON issue)
%
% Prasad Shirvalkar July 29 2021

clear
clc

PATIENTIDside =  'RCS04R'
% 'RCS02R'
% 'CPRCS01';
rootdir = '/Volumes/DBS Pain 3/' ;
github_dir = '/Users/pshirvalkar/Documents/GitHub/UCSF-rcs-data-analysis';
patientrootdir = fullfile(rootdir,char(regexp(PATIENTIDside,'\w*\d\d','match'))); %match the PATIENTID up to 2 digits: ie RCS02
scbsdir = fullfile(patientrootdir,'/SummitData/SummitContinuousBilateralStreaming/', PATIENTIDside);
adbsdir = fullfile(patientrootdir, '/SummitData/StarrLab/', PATIENTIDside);

cd(github_dir)
addpath(genpath(github_dir))

%% make database of all files
[database_out,badsessions] = makeDataBaseRCSdata(patientrootdir,PATIENTIDside); % add AdaptiveData.Ld0_output

%% compile text logs of all Adaptive/ Stim changes
[textlog] = RCS_logs(rootdir,PATIENTIDside);
 

%%  LOAD Database and Textlogs 
load(fullfile(patientrootdir,[PATIENTIDside '_database.mat'])) 
D = RCSdatabase_out;
load(fullfile(patientrootdir,[PATIENTIDside '_textlogs.mat'])) 


%% now search for when  program D was activated 
% get time stamps for then, and switch to next program.  
% then plot adaptive stim events between those  times 
  textlog.adaptive.time.TimeZone = 'America/Los_Angeles';
  close all
for a = 1:height(textlog.groupchange)-1
    
   if strcmp(textlog.groupchange.group{a},'D')
  
       time1  = textlog.groupchange.time(a);
       time2 = textlog.groupchange.time(a+1);
  	
        adbsIDX{a} = textlog.adaptive.time>= time1 & textlog.adaptive.time < time2;
        if sum(adbsIDX{a})>0
            disp(sum(adbsIDX{a}))
%        plot(textlog.adaptive.detectionStatus(adbsIDX{a}));
%        pause(1)
%        close
%         a
        end
        
   end
   
    
    
end



% Plot
% 1. distribution of powers, with percentiles (with actual threshold over)
% 2. percent of time stim on  
% 3. TEED
% 4. Avg time above and below threshold
% 5. pain scores reported during each segment (group D but also other
% groups/ sessions)
%% Process and load all data - skip if mat already exists

dirsdata = findFilesBVQX(scbsdir,'Sess*',struct('dirs',1,'depth',1));

% find out if a mat file was already created in this folder
% if so, just an update is needed and will not recreate mat file
dbout = [];
for d = 1:numel(dirsdata)
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
                DetectorSettings,AdaptiveStimSettings,AdaptiveRuns_StimSettings] = ProcessRCS(diruse{1});
        catch
        end
    end
end

    disp('DONE!')
%%  Get files from DB and find where group D is active during recording, 
% load raw data and concatenate and plot


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