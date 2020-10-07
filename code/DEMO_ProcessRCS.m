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
% DeviceSettings data
disp('Collecting Device Settings data')
DeviceSettings_fileToLoad = [folderPath filesep 'RawDataTD.json'];
if isfile(DeviceSettings_fileToLoad)
    [timeDomainSettings, powerSettings, fftSettings, metaData] = createDeviceSettingsTable(folderPath);
else
    error('No DeviceSettings.json file')
end
%%
% Stimulation settings



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
disp('Checking for Power Data')
Power_fileToLoad = [folderPath filesep 'RawDataPower.json'];
if isfile(Power_fileToLoad)
    disp('Loading Power Data')
    % Checking if power data is empty happens within createPowerTable
    % function
    [outtable_Power] = createPowerTable(folderPath);
    
    % Calculate power band cutoffs (in Hz) and add column to powerSettings
    if ~isempty(outtable_Power)
        % Translate powerSettings.powerBands into Hz
        numSettings = size(powerSettings,1);
        for iSetting = 1:numSettings
            powerBands_toConvert = powerSettings.powerBands{iSetting};
            currentTDsampleRate = powerSettings.TDsampleRates{iSetting};
            currentFFTconfig = powerSettings.fftConfig{iSetting};
            [currentPowerBands] = getPowerBands(powerBands_toConvert,currentFFTconfig,currentTDsampleRate);
            powerSettings.powerBandsInHz(iSetting) = currentPowerBands;
        end
        
        % Add samplerate and packetsizes column to outtable_Power -- samplerate is inverse
        % of fftConfig.interval; in principle this interval could change
        % over the course of the recording
        
        % Determine if more than one sampling rate across recording
        for iSetting = 1:numSettings
            all_powerFs(iSetting) =  1/((powerSettings.fftConfig{iSetting}.interval)/1000);
        end
        
        if length(unique(all_powerFs)) > 1
            error('More than one sampling rate for power channels -- code development needed')
            % Need to loop through each setting in powerSettings; find
            % closest times between powerSettings and outtable_Power to
            % assign corresponding samplerate
        else
            % Same sample rate for power data for the full file
            powerDomain_sampleRate = unique(all_powerFs);
            outtable_Power.samplerate(:) = powerDomain_sampleRate;
            outtable_Power.packetsizes(:) = 1;
        end
        
        PowerData = assignTime(outtable_Power);
    else
        PowerData = [];
    end
else
    PowerData = [];
end

%%
% FFT data
disp('Checking for FFT Data')
FFT_fileToLoad = [folderPath filesep 'RawDataFFT.json'];
if isfile(FFT_fileToLoad)
    jsonobj_FFT = deserializeJSON(FFT_fileToLoad);
    if ~isempty(jsonobj_FFT.FftData)
        disp('Loading FFT Data')
        outtable_FFT = createFFTtable(jsonobj_FFT);
        
        % Add FFT parameter info to fftSettings
        numSettings = size(fftSettings,1);
        for iSetting = 1:numSettings
            currentFFTconfig = fftSettings.fftConfig{iSetting};
            currentTDsampleRate = fftSettings.TDsampleRates{iSetting};
            fftParameters = getFFTparameters(currentFFTconfig,currentTDsampleRate);
            fftSettings.fftParameters(iSetting) = fftParameters;
        end
        % Add samplerate and packetsizes column to outtable_Power -- samplerate is inverse
        % of fftConfig.interval; in principle this interval could change
        % over the course of the recording
        
        % Determine if more than one sampling rate across recording
        for iSetting = 1:numSettings
            all_powerFs(iSetting) =  1/((fftSettings.fftConfig{iSetting}.interval)/1000);
        end
        
        if length(unique(all_powerFs)) > 1
            error('More than one sampling rate for FFT channels -- code development needed')
            % Need to loop through each setting in fftSettings; find
            % closest times between fftSettings and outtable_FFT to
            % assign corresponding samplerate
        else
            % Same sample rate for FFT data for the full file
            FFT_sampleRate = unique(all_powerFs);
            outtable_FFT.samplerate(:) = FFT_sampleRate;
            outtable_FFT.packetsizes(:) = 1;
        end
        
        disp('Creating derivedTimes for FFT:')
        FFTData = assignTime(outtable_FFT);
    else
        FFTData = [];
    end
else
    FFTData = [];
end

%%
% % Create unified table with all above data stream -- use timeDomain data as
% % time base
%
% derivedTime_TD = timeDomainData.DerivedTime;
%
% % Harmonize Accel with TD
% if ~isempty(AccelData)
%     disp('Harmonizing time of Accelerometer data with Time Domain Data')
%     derivedTime_Accel = AccelData.DerivedTime;
%     [baseTimeIndices_forAccel,indicesToRemove_Accel] = harmonizeTimeAcrossDataStreams(derivedTime_TD, derivedTime_Accel, srates_Accel);
%     % Remove indicesToRemove_Accel from both Accel table and the
%     % baseTimeIndices_forAccel to keep aligned
%     AccelData(indicesToRemove_Accel,:) = [];
%     baseTimeIndices_forAccel(indicesToRemove_Accel) = [];
% end
%
% % Harmonize Power with TD
%
%
% % Harmonize FFT with TD
%
%
% %%
% % Create combined data table
% disp('Creating combined data table')
% combinedDataTable = table();
%
% numRows = length(timeDomainData.DerivedTime);
% % Copy TimeDomain data
% combinedDataTable.DerivedTime = timeDomainData.DerivedTime;
% combinedDataTable.TD0 = timeDomainData.key0;
% if ~isequal(sum(timeDomainData.key1),0)
%     combinedDataTable.TD1 = timeDomainData.key1;
% end
% if ~isequal(sum(timeDomainData.key2),0)
%     combinedDataTable.TD2 = timeDomainData.key2;
% end
% if ~isequal(sum(timeDomainData.key3),0)
%     combinedDataTable.TD3 = timeDomainData.key3;
% end
%
% % Temp for debugging
% TD_systemTick_withNans = timeDomainData.systemTick;
% TD_systemTick_withNans(TD_systemTick_withNans == 0) = NaN;
% combinedDataTable.TD_systemTick = TD_systemTick_withNans;
%
% TD_timestamp_withNans = timeDomainData.timestamp;
% TD_timestamp_withNans(TD_timestamp_withNans == 0) = NaN;
% combinedDataTable.TD_timestamp = TD_timestamp_withNans;
%
% TD_PacketGenTime_withNans = timeDomainData.PacketGenTime;
% TD_PacketGenTime_withNans(TD_PacketGenTime_withNans == 0) = NaN;
% combinedDataTable.TD_PacketGenTime = TD_PacketGenTime_withNans;
%
% % Copy Accel data
% if ~isempty(AccelData)
%     % Add Accel Data at appropriate rows with appropriate TimeDomain DerivedTime
%     combinedDataTable.Accel_X(baseTimeIndices_forAccel) = AccelData.XSamples;
%     combinedDataTable.Accel_Y(baseTimeIndices_forAccel) = AccelData.YSamples;
%     combinedDataTable.Accel_Z(baseTimeIndices_forAccel) = AccelData.ZSamples;
%
%     % Temp for debugging
%     combinedDataTable.Accel_systemTick(baseTimeIndices_forAccel) = AccelData.systemTick;
%     combinedDataTable.Accel_timestamp(baseTimeIndices_forAccel) = AccelData.timestamp;
%     combinedDataTable.Accel_PacketGenTime(baseTimeIndices_forAccel) = AccelData.PacketGenTime;
%
% end
%
% % Change zeros to NaNs (e.g. missing values; values not present)
% disp('Cleaning up combined data table')
% combinedDataTable = standardizeMissing(combinedDataTable,0);
% %%
% % To Do: Save output


end

