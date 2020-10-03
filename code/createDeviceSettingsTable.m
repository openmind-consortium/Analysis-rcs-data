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
entryNumber_TD = 1; % Initialize counter for populating entries to table
entryNumber_Power = 1; % Initialize counter for populating entries to table
entryNumber_FFT = 1; % Initialize counter for populating entries to table

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

while recordCounter <= length(DeviceSettings)
    currentSettings = DeviceSettings{recordCounter};
    
    % Check if SensingConfig was updated
    if isfield(currentSettings,'SensingConfig')
        
        % If timeDomain updated in this record, create
        % new row in TD_SettingsTable and populate with metadata
        if isfield(currentSettings.SensingConfig,'timeDomainChannels')
            HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
            TD_SettingsTable.action{entryNumber_TD} = 'Sense Config';
            TD_SettingsTable.recNum(entryNumber_TD) = NaN;
            TD_SettingsTable.time{entryNumber_TD} = HostUnixTime;
            
            % Settings will remain in TDsettings until updated
            TDsettings = convertTDcodes(currentSettings.SensingConfig.timeDomainChannels);
            for iChan = 1:4
                fieldName = sprintf('chan%d',iChan);
                TD_SettingsTable.(fieldName){entryNumber_TD} = TDsettings(iChan).chanFullStr;
            end
            TD_SettingsTable.tdDataStruc{entryNumber_TD} = TDsettings;
            
            entryNumber_TD = entryNumber_TD + 1;
        end
        
        % If power domain updated in this record, create
        % new row in Power_SettingsTable and populate with metadata
        if isfield(currentSettings.SensingConfig,'powerChannels')
            HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
            Power_SettingsTable.action{entryNumber_Power} = 'Sense Config';
            Power_SettingsTable.recNum(entryNumber_Power) = NaN;
            Power_SettingsTable.time{entryNumber_Power} = HostUnixTime;
            
            % This populates information about the powerBands (coded
            % values, not in Hz). The bipolar channels associated with the
            % bands are defined above (from timeDomainChannels). Sense chan1: Bands
            % 1-2, sense chan2: Bands 3-4, Sense chan3: Bands 5-6, Sense
            % chan4: Bands 7-8
            
            % Settings will remain in powerChannels, TDsampleRate, and fftConfig until
            % updated; TDsampleRate and fftConfig needed in later processing for
            % determinig powerBands
            powerChannels = currentSettings.SensingConfig.powerChannels;
            Power_SettingsTable.powerBands{entryNumber_Power} = powerChannels;
            
            % Get sample rate for each TD channel
            for iChan = 1:4
                TDsampleRates(iChan) = str2double(TDsettings(iChan).sampleRate(1:end-2));
            end
            Power_SettingsTable.TDsampleRates{entryNumber_Power} = TDsampleRates;
            
            % Get fftConfig info if updated
            if isfield(currentSettings.SensingConfig,'fftConfig')
                fftConfig = currentSettings.SensingConfig.fftConfig;
            end
            Power_SettingsTable.fftConfig(entryNumber_Power) = fftConfig;
            
            entryNumber_Power = entryNumber_Power + 1;
        end
        
        % If FFT updated in this record, create
        % new row in FFT_SettingsTable and populate with metadata
        if isfield(currentSettings.SensingConfig,'fftConfig')
            HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
            FFT_SettingsTable.action{entryNumber_FFT} = 'Sense Config';
            FFT_SettingsTable.recNum(entryNumber_FFT) = NaN;
            FFT_SettingsTable.time{entryNumber_FFT} = HostUnixTime;
            
            % Settings will remain in fftConfig until updated
            fftConfig = currentSettings.SensingConfig.fftConfig;
            FFT_SettingsTable.FFTbandFormationConfig(entryNumber_FFT) = fftConfig.bandFormationConfig;
            FFT_SettingsTable.FFTconfig(entryNumber_FFT) = fftConfig.config;
            FFT_SettingsTable.FFTinterval(entryNumber_FFT) = fftConfig.interval;
            FFT_SettingsTable.FFTsize(entryNumber_FFT) = fftConfig.size;
            FFT_SettingsTable.FFTstreamOffsetBins(entryNumber_FFT) = fftConfig.streamOffsetBins;
            FFT_SettingsTable.FFTstreamSizeBins(entryNumber_FFT) = fftConfig.streamSizeBins;
            FFT_SettingsTable.FFTwindowLoad(entryNumber_FFT) = fftConfig.windowLoad;
            
            entryNumber_FFT = entryNumber_FFT + 1;
        end
    end
    %%
    % Check if streaming has been turned on
    % (TDsettings, powerChannels, and fftConfig should have all been populated
    % with something because first record should have all variables)
    if isfield(currentSettings,'StreamState')
        % TIME DOMAIN
        if currentSettings.StreamState.TimeDomainStreamEnabled && ~inStream_TD % If not already inStream, then streaming is starting
            % Create new row in TD_SettingsTable and populate with metadata
            HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
            TD_SettingsTable.action{entryNumber_TD} = sprintf('Start Stream TD %d',streamStartCounter_TD);
            TD_SettingsTable.recNum(entryNumber_TD) = streamStartCounter_TD;
            TD_SettingsTable.time{entryNumber_TD} = HostUnixTime;
            
            % Time domain info
            % Fill in most recent time domain data settings
            for iChan = 1:4
                fieldName = sprintf('chan%d',iChan);
                TD_SettingsTable.(fieldName){entryNumber_TD} = TDsettings(iChan).chanFullStr;
            end
            TD_SettingsTable.tdDataStruc{entryNumber_TD} = TDsettings;
            
            streamStartCounter_TD = streamStartCounter_TD + 1;
            entryNumber_TD = entryNumber_TD + 1;
            inStream_TD = 1;
        end
        
        % POWER DOMAIN
        if currentSettings.StreamState.PowerDomainStreamEnabled && ~inStream_Power % If not already inStream, then streaming is starting
            % Create new row in Power_SettingsTable and populate with metadata
            HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
            Power_SettingsTable.action{entryNumber_Power} = sprintf('Start Stream Power %d',streamStartCounter_Power);
            Power_SettingsTable.recNum(entryNumber_Power) = streamStartCounter_Power;
            Power_SettingsTable.time{entryNumber_Power} = HostUnixTime;
            
            % Power domain info
            Power_SettingsTable.powerBands{entryNumber_Power} = powerChannels;
            for iChan = 1:4
                TDsampleRates(iChan) = str2double(TDsettings(iChan).sampleRate(1:end-2));
            end
            Power_SettingsTable.TDsampleRates{entryNumber_Power} = TDsampleRates;
            Power_SettingsTable.fftConfig(entryNumber_Power) = fftConfig;
            
            streamStartCounter_Power = streamStartCounter_Power + 1;
            entryNumber_Power = entryNumber_Power + 1;
            inStream_Power = 1;
        end
        
        % FFT
        if currentSettings.StreamState.FftStreamEnabled && ~inStream_FFT % If not already inStream, then streaming is starting
            % Create new row in FFT_SettingsTable and populate with metadata
            HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
            FFT_SettingsTable.action{entryNumber_FFT} = sprintf('Start Stream FFT %d',streamStartCounter_FFT);
            FFT_SettingsTable.recNum(entryNumber_FFT) = streamStartCounter_FFT;
            FFT_SettingsTable.time{entryNumber_FFT} = HostUnixTime;
            
            % FFT info
            FFT_SettingsTable.FFTbandFormationConfig(entryNumber_FFT) = fftConfig.bandFormationConfig;
            FFT_SettingsTable.FFTconfig(entryNumber_FFT) = fftConfig.config;
            FFT_SettingsTable.FFTinterval(entryNumber_FFT) = fftConfig.interval;
            FFT_SettingsTable.FFTsize(entryNumber_FFT) = fftConfig.size;
            FFT_SettingsTable.FFTstreamOffsetBins(entryNumber_FFT) = fftConfig.streamOffsetBins;
            FFT_SettingsTable.FFTstreamSizeBins(entryNumber_FFT) = fftConfig.streamSizeBins;
            FFT_SettingsTable.FFTwindowLoad(entryNumber_FFT) = fftConfig.windowLoad;
            
            streamStartCounter_FFT = streamStartCounter_FFT + 1;
            entryNumber_FFT = entryNumber_FFT + 1;
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
            HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
            TD_SettingsTable.action{entryNumber_TD} = sprintf('Stop Stream TD %d',streamStopCounter_TD);
            TD_SettingsTable.recNum(entryNumber_TD) = streamStopCounter_TD;
            TD_SettingsTable.time{entryNumber_TD} = HostUnixTime;
            
            % Fill in most recent time domain data settings
            for iChan = 1:4
                fieldName = sprintf('chan%d',iChan);
                TD_SettingsTable.(fieldName){entryNumber_TD} = TDsettings(iChan).chanFullStr;
            end
            TD_SettingsTable.tdDataStruc{entryNumber_TD} = TDsettings;
            
            inStream_TD = 0;
            streamStopCounter_TD = streamStopCounter_TD + 1;
            entryNumber_TD = entryNumber_TD + 1;
            
        end
        
        % POWER DOMAIN
        if inStream_Power && ~currentSettings.StreamState.PowerDomainStreamEnabled
            HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
            Power_SettingsTable.action{entryNumber_Power} = sprintf('Stop Stream Power %d',streamStopCounter_Power);
            Power_SettingsTable.recNum(entryNumber_Power) = streamStopCounter_Power;
            Power_SettingsTable.time{entryNumber_Power} = HostUnixTime;
            
            % Fill in most recent power domain settings
            Power_SettingsTable.powerBands{entryNumber_Power} = powerChannels;
            for iChan = 1:4
                TDsampleRates(iChan) = str2double(TDsettings(iChan).sampleRate(1:end-2));
            end
            Power_SettingsTable.TDsampleRates{entryNumber_Power} = TDsampleRates;
            Power_SettingsTable.fftConfig(entryNumber_Power) = fftConfig;
            
            inStream_Power = 0;
            streamStopCounter_Power = streamStopCounter_Power + 1;
            entryNumber_Power = entryNumber_Power + 1;
            
        end
        
        % FFT
        if inStream_FFT && ~currentSettings.StreamState.FftStreamEnabled
            HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
            FFT_SettingsTable.action{entryNumber_FFT} = sprintf('Stop Stream FFT %d',streamStopCounter_FFT);
            FFT_SettingsTable.recNum(entryNumber_FFT) = streamStopCounter_FFT;
            FFT_SettingsTable.time{entryNumber_FFT} = HostUnixTime;
            
            % Fill in most recent FFT settings
            FFT_SettingsTable.FFTbandFormationConfig(entryNumber_FFT) = fftConfig.bandFormationConfig;
            FFT_SettingsTable.FFTconfig(entryNumber_FFT) = fftConfig.config;
            FFT_SettingsTable.FFTinterval(entryNumber_FFT) = fftConfig.interval;
            FFT_SettingsTable.FFTsize(entryNumber_FFT) = fftConfig.size;
            FFT_SettingsTable.FFTstreamOffsetBins(entryNumber_FFT) = fftConfig.streamOffsetBins;
            FFT_SettingsTable.FFTstreamSizeBins(entryNumber_FFT) = fftConfig.streamSizeBins;
            FFT_SettingsTable.FFTwindowLoad(entryNumber_FFT) = fftConfig.windowLoad;
            
            inStream_FFT = 0;
            streamStopCounter_FFT = streamStopCounter_FFT + 1;
            entryNumber_FFT = entryNumber_FFT + 1;
        end
    end
    
    % Option 2: Check if sense has been turned off
    if isfield(currentSettings,'SenseState')
        % TIME DOMAIN
        if inStream_TD && isfield(currentSettings.SenseState,'state')
            senseState = dec2bin(currentSettings.SenseState.state,4);
            % Check starting/stopping of time domain streaming. See
            % documentation enum Medtronic.NeuroStim.Olympus.DataTypes.Sensing.SenseStates : byte
            % for more details about binary number coding
            
            if strcmp(senseState(4),'0') % Time domain streaming is off
                % Create new row in deviceSettingsTable and populate with metadata
                HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
                TD_SettingsTable.action{entryNumber_TD} = sprintf('Stop Sense TD %d',streamStopCounter_TD);
                TD_SettingsTable.recNum(entryNumber_TD) = streamStopCounter_TD;
                TD_SettingsTable.time{entryNumber_TD} = HostUnixTime;
                
                % Fill in most recent time domain data settings
                for iChan = 1:4
                    fieldName = sprintf('chan%d',iChan);
                    TD_SettingsTable.(fieldName){entryNumber_TD} = TDsettings(iChan).chanFullStr;
                end
                TD_SettingsTable.tdDataStruc{entryNumber_TD} = TDsettings;
                inStream_TD = 0;
                streamStopCounter_TD = streamStopCounter_TD + 1;
                entryNumber_TD = entryNumber_TD + 1;
            end
        end
        
        % POWER DOMAIN
        if inStream_Power && isfield(currentSettings.SenseState,'state')
            % KS UPDATE LINE BELOW/ABOVE
            senseState = dec2bin(currentSettings.SenseState.state,4);
            % Check starting/stopping of time domain streaming. See
            % documentation enum Medtronic.NeuroStim.Olympus.DataTypes.Sensing.SenseStates : byte
            % for more details about binary number coding
            
            % KS UPDATE LINE BELOW
            if strcmp(senseState(4),'0') % Time domain streaming is off
                % Create new row in deviceSettingsTable and populate with metadata
                HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
                Power_SettingsTable.action{entryNumber_Power} = sprintf('Stop Sense Power %d',streamStopCounter_Power);
                Power_SettingsTable.recNum(entryNumber_Power) = streamStopCounter_Power;
                Power_SettingsTable.time{entryNumber_Power} = HostUnixTime;
                
                % Fill in most recent power domain settings
                Power_SettingsTable.powerBands{entryNumber_Power} = powerChannels;
                for iChan = 1:4
                    TDsampleRates(iChan) = str2double(TDsettings(iChan).sampleRate(1:end-2));
                end
                Power_SettingsTable.TDsampleRates{entryNumber_Power} = TDsampleRates;
                Power_SettingsTable.fftConfig(entryNumber_Power) = fftConfig;
                
                inStream_Power = 0;
                streamStopCounter_Power = streamStopCounter_Power + 1;
                entryNumber_Power = entryNumber_Power + 1;
            end
            
        end
        
        % FFT
        if inStream_FFT && isfield(currentSettings.SenseState,'state')
            % KS UPDATE SENSE STATE
            senseState = dec2bin(currentSettings.SenseState.state,4);
            % Check starting/stopping of time domain streaming. See
            % documentation enum Medtronic.NeuroStim.Olympus.DataTypes.Sensing.SenseStates : byte
            % for more details about binary number coding
            
            % KS IF STATEMENT MUST BE UPDATED
            if strcmp(senseState(4),'0') % Time domain streaming is off
                % Create new row in deviceSettingsTable and populate with metadata
                HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
                FFT_SettingsTable.action{entryNumber_FFT} = sprintf('Stop Sense FFT %d',streamStopCounter_FFT);
                FFT_SettingsTable.recNum(entryNumber_FFT) = streamStopCounter_FFT;
                FFT_SettingsTable.time{entryNumber_FFT} = HostUnixTime;
                
                % Fill in most recent FFT settings
                FFT_SettingsTable.FFTbandFormationConfig(entryNumber_FFT) = fftConfig.bandFormationConfig;
                FFT_SettingsTable.FFTconfig(entryNumber_FFT) = fftConfig.config;
                FFT_SettingsTable.FFTinterval(entryNumber_FFT) = fftConfig.interval;
                FFT_SettingsTable.FFTsize(entryNumber_FFT) = fftConfig.size;
                FFT_SettingsTable.FFTstreamOffsetBins(entryNumber_FFT) = fftConfig.streamOffsetBins;
                FFT_SettingsTable.FFTstreamSizeBins(entryNumber_FFT) = fftConfig.streamSizeBins;
                FFT_SettingsTable.FFTwindowLoad(entryNumber_FFT) = fftConfig.windowLoad;
                
                inStream_FFT = 0;
                streamStopCounter_FFT = streamStopCounter_FFT + 1;
                entryNumber_FFT = entryNumber_FFT + 1;
            end
        end
    end
    
    % Option 3: If last record, get HostUnixTime (can use in cases where no stop time
    % was recorded)
    if recordCounter == length(DeviceSettings)
        TD_SettingsTable.action{entryNumber_TD} = sprintf('Last record');
        TD_SettingsTable.recNum(entryNumber_TD) = NaN;
        TD_SettingsTable.time{entryNumber_TD} = HostUnixTime;
        
        Power_SettingsTable.action{entryNumber_Power} = sprintf('Last record');
        Power_SettingsTable.recNum(entryNumber_Power) = NaN;
        Power_SettingsTable.time{entryNumber_Power} = HostUnixTime;
        
        FFT_SettingsTable.action{entryNumber_FFT} = sprintf('Last record');
        FFT_SettingsTable.recNum(entryNumber_FFT) = NaN;
        FFT_SettingsTable.time{entryNumber_FFT} = HostUnixTime;
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
            timeStart = selectData.time{1};
        else
            warning('Streaming of time domain data does not have start time')
            missingTime = 1;
        end
        
        % Check that second time is a stop time, or if last chunk can
        % have stop time missing and use 'last record' time
        if iChunk == length(recordingChunks) && size(selectData,1) ~= 2
            timeStop = TD_SettingsTable.time{end};
        else
            if contains(selectData.action{2},'Stop')
                timeStop = selectData.time{2};
            else
                warning('Streaming of time domain data does not have stop time')
                missingTime = 1;
            end
        end
        
        % If no missing start or stop time, populate deviceSettingsOut
        if missingTime == 0
            TD_SettingsOut.recNum(iChunk) = recordingChunks(iChunk);
            TD_SettingsOut.duration(iChunk) = timeStop - timeStart;
            TD_SettingsOut.timeStart(iChunk) = timeStart;
            TD_SettingsOut.timeStop(iChunk) = timeStop;
            
            % Loop through all TD channels to get sampling rate and acquistion parameters
            for iChan = 1:4
                if ~strcmp(selectData.tdDataStruc{1}(iChan).sampleRate,'disabled') &&...
                        ~strcmp(selectData.tdDataStruc{1}(iChan).sampleRate,'unexpected')
                    TD_SettingsOut.samplingRate(iChunk) = str2num(selectData.tdDataStruc{1}(iChan).sampleRate(1:end-2));
                    fieldName = sprintf('chan%d',iChan);
                    TD_SettingsOut.(fieldName){iChunk} = selectData.(fieldName){1};
                end
            end
            TD_SettingsOut.TimeDomainDataStruc{iChunk} = selectData.tdDataStruc{1};
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
            timeStart = selectData.time{1};
        else
            warning('Streaming of power data does not have start time')
            missingTime = 1;
        end
        
        % Check that second time is a stop time, or if last chunk can
        % have stop time missing and use 'last record' time
        if iChunk == length(recordingChunks) && size(selectData,1) ~= 2
            timeStop = Power_SettingsTable.time{end};
        else
            if contains(selectData.action{2},'Stop')
                timeStop = selectData.time{2};
            else
                warning('Streaming of power data does not have stop time')
                missingTime = 1;
            end
        end
        
        % If no missing start or stop time, populate deviceSettingsOut
        if missingTime == 0
            Power_SettingsOut.recNum(iChunk) = recordingChunks(iChunk);
            Power_SettingsOut.duration(iChunk) = timeStop - timeStart;
            Power_SettingsOut.timeStart(iChunk) = timeStart;
            Power_SettingsOut.timeStop(iChunk) = timeStop;
            
            Power_SettingsOut.powerBands{iChunk} = selectData.powerBands{1};
            Power_SettingsOut.TDsampleRates{iChunk} = selectData.TDsampleRates{1};
            Power_SettingsOut.fftConfig{iChunk} = selectData.fftConfig(1);
        end
    end
end

%%
% FFT DATA
FFT_SettingsOut = table();

% Indices in table of start/stop actions
indices = ~isnan(FFT_SettingsTable.recNum);
recordingChunks = unique(FFT_SettingsTable.recNum(indices));

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
            timeStart = selectData.time{1};
        else
            warning('Streaming of FFT data does not have start time')
            missingTime = 1;
        end
        
        % Check that second time is a stop time, or if last chunk can
        % have stop time missing and use 'last record' time
        if iChunk == length(recordingChunks) && size(selectData,1) ~= 2
            timeStop = FFT_SettingsTable.time{end};
        else
            if contains(selectData.action{2},'Stop')
                timeStop = selectData.time{2};
            else
                warning('Streaming of FFT data does not have stop time')
                missingTime = 1;
            end
        end
        
        % If no missing start or stop time, populate deviceSettingsOut
        if missingTime == 0
            FFT_SettingsOut.recNum(iChunk) = recordingChunks(iChunk);
            FFT_SettingsOut.duration(iChunk) = timeStop - timeStart;
            FFT_SettingsOut.timeStart(iChunk) = timeStart;
            FFT_SettingsOut.timeStop(iChunk) = timeStop;
            
            FFT_SettingsOut.FFTbandFormationConfig(iChunk) = selectData.FFTbandFormationConfig(1);
            FFT_SettingsOut.FFTconfig(iChunk) = selectData.FFTconfig(1);
            FFT_SettingsOut.FFTinterval(iChunk) = selectData.FFTinterval(1);
            FFT_SettingsOut.FFTsize(iChunk) = selectData.FFTsize(1);
            FFT_SettingsOut.FFTstreamOffsetBins(iChunk) = selectData.FFTstreamOffsetBins(1);
            FFT_SettingsOut.FFTstreamSizeBins(iChunk) = selectData.FFTstreamSizeBins(1);
            FFT_SettingsOut.FFTwindowLoad(iChunk) = selectData.FFTwindowLoad(1);
        end
    end
end


%%
% KS NOTE: BELOW SECTION FROM DEVICESETTINGSFORMONTAGE.M

% %% Adaptive / detection config
% % detection settings first are reported in full (e.g. all fields)
% % after this point, only changes are reported.
% % to make analysis easier, each row in output table will contain the full
% % settings such that I copy over initial settings.
% % this also assumes that you get a full report of the detection settings on
% % first connection.
%
% % the settings being changed in each adaptive state update will be noted
% % in a cell array as well
%
%
%
% %%%
% %%%
% %%%
% % NEW CODE - first load initial settings that then get updates
% %%%
% %%%
% %%%
%
% recordCounter = 1;
% previosSettIdx = 0;
% currentSettIdx  = 1;
% adaptiveSettings = table();
%
% fnms = fieldnames(DeviceSettings{recordCounter});
% currentSettings = DeviceSettings{recordCounter};
% det_fiels = {'blankingDurationUponStateChange',...
%     'detectionEnable','detectionInputs','fractionalFixedPointValue',...
%     'holdoffTime','onsetDuration','terminationDuration','updateRate'};
% if isfield(currentSettings,'DetectionConfig')
%     lds_fn = {'Ld0','Ld1'};
%     for ll = 1:length(lds_fn)
%         ldTable = table();
%         if isfield(currentSettings.DetectionConfig,lds_fn{ll})
%             LD = currentSettings.DetectionConfig.(lds_fn{ll});
%             adaptiveSettings.([lds_fn{ll} '_' 'biasTerm']) = LD.biasTerm';
%             adaptiveSettings.([lds_fn{ll} '_' 'normalizationMultiplyVector']) = [LD.features.normalizationMultiplyVector];
%             adaptiveSettings.([lds_fn{ll} '_' 'normalizationSubtractVector']) = [LD.features.normalizationSubtractVector];
%             adaptiveSettings.([lds_fn{ll} '_' 'weightVector']) = [LD.features.weightVector];
%             for d = 1:length(det_fiels)
%                 adaptiveSettings.([lds_fn{ll} '_' det_fiels{d}])  =  LD.(det_fiels{d});
%             end
%         else % fill in previous settings.
%             warning('missing field on first itiration');
%         end
%     end
%     adaptiveSettings.HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
% end
% if isfield(currentSettings,'AdaptiveConfig')
%     adaptive_fields = {'adaptiveMode','adaptiveStatus','currentState',...
%         'deltaLimitsValid','deltasValid'};
%     adaptiveConfig = currentSettings.AdaptiveConfig;
%     for a = 1:length(adaptive_fields)
%         if isfield(adaptiveConfig,adaptive_fields{a})
%             adaptiveSettings.(adaptive_fields{a}) = adaptiveConfig.(adaptive_fields{a});
%         else
%             warning('missing field on first itiration');
%         end
%     end
%     if isfield(adaptiveConfig,'deltas')
%         adaptiveSettings.fall_rate = [adaptiveConfig.deltas.fall];
%         adaptiveSettings.rise_rate = [adaptiveConfig.deltas.rise];
%     else
%         warning('missing field on first itiration');
%     end
%     adaptiveSettings.HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
% end
% if isfield(currentSettings,'AdaptiveConfig')
%     % loop on states
%     if isfield(adaptiveConfig,'state0')
%         for s = 0:8
%             statefn = sprintf('state%d',s);
%             stateStruct = adaptiveConfig.(statefn);
%             adaptiveSettings.(['state' num2str(s)] ) = s;
%             adaptiveSettings.(['rate_hz_state' num2str(s)] ) = stateStruct.rateTargetInHz;
%             adaptiveSettings.(['isValid_state' num2str(s)] ) = stateStruct.isValid;
%             for iProgram = 0:3
%                 progfn = sprintf('prog%dAmpInMilliamps',iProgram);
%                 curr(iProgram+1) = stateStruct.(progfn);
%             end
%             adaptiveSettings.(['currentMa_state' num2str(s)] )(1,:) = curr;
%         end
%     else
%         % fill in previous settings.
%     end
% end
%
%
% % loop on rest of code and just report changes and when they happened
% % don't copy things over for now
%
% return;
%
%
% f = 2;
% previosSettIdx = 0;
% currentSettIdx  = 1;
% changesMade = struct();
% cntchange = 1;
% while f <= length(DeviceSettings)
%     adaptiveChanges = table();
%     fnms = fieldnames(DeviceSettings{f});
%     curStr = DeviceSettings{f};
%     det_fiels = {'blankingDurationUponStateChange',...
%         'detectionEnable','detectionInputs','fractionalFixedPointValue',...
%         'holdoffTime','onsetDuration','terminationDuration','updateRate'};
%     if isfield(curStr,'DetectionConfig')
%         lds_fn = {'Ld0','Ld1'};
%         for ll = 1:length(lds_fn)
%             ldTable = table();
%             if isfield(curStr.DetectionConfig,lds_fn{ll})
%                 LD = curStr.DetectionConfig.(lds_fn{ll});
%                 adaptiveChanges.([lds_fn{ll} '_' 'biasTerm']) = LD.biasTerm';
%                 adaptiveChanges.([lds_fn{ll} '_' 'normalizationMultiplyVector']) = [LD.features.normalizationMultiplyVector];
%                 adaptiveChanges.([lds_fn{ll} '_' 'normalizationSubtractVector']) = [LD.features.normalizationSubtractVector];
%                 adaptiveChanges.([lds_fn{ll} '_' 'weightVector']) = [LD.features.weightVector];
%                 for d = 1:length(det_fiels)
%                     adaptiveChanges.([lds_fn{ll} '_' det_fiels{d}])  =  LD.(det_fiels{d});
%                 end
%             else % fill in previous settings.
%                 warning('missing field on first itiration');
%             end
%         end
%         adaptiveChanges.HostUnixTime = curStr.RecordInfo.HostUnixTime;
%     end
%     if isfield(curStr,'AdaptiveConfig')
%         adaptive_fields = {'adaptiveMode','adaptiveStatus','currentState',...
%             'deltaLimitsValid','deltasValid'};
%         adaptiveConfig = curStr.AdaptiveConfig;
%         for a = 1:length(adaptive_fields)
%             if isfield(adaptiveConfig,adaptive_fields{a})
%                 adaptiveChanges.(adaptive_fields{a}) = adaptiveConfig.(adaptive_fields{a});
%             else
%                 warning('missing field on first itiration');
%             end
%         end
%         if isfield(adaptiveConfig,'deltas')
%             adaptiveChanges.fall_rate = [adaptiveConfig.deltas.fall];
%             adaptiveChanges.rise_rate = [adaptiveConfig.deltas.rise];
%         else
%             warning('missing field on first itiration');
%         end
%         adaptiveChanges.HostUnixTime = curStr.RecordInfo.HostUnixTime;
%     end
%     if isfield(curStr,'AdaptiveConfig')
%         % loop on states
%         if isfield(adaptiveConfig,'state0')
%             for s = 0:8
%                 statefn = sprintf('state%d',s);
%                 stateStruct = adaptiveConfig.(statefn);
%                 adaptiveChanges.(['state' num2str(s)] ) = s;
%                 adaptiveChanges.(['rate_hz_state' num2str(s)] ) = stateStruct.rateTargetInHz;
%                 adaptiveChanges.(['isValid_state' num2str(s)] ) = stateStruct.isValid;
%                 for p = 0:3
%                     progfn = sprintf('prog%dAmpInMilliamps',p);
%                     curr(p+1) = stateStruct.(progfn);
%                 end
%                 adaptiveChanges.(['currentMa_state' num2str(s)] )(1,:) = curr;
%             end
%         end
%     end
%     if ~isempty(adaptiveChanges)
%         changesMade(cntchange).adaptiveChanges = adaptiveChanges;
%         cntchange = cntchange + 1;
%     end
%     f = f +1;
%%
