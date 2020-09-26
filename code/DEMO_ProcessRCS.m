function [combinedDataTable] = DEMO_ProcessRCS(varargin)
%%
% Demo wrapper script for importing raw .JSON files from RC+S, parsing
% into Matlab table format, and handling missing packets / harmonizing
% timestamps across data streams. Currently assuming you always have
% timeDomain data
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
disp('Checking for Time Domain Data')
TD_fileToLoad = [folderPath filesep 'RawDataTD.json'];
if isfile(TD_fileToLoad)
    jsonobj_TD = deserializeJSON(TD_fileToLoad);
    if ~isempty(jsonobj_TD.TimeDomainData)
        disp('Loading Time Domain Data')
        [outtable_TD, srates_TD] = createTimeDomainTable(jsonobj_TD);
        disp('Creating derivedTimes for time domain:')
        timeDomainData = assignTime(outtable_TD);
    else
        timeDomainData = [];
    end
else
    timeDomainData = [];
end

%%
% Accelerometer data
disp('Checking for Accelerometer Data')
Accel_fileToLoad = [folderPath filesep 'RawDataAccel.json'];
if isfile(Accel_fileToLoad)
    jsonobj_Accel = deserializeJSON(Accel_fileToLoad);
    if ~isempty(jsonobj_Accel.AccelData)
        disp('Loading Accelerometer Data')
        [outtable_Accel, srates_Accel] = createAccelTable(jsonobj_Accel);
        disp('Creating derivedTimes for accelerometer:')
        AccelData = assignTime(outtable_Accel);
    else
        AccelData = [];
    end
else
    AccelData = [];
end

%%
% Power data


%%
% FFT data


%%
% Create unified table with all above data stream -- use timeDomain data as
% time base

% Harmonize Accel with TD


% Harmonize Power with TD


% Harmonize FFT with TD


%%
% Create combined data table


%%
% Save output



end

