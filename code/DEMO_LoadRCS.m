close all
clear all
clc
%%
% Select file
[fileName,pathName] = uigetfile('AllDataTables.mat');

% Load file
disp('Loading selected .mat file')
load([pathName fileName])

% Create unified table with selected data streams -- use timeDomain data as
% time base
dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};
[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);
