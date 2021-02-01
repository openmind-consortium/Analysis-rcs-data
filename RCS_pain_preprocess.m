% This is the first attempt at preprocessing RC+S data using the new deserialization pipeline
% This will create combined MAT files for all recording sessions and create
% a database index of all files
%
% MUST USE MATLAB 2019a or earlier (given JSON issue)
%
% Prasad Shirvalkar Nov 11, 2020

clear
clc

PATIENTID = 'RCS02R'
% 'CPRCS01';


rootdir = ['/Volumes/Prasad_X5/' PATIENTID(1:end-1)];
loaddir = [rootdir '/SummitData/SummitContinuousBilateralStreaming/' PATIENTID];
github_dir = '/Users/pshirvalkar/Documents/GitHub/UCSF-rcs-data-analysis';

cd(github_dir)
addpath(genpath(github_dir))

%% make database of all files

T= makeDataBaseRCSdata(loaddir);


%% Process and load all data - skip if mat already exists

dirsdata = findFilesBVQX(loaddir,'Sess*',struct('dirs',1,'depth',1));

% find out if a mat file was already created in this folder
% if so, just an update is needed and will not recreate mat file
dbout = [];
for d = 1:length(dirsdata)
    diruse = findFilesBVQX(dirsdata{d},'Device*',struct('dirs',1,'depth',1));
    
    fprintf('\n \n Reading Session Folder %d of %d  \n',d,length(dirsdata))
    if isempty(diruse) % no data exists inside
        fprintf('No data...\n');
        
    elseif exist(fullfile(diruse{1},'combinedDataTable.mat')) == 2
        fprintf('combinedDataTable mat file already exists... skipping \n');
        
    else % process the data
        try
            [combinedDataTable, debugTable, timeDomainSettings,powerSettings,...
                fftSettings,eventLogTable, metaData,stimSettingsOut,stimMetaData,stimLogSettings,...
                DetectorSettings,AdaptiveStimSettings,AdaptiveRuns_StimSettings] = DEMO_ProcessRCS(diruse{1});
        catch
        end
    end
end

%%  Check if mat file exists, if not, load raw data and save to new matfile




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