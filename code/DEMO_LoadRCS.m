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

% Convert sparse matrics (with only time variables) to tables
if ~isempty(timeDomainData_onlyTimeVariables)
    [timeDomainData_onlyTimeVariables] = createTableFromSparseMatrix(timeDomainData_onlyTimeVariables,timeDomain_timeVariableNames);
    timeDomainData_onlyTimeVariables.TimeDomainStream = ones(size(timeDomainData_onlyTimeVariables,1),1);
end

if ~isempty(AccelData_onlyTimeVariables)
    [AccelData_onlyTimeVariables] = createTableFromSparseMatrix(AccelData_onlyTimeVariables,Accel_timeVariableNames);
    AccelData_onlyTimeVariables.AccelStream = ones(size(AccelData_onlyTimeVariables,1),1);
end

if ~isempty(PowerData_onlyTimeVariables)
    [PowerData_onlyTimeVariables] = createTableFromSparseMatrix(PowerData_onlyTimeVariables,Power_timeVariableNames);
    PowerData_onlyTimeVariables.PowerStream = ones(size(PowerData_onlyTimeVariables,1),1);
end

if ~isempty(FFTData_onlyTimeVariables)
    [FFTData_onlyTimeVariables] = createTableFromSparseMatrix(FFTData_onlyTimeVariables,FFT_timeVariableNames);
    FFTData_onlyTimeVariables.FFTStream = ones(size(FFTData_onlyTimeVariables,1),1);
end

if ~isempty(AdaptiveData_onlyTimeVariables)
    [AdaptiveData_onlyTimeVariables] = createTableFromSparseMatrix(AdaptiveData_onlyTimeVariables,Adaptive_timeVariableNames);
    AdaptiveData_onlyTimeVariables.AdaptiveStream = ones(size(AdaptiveData_onlyTimeVariables,1),1);
end

timeDataStreams = {timeDomainData_onlyTimeVariables, AccelData_onlyTimeVariables,...
    PowerData_onlyTimeVariables, FFTData_onlyTimeVariables, AdaptiveData_onlyTimeVariables};

% Create debug table
[debugTable] = createCombinedTable_debugTable(timeDataStreams,unifiedDerivedTimes,metaData);

