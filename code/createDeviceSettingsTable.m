function [TD_SettingsOut, Power_SettingsOut, FFT_SettingsOut, metaData] = createDeviceSettingsTable(folderPath)
%%
% Extract information from DeviceSettings related to configuration for time domain,
% power, and FFT channels. All fields are present in first entry, but subsequent
% entries only have fields which were updated. This function first collects
% all configs, changes in configs, and stream starts/stops times
% (these gets stored in internal variables TD_SettingsTable, Power_SettingsTable, or
% FFT_SettingsTable). Then, go through these tables to create a 'cleaned up'
% version, collecting settings for enabled channels and streams
% (stored in TD_SettingsOut, Power_SettingsOut, FFT_SettingsOut)
%
% Input: Folder path to Device* folder containing json files
% Output: TD_SettingsOut, Power_SettingsOut, FFT_SettingsOut, metaData
%
% Requires convertTDcodes.m
%%
% Load in DeviceSettings.json file
DeviceSettings = jsondecode(fixMalformedJson(fileread([folderPath filesep 'DeviceSettings.json']),'DeviceSettings'));
%%
% Fix format - Sometimes device settings is a struct or cell array
if isstruct(DeviceSettings)
    DeviceSettings = {DeviceSettings};
end
%%
% Convert metaData variables into human readable
metaData = convertMetadataCodes(DeviceSettings{1}.SubjectInfo);

% UTC offset to determine timezone conversion
metaData.UTCoffset = DeviceSettings{1,1}.UtcOffset;

% Battery information, as of beginning of the current recording
metaData.batteryLevelPercent = DeviceSettings{1}.BatteryStatus.batteryLevelPercent;
metaData.batteryVoltage = DeviceSettings{1}.BatteryStatus.batteryVoltage;
metaData.estimatedCapacity = DeviceSettings{1}.BatteryStatus.estimatedCapacity;
metaData.batterySOC = DeviceSettings{1}.BatteryStatus.batterySOC;

%%
TD_SettingsTable = table(); % Initalize table
Power_SettingsTable = table(); % Initalize table
FFT_SettingsTable = table(); % Initalize table

recordCounter = 1; % Initalize counter for records in DeviceSetting

inStream_TD = 0; % Initalize as streaming off
inStream_Power = 0; % Initalize as streaming off
inStream_FFT = 0; % Initalize as streaming off

changeToInStream = 0;
streamStartCounter_TD = 1; % Initalize counter for streaming starts
streamStopCounter_TD = 1; % Initalize counter for streaming stops
streamStartCounter_Power = 1; % Initalize counter for streaming starts
streamStopCounter_Power = 1; % Initalize counter for streaming stops
streamStartCounter_FFT = 1; % Initalize counter for streaming starts
streamStopCounter_FFT = 1; % Initalize counter for streaming stops
TDsettings = [];
powerChannels = [];
fftConfig = [];

while recordCounter <= length(DeviceSettings)
    currentSettings = DeviceSettings{recordCounter};
    
    % Check if SensingConfig was updated
    if isfield(currentSettings,'SensingConfig')
        
        % If timeDomain updated in this record, create
        % new row in TD_SettingsTable and populate with metadata
        if isfield(currentSettings.SensingConfig,'timeDomainChannels')
            % Gather data for creating new row in table
            actionType = 'Sense Config';
            recNum = NaN;
            % Settings will remain in TDsettings until updated
            [newEntry, TDsettings] = addNewEntry_TimeDomainSettings(actionType,recNum,currentSettings,TDsettings);
            TD_SettingsTable = addRowToTable(newEntry,TD_SettingsTable);
        end
        
        % If power domain updated in this record, create
        % new row in Power_SettingsTable and populate with metadata
        if isfield(currentSettings.SensingConfig,'powerChannels')
            % Gather data for creating new row in table
            actionType = 'Sense Config';
            recNum = NaN;
            [newEntry, powerChannels, fftConfig] = addNewEntry_PowerDomainSettings(actionType,...
                recNum,currentSettings,TDsettings,powerChannels,fftConfig);
            % This populates information about the powerBands. The bipolar channels associated with the
            % bands are defined above (from timeDomainChannels). Sense chan1: Bands
            % 1-2, sense chan2: Bands 3-4, Sense chan3: Bands 5-6, Sense
            % chan4: Bands 7-8
            
            % Settings will remain in powerChannels and fftConfig until
            % updated; fftConfig needed in later processing for
            % determinig powerBands
            
            Power_SettingsTable = addRowToTable(newEntry,Power_SettingsTable);
        end
        
        % If FFT updated in this record, create
        % new row in FFT_SettingsTable and populate with metadata
        if isfield(currentSettings.SensingConfig,'fftConfig')
            % Gather data for creating new row in table
            actionType = 'Sense Config';
            recNum = NaN;
            [newEntry, fftConfig] = addNewEntry_FFTSettings(actionType,recNum,currentSettings,TDsettings,fftConfig);
            FFT_SettingsTable = addRowToTable(newEntry,FFT_SettingsTable);
        end
    end
    %%
    % Check if streaming has been turned on
    % (TDsettings, powerChannels, and fftConfig should have all been populated
    % with something because first record should have all variables)
    if isfield(currentSettings,'StreamState')
        % TIME DOMAIN
        if currentSettings.StreamState.TimeDomainStreamEnabled && ~inStream_TD % If not already inStream, then streaming is starting
            % Create new entry for TD_SettingsTable and populate with metadata
            actionType = sprintf('Start Stream TD %d',streamStartCounter_TD);
            recNum = streamStartCounter_TD;
            [newEntry, TDsettings] = addNewEntry_TimeDomainSettings(actionType,recNum,currentSettings,TDsettings);
            TD_SettingsTable = addRowToTable(newEntry,TD_SettingsTable);
            
            streamStartCounter_TD = streamStartCounter_TD + 1;
            inStream_TD = 1;
        end
        
        % POWER DOMAIN
        if currentSettings.StreamState.PowerDomainStreamEnabled && ~inStream_Power % If not already inStream, then streaming is starting
            % Create new entry for Power_SettingsTable and populate with metadata
            actionType = sprintf('Start Stream Power %d',streamStartCounter_Power);
            recNum = streamStartCounter_Power;
            [newEntry,powerChannels,fftConfig] = addNewEntry_PowerDomainSettings(actionType,...
                recNum,currentSettings,TDsettings,powerChannels,fftConfig);
            Power_SettingsTable = addRowToTable(newEntry,Power_SettingsTable);
            
            streamStartCounter_Power = streamStartCounter_Power + 1;
            inStream_Power = 1;
        end
        
        % FFT
        if currentSettings.StreamState.FftStreamEnabled && ~inStream_FFT % If not already inStream, then streaming is starting
            % Create new entry for FFT_SettingsTable and populate with metadata
            actionType = sprintf('Start Stream FFT %d',streamStartCounter_FFT);
            recNum = streamStartCounter_FFT;
            [newEntry,fftConfig] = addNewEntry_FFTSettings(actionType,recNum,currentSettings,TDsettings,fftConfig);
            FFT_SettingsTable = addRowToTable(newEntry,FFT_SettingsTable);
            
            streamStartCounter_FFT = streamStartCounter_FFT + 1;
            inStream_FFT = 1;
        end
    end
    %%
    % Check if streaming has been stopped - this can be done by turning
    % streaming off, by turning sensing off, or by ending the session.
    % Use the same counter across the first two methods.
    
    % Option 1: Check if streaming has been stopped
    if isfield(currentSettings,'StreamState')
        
        % TIME DOMAIN
        if inStream_TD && ~currentSettings.StreamState.TimeDomainStreamEnabled
            actionType = sprintf('Stop Stream TD %d',streamStopCounter_TD);
            recNum = streamStopCounter_TD;
            [newEntry, TDsettings] = addNewEntry_TimeDomainSettings(actionType,recNum,currentSettings,TDsettings);
            TD_SettingsTable = addRowToTable(newEntry,TD_SettingsTable);
            
            inStream_TD = 0;
            streamStopCounter_TD = streamStopCounter_TD + 1;
        end
        
        % POWER DOMAIN
        if inStream_Power && ~currentSettings.StreamState.PowerDomainStreamEnabled
            actionType = sprintf('Stop Stream Power %d',streamStopCounter_Power);
            recNum = streamStopCounter_Power;
            [newEntry,powerChannels,fftConfig] = addNewEntry_PowerDomainSettings(actionType,...
                recNum,currentSettings,TDsettings,powerChannels,fftConfig);
            Power_SettingsTable = addRowToTable(newEntry,Power_SettingsTable);
            
            inStream_Power = 0;
            streamStopCounter_Power = streamStopCounter_Power + 1;
        end
        
        % FFT
        if inStream_FFT && ~currentSettings.StreamState.FftStreamEnabled
            actionType = sprintf('Stop Stream FFT %d',streamStopCounter_FFT);
            recNum = streamStopCounter_FFT;
            [newEntry,fftConfig] = addNewEntry_FFTSettings(actionType,recNum,currentSettings,TDsettings,fftConfig);
            FFT_SettingsTable = addRowToTable(newEntry,FFT_SettingsTable);
            
            inStream_FFT = 0;
            streamStopCounter_FFT = streamStopCounter_FFT + 1;
        end
    end
    
    % Option 2: Check if sense has been turned off
    if isfield(currentSettings,'SenseState')
        
        if isfield(currentSettings.SenseState,'state')
            senseState = dec2bin(currentSettings.SenseState.state,8);
        end
        
        % TIME DOMAIN
        if inStream_TD && isfield(currentSettings.SenseState,'state')
            % Check starting/stopping of time domain streaming. See
            % documentation enum Medtronic.NeuroStim.Olympus.DataTypes.Sensing.SenseStates : byte
            % for more details about binary number coding
            if str2double(senseState) == 0 % streaming off
                % Create new row in deviceSettingsTable and populate with metadata
                actionType = sprintf('Stop Sense TD %d',streamStopCounter_TD);
                recNum = streamStopCounter_TD;
                [newEntry, TDsettings] = addNewEntry_TimeDomainSettings(actionType,recNum,currentSettings,TDsettings);
                TD_SettingsTable = addRowToTable(newEntry,TD_SettingsTable);
                
                inStream_TD = 0;
                streamStopCounter_TD = streamStopCounter_TD + 1;
            end
        end
        
        % POWER DOMAIN
        if inStream_Power && isfield(currentSettings.SenseState,'state')
            % Check starting/stopping of time domain streaming. See
            % documentation enum Medtronic.NeuroStim.Olympus.DataTypes.Sensing.SenseStates : byte
            % for more details about binary number coding
            % Same code for all streams to indicate sense off
            if str2double(senseState) == 0 % streaming off
                % Create new row in deviceSettingsTable and populate with metadata
                actionType = sprintf('Stop Sense Power %d',streamStopCounter_Power);
                recNum = streamStopCounter_Power;
                [newEntry,powerChannels,fftConfig] = addNewEntry_PowerDomainSettings(actionType,...
                    recNum,currentSettings,TDsettings,powerChannels,fftConfig);
                Power_SettingsTable = addRowToTable(newEntry,Power_SettingsTable);
                
                inStream_Power = 0;
                streamStopCounter_Power = streamStopCounter_Power + 1;
            end
            
        end
        
        % FFT
        if inStream_FFT && isfield(currentSettings.SenseState,'state')
            % Check starting/stopping of time domain streaming. See
            % documentation enum Medtronic.NeuroStim.Olympus.DataTypes.Sensing.SenseStates : byte
            % for more details about binary number coding
            
            % Same code for all streams to indicate sense off
            if str2double(senseState) == 0 % streaming off
                % Create new row in deviceSettingsTable and populate with metadata
                actionType = sprintf('Stop Sense FFT %d',streamStopCounter_FFT);
                recNum = streamStopCounter_FFT;
                [newEntry,fftConfig] = addNewEntry_FFTSettings(actionType,recNum,currentSettings,TDsettings,fftConfig);
                FFT_SettingsTable = addRowToTable(newEntry,FFT_SettingsTable);
                
                inStream_FFT = 0;
                streamStopCounter_FFT = streamStopCounter_FFT + 1;
            end
        end
    end
    
    % Option 3: If last record, get HostUnixTime (can use in cases where no stop time
    % was recorded)
    if recordCounter == length(DeviceSettings)
        % TIME DOMAIN
        actionType = sprintf('Last record');
        recNum = NaN;
        [newEntry, TDsettings] = addNewEntry_TimeDomainSettings(actionType,recNum,currentSettings,TDsettings);
        TD_SettingsTable = addRowToTable(newEntry,TD_SettingsTable);
        
        % POWER DOMAIN
        actionType = sprintf('Last record');
        recNum = NaN;
        [newEntry,powerChannels,fftConfig] = addNewEntry_PowerDomainSettings(actionType,...
            recNum,currentSettings,TDsettings,powerChannels,fftConfig);
        Power_SettingsTable = addRowToTable(newEntry,Power_SettingsTable);
        
        % FFT
        actionType = sprintf('Last record');
        recNum = NaN;
        [newEntry,fftConfig] = addNewEntry_FFTSettings(actionType,recNum,currentSettings,TDsettings,fftConfig);
        FFT_SettingsTable = addRowToTable(newEntry,FFT_SettingsTable);
        
    end
    recordCounter = recordCounter + 1;
end

%%
% Loop through each SettingsTable (TD_SettingsTable, Power_SettingsTable,
% and FFT_SettingsTable) to determine start and stop time for each
% recording segment in the file. deviceSettingOutput pulls relevant
% information from deviceSettingsTable, only taking information about data
% which was streamed

% Extract timing info and metadata about each recording chunk. Recording chunks are defined as
% having a start and stop time in the deviceSettingsTable; the last
% recording chunk in the file can use the last record time as the stop
% time.

%%
% TIME DOMAIN
TD_SettingsOut = table();

% Indices in table of start/stop actions
indices = ~isnan(TD_SettingsTable.recNum);
recordingChunks = unique(TD_SettingsTable.recNum(indices));

for iChunk = 1:length(recordingChunks)
    currentIndices = TD_SettingsTable.recNum == recordingChunks(iChunk);
    selectData = TD_SettingsTable(currentIndices,:);
    missingTime = 0;
    
    % If not the last chunk in the file, check for two times (assuming
    % start and stop times). Lack of two times indicates something wrong
    % with streaming - do not keep these data
    if size(selectData,1) ~= 2 && iChunk < length(recordingChunks)
        warning('Streaming of time domain data does not have one start and one stop time')
        missingTime = 1;
    else
        % Check that first time is a start time
        if contains(selectData.action{1},'Start')
            timeStart = selectData.time(1);
        else
            warning('Streaming of time domain data does not have start time')
            missingTime = 1;
        end
        
        % Check that second time is a stop time, or if last chunk can
        % have stop time missing and use 'last record' time
        if iChunk == length(recordingChunks) && size(selectData,1) ~= 2
            timeStop = TD_SettingsTable.time(end);
        else
            if contains(selectData.action{2},'Stop')
                timeStop = selectData.time(2);
            else
                warning('Streaming of time domain data does not have stop time')
                missingTime = 1;
            end
        end
        
        % If no missing start or stop time, populate deviceSettingsOut
        if missingTime == 0
            toAdd.recNum = recordingChunks(iChunk);
            toAdd.duration = timeStop - timeStart;
            toAdd.timeStart = timeStart;
            toAdd.timeStop = timeStop;
            
            % Loop through all TD channels to get sampling rate and acquistion parameters
            for iChan = 1:4
                if ~strcmp(selectData.tdDataStruc{1}(iChan).sampleRate,'disabled') &&...
                        ~strcmp(selectData.tdDataStruc{1}(iChan).sampleRate,'unexpected')
                    toAdd.samplingRate = selectData.tdDataStruc{1}(iChan).sampleRate;
                    fieldName = sprintf('chan%d',iChan);
                    toAdd.(fieldName) = selectData.(fieldName){1};
                else
                    fieldName = sprintf('chan%d',iChan);
                    toAdd.(fieldName) = NaN;
                end
            end
            toAdd.TDsettings = selectData.tdDataStruc{1};
            
            if isempty(TD_SettingsOut)
                TD_SettingsOut = struct2table(toAdd,'AsArray',true);
            else
                TD_SettingsOut = [TD_SettingsOut; struct2table(toAdd,'AsArray',true)];
            end
            clear toAdd
        end
    end
end
%%
% POWER DOMAIN
Power_SettingsOut = table();

% Indices in table of start/stop actions
indices = ~isnan(Power_SettingsTable.recNum);
recordingChunks = unique(Power_SettingsTable.recNum(indices));

for iChunk = 1:length(recordingChunks)
    currentIndices = Power_SettingsTable.recNum == recordingChunks(iChunk);
    selectData = Power_SettingsTable(currentIndices,:);
    missingTime = 0;
    
    % If not the last chunk in the file, check for two times (assuming
    % start and stop times). Lack of two times indicates something wrong
    % with streaming - do not keep these data
    if size(selectData,1) ~= 2 && iChunk < length(recordingChunks)
        warning('Streaming of power data does not have one start and one stop time')
        missingTime = 1;
    else
        % Check that first time is a start time
        if contains(selectData.action{1},'Start')
            timeStart = selectData.time(1);
        else
            warning('Streaming of power data does not have start time')
            missingTime = 1;
        end
        
        % Check that second time is a stop time, or if last chunk can
        % have stop time missing and use 'last record' time
        if iChunk == length(recordingChunks) && size(selectData,1) ~= 2
            timeStop = Power_SettingsTable.time(end);
        else
            if contains(selectData.action{2},'Stop')
                timeStop = selectData.time(2);
            else
                warning('Streaming of power data does not have stop time')
                missingTime = 1;
            end
        end
        
        % If no missing start or stop time, populate deviceSettingsOut
        if missingTime == 0
            toAdd.recNum = recordingChunks(iChunk);
            toAdd.duration = timeStop - timeStart;
            toAdd.timeStart = timeStart;
            toAdd.timeStop = timeStop;
            
            toAdd.powerBands = selectData.powerBands(1);
            toAdd.TDsampleRates = selectData.TDsampleRates(1);
            toAdd.fftConfig = selectData.fftConfig(1);
            
            if isempty(Power_SettingsOut)
                Power_SettingsOut = struct2table(toAdd,'AsArray',true);
            else
                Power_SettingsOut = [Power_SettingsOut; struct2table(toAdd,'AsArray',true)];
            end
            clear toAdd
        end
    end
end

%%
% FFT DATA
FFT_SettingsOut = table();

% Indices in table of start/stop actions
indices = ~isnan(FFT_SettingsTable.recNum);
recordingChunks = unique(FFT_SettingsTable.recNum(indices));

if isempty(recordingChunks)
    % Indicates that FFT was not enabled for streaming, but may still want
    % FFT config info (i.e. if adaptive was enabled) -- take this info from
    % first record
    selectData = FFT_SettingsTable(1,:);
    toAdd.recNum = NaN;
    toAdd.duration = NaN;
    toAdd.timeStart = NaN;
    toAdd.timeStop = NaN;
    toAdd.fftConfig = selectData.fftConfig(1);
    toAdd.TDsampleRates = selectData.TDsampleRates(1);
    
    FFT_SettingsOut = struct2table(toAdd,'AsArray',true);
else
    for iChunk = 1:length(recordingChunks)
        currentIndices = FFT_SettingsTable.recNum == recordingChunks(iChunk);
        selectData = FFT_SettingsTable(currentIndices,:);
        missingTime = 0;
        
        % If not the last chunk in the file, check for two times (assuming
        % start and stop times). Lack of two times indicates something wrong
        % with streaming - do not keep these data
        if size(selectData,1) ~= 2 && iChunk < length(recordingChunks)
            warning('Streaming of FFT data does not have one start and one stop time')
            missingTime = 1;
        else
            % Check that first time is a start time
            if contains(selectData.action{1},'Start')
                timeStart = selectData.time(1);
            else
                warning('Streaming of FFT data does not have start time')
                missingTime = 1;
            end
            
            % Check that second time is a stop time, or if last chunk can
            % have stop time missing and use 'last record' time
            if iChunk == length(recordingChunks) && size(selectData,1) ~= 2
                timeStop = FFT_SettingsTable.time(end);
            else
                if contains(selectData.action{2},'Stop')
                    timeStop = selectData.time(2);
                else
                    warning('Streaming of FFT data does not have stop time')
                    missingTime = 1;
                end
            end
            
            % If no missing start or stop time, populate deviceSettingsOut
            if missingTime == 0
                toAdd.recNum = recordingChunks(iChunk);
                toAdd.duration = timeStop - timeStart;
                toAdd.timeStart = timeStart;
                toAdd.timeStop = timeStop;
                toAdd.fftConfig = selectData.fftConfig(1);
                toAdd.TDsampleRates = selectData.TDsampleRates(1);
                
                if isempty(FFT_SettingsOut)
                    FFT_SettingsOut = struct2table(toAdd,'AsArray',true);
                else
                    FFT_SettingsOut = [FFT_SettingsOut; struct2table(toAdd,'AsArray',true)];
                end
                clear toAdd
            end
        end
    end
end
