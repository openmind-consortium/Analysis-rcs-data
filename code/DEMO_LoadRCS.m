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

% Create equivalent device power -- use timeDomain data as time base
settings = {fftSettings,powerSettings,metaData};
[powerFromTimeDomain] = getPowerFromTimeDomain(combinedDataTable,settings); % outputs default 8 power bands using default power band settings
[newPowerFromTimeDomain, newSettings] = calculateEquivalentDevicePower(combinedDataTable,settings,1,[10 15]); % for 1 time domain channel outputs a new power series given a new band limit