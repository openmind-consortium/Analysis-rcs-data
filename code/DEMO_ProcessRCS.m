function [outdatcomplete, srates, unqsrates] = DEMO_ProcessRCS(varargin)
%%
% Demo wrapper script for importing raw .JSON files from RC+S, parsing
% into Matlab table format, and handling missing packets / harmonizing 
% timestamps across data streams.
%
% Depedencies: 
% https://github.com/JimHokanson/turtle_json
% in the a folder called "toolboxes" in the same directory as the processing scripts
%
% Input = RC+S Device folder, containing raw JSON files
%%
if isempty(varargin)
    folderPath = uigetdir();
else
    folderPath  = varargin{1};
end

% JSON files:
% AdaptiveLog.json
% DeviceSettings.json
% DiagnosticLogs.json
% ErrorLog.json
% EventLog.json
% RawDataAccel.json
% RawDataFFT.json
% RawDataPower.json
% RawDataTD.json
% StimLog.json
% TimeSync.json


%%
% TimeDomain data
TD_fileToLoad = [folderPath filesep 'RawDataTD.json'];
if isfile(TD_fileToLoad)
    jsonobj_TD = deserializeJSON(TD_fileToLoad);
    if ~isempty(jsonobj_TD)
        [outtable_TD, srates_TD] = createTimeDomainTable(jsonobj_TD);
        timeDomainData = assignTime(outtable_TD);
    end
end

%%
% Accelerometer data
Accel_fileToLoad = [folderPath filesep 'RawDataAccel.json'];
if isfile(Accel_fileToLoad)
    jsonobj_Accel = deserializeJSON(Accel_fileToLoad);
    if ~isempty(jsonobj_TD)
        [outtable_Accel, srates_Accel] = createAccelTable(jsonobj_Accel);
        AccelData = assignTime(outtable_Accel);
    end
end

%%
% Power data


%%
% FFT data


%%
% Create unified table with all above data stream -- use timeDomain data as
% time base

derivedTime_TD = timeDomainData.DerivedTime;
derivedTime_Accel = AccelData.DerivedTime;

[baseTimeIndices,indicesToRemove] = harmonizeTimeAcrossDataStreams(derivedTime_TD, derivedTime_Accel, srates_Accel);

harmonizedAccelData = AccelData;
harmonizedAccelData.DerivedTime = derivedTime_TD(baseTimeIndices);
harmonizedAccelData(indicesToRemove,:) = [];

%%
% To Do: Create table with all data streams

%%
% To Do: Save output


end

