function [deviceSettingsOut, stimStatus, stimState] = createDeviceSettingsTable(folderPath)
%%
%
% Input: Folder path to Device* folder containing json files
%
% Output: *
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
UTCoffset = DeviceSettings{1,1}.UtcOffset;

%%
deviceSettingsTable = table(); % Initalize table
recordCounter = 1; % Initalize counter for records in DeviceSetting
entryNumber = 1; % Initialize counter for populating entries to table
inStream = 0; % Initalize as streaming off
streamStartCounter = 1; % Initalize counter for streaming starts
streamStopCounter = 1; % Initalize counter for streaming stops

% All fields are present in first entry, but subsequent entries only have
% fields which were updated. Go through all the entries in device settings,
% checking for updates.

while recordCounter <= length(DeviceSettings)
    currentSettings = DeviceSettings{recordCounter};
    
    createdEntry = 0;
    % Check if SensingConfig was updated
    if isfield(currentSettings,'SensingConfig')
        
        % If timeDomain, power, or FFT is updated in this record, create
        % new row in deviceSettingsTable and populate with metadata
        if isfield(currentSettings.SensingConfig,'timeDomainChannels') ||...
                isfield(currentSettings.SensingConfig,'powerChannels') ||...
                isfield(currentSettings.SensingConfig,'fftConfig')
            HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
            deviceSettingsTable.action{entryNumber} = 'Sense Config';
            deviceSettingsTable.recNum(entryNumber) = NaN;
            deviceSettingsTable.time{entryNumber} = HostUnixTime;
            createdEntry = 1;
        end
        
        % Time domain data
        if isfield(currentSettings.SensingConfig,'timeDomainChannels')
            % Settings will remain in TDsettings until updated
            TDsettings = convertTDcodes(currentSettings.SensingConfig.timeDomainChannels);
            for iChan = 1:4
                fieldName = sprintf('chan%d',iChan);
                deviceSettingsTable.(fieldName){entryNumber} = TDsettings(iChan).chanFullStr;
            end
            deviceSettingsTable.tdDataStruc{entryNumber} = TDsettings;
        end
        
        % Power domain data
        if isfield(currentSettings.SensingConfig,'powerChannels')
            % This populates information about the powerBands (coded
            % values, not in Hz). The bipolar channels associated with the
            % bands are defined above (from timeDomainChannels). Sense chan1: Bands
            % 1-2, sense chan2: Bands 3-4, Sense chan3: Bands 5-6, Sense
            % chan4: Bands 7-8
            
            % Settings will remain in powerChannels until updated
            powerChannels = currentSettings.SensingConfig.powerChannels;
            deviceSettingsTable.powerBands{entryNumber} = powerChannels;
        end
        
        % FFT data
        if isfield(currentSettings.SensingConfig,'fftConfig')
            % Settings will remain in fftConfig until updated
            fftConfig = currentSettings.SensingConfig.fftConfig;
            deviceSettingsTable.FFTbandFormationConfig(entryNumber) = fftConfig.bandFormationConfig;
            deviceSettingsTable.FFTconfig(entryNumber) = fftConfig.config;
            deviceSettingsTable.FFTinterval(entryNumber) = fftConfig.interval;
            deviceSettingsTable.FFTsize(entryNumber) = fftConfig.size;
            deviceSettingsTable.FFTstreamOffsetBins(entryNumber) = fftConfig.streamOffsetBins;
            deviceSettingsTable.FFTstreamSizeBins(entryNumber) = fftConfig.streamSizeBins;
            deviceSettingsTable.FFTwindowLoad(entryNumber) = fftConfig.windowLoad;
        end
        
        % If any of the above were updated, iterate entryNumber
        if createdEntry == 1
            entryNumber = entryNumber + 1;
        end
    end
    
    % Check if streaming has been turned on
    % (TDsettings, powerChannels, and fftConfig should have all been populated
    % with something because first record should have all variables)
    if isfield(currentSettings,'StreamState')
        if currentSettings.StreamState.TimeDomainStreamEnabled
            if ~inStream % If not already inStream, then streaming is starting
                % Create new row in deviceSettingsTable and populate with metadata
                HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
                deviceSettingsTable.action{entryNumber} = sprintf('Start Stream %d',streamStartCounter);
                deviceSettingsTable.recNum(entryNumber) = streamStartCounter;
                deviceSettingsTable.time{entryNumber} = HostUnixTime;
                
                % Fill in most recent time domain data settings
                for iChan = 1:4
                    fieldName = sprintf('chan%d',iChan);
                    deviceSettingsTable.(fieldName){entryNumber} = TDsettings(iChan).chanFullStr;
                end
                deviceSettingsTable.tdDataStruc{entryNumber} = TDsettings;
                
                % Fill in most recent power domain settings
                deviceSettingsTable.powerBands{entryNumber} = powerChannels;
                
                % Fill in most recent FFT settings
                deviceSettingsTable.FFTbandFormationConfig(entryNumber) = fftConfig.bandFormationConfig;
                deviceSettingsTable.FFTconfig(entryNumber) = fftConfig.config;
                deviceSettingsTable.FFTinterval(entryNumber) = fftConfig.interval;
                deviceSettingsTable.FFTsize(entryNumber) = fftConfig.size;
                deviceSettingsTable.FFTstreamOffsetBins(entryNumber) = fftConfig.streamOffsetBins;
                deviceSettingsTable.FFTstreamSizeBins(entryNumber) = fftConfig.streamSizeBins;
                deviceSettingsTable.FFTwindowLoad(entryNumber) = fftConfig.windowLoad;
                
                streamStartCounter = streamStartCounter + 1;
                entryNumber = entryNumber + 1;
                inStream = 1;
            end
        end
    end
    
    % Check if streaming has been stopped - this can be done by turning
    % streaming off or by turning sensing off. Use the same counter across
    % these two methods
    
    % Option 1: Check if streaming has been stopped
    if isfield(currentSettings,'StreamState')
        if inStream % Only continue if streaming is on
            if ~currentSettings.StreamState.TimeDomainStreamEnabled % If stream is not enabled
                % Create new row in deviceSettingsTable and populate with metadata
                HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
                deviceSettingsTable.action{entryNumber} = sprintf('Stop Stream %d',streamStopCounter);
                deviceSettingsTable.recNum(entryNumber) = streamStopCounter;
                deviceSettingsTable.time{entryNumber} = HostUnixTime;
                
                % Fill in most recent time domain data settings
                for iChan = 1:4
                    fieldName = sprintf('chan%d',iChan);
                    deviceSettingsTable.(fieldName){entryNumber} = TDsettings(iChan).chanFullStr;
                end
                deviceSettingsTable.tdDataStruc{entryNumber} = TDsettings;
                
                % Fill in most recent power domain settings
                deviceSettingsTable.powerBands{entryNumber} = powerChannels;
                
                % Fill in most recent FFT settings
                deviceSettingsTable.FFTbandFormationConfig(entryNumber) = fftConfig.bandFormationConfig;
                deviceSettingsTable.FFTconfig(entryNumber) = fftConfig.config;
                deviceSettingsTable.FFTinterval(entryNumber) = fftConfig.interval;
                deviceSettingsTable.FFTsize(entryNumber) = fftConfig.size;
                deviceSettingsTable.FFTstreamOffsetBins(entryNumber) = fftConfig.streamOffsetBins;
                deviceSettingsTable.FFTstreamSizeBins(entryNumber) = fftConfig.streamSizeBins;
                deviceSettingsTable.FFTwindowLoad(entryNumber) = fftConfig.windowLoad;
                
                inStream = 0;
                streamStopCounter = streamStopCounter + 1;
                entryNumber = entryNumber + 1;
            end
        end
    end
    % Option 2: Check if sense has been turned off
    if isfield(currentSettings,'SenseState')
        if inStream % Only continue if streaming is on
            if isfield(currentSettings.SenseState,'state')
                senseState = dec2bin(currentSettings.SenseState.state,4);
                % Check starting/stopping of time domain streaming. See
                % documentation enum Medtronic.NeuroStim.Olympus.DataTypes.Sensing.SenseStates : byte
                % for more details about binary number coding
                if strcmp(senseState(4),'0') % Time domain streaming is off
                    % Create new row in deviceSettingsTable and populate with metadata
                    HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
                    deviceSettingsTable.action{entryNumber} = sprintf('Stop Sense %d',streamStopCounter);
                    deviceSettingsTable.recNum(entryNumber) = streamStopCounter;
                    deviceSettingsTable.time{entryNumber} = HostUnixTime;
                    
                    % Fill in most recent time domain data settings
                    for iChan = 1:4
                        fieldName = sprintf('chan%d',iChan);
                        deviceSettingsTable.(fieldName){entryNumber} = TDsettings(iChan).chanFullStr;
                    end
                    deviceSettingsTable.tdDataStruc{entryNumber} = TDsettings;
                    % Fill in most recent power domain settings
                    deviceSettingsTable.powerBands{entryNumber} = powerChannels;
                    
                    % Fill in most recent FFT settings
                    deviceSettingsTable.FFTbandFormationConfig(entryNumber) = fftConfig.bandFormationConfig;
                    deviceSettingsTable.FFTconfig(entryNumber) = fftConfig.config;
                    deviceSettingsTable.FFTinterval(entryNumber) = fftConfig.interval;
                    deviceSettingsTable.FFTsize(entryNumber) = fftConfig.size;
                    deviceSettingsTable.FFTstreamOffsetBins(entryNumber) = fftConfig.streamOffsetBins;
                    deviceSettingsTable.FFTstreamSizeBins(entryNumber) = fftConfig.streamSizeBins;
                    deviceSettingsTable.FFTwindowLoad(entryNumber) = fftConfig.windowLoad;
                    
                    inStream = 0;
                    streamStopCounter = streamStopCounter + 1;
                    entryNumber = entryNumber + 1;
                end
            end
        end
    end
    % If last record, get HostUnixTime (useful in cases where no stop time
    % was recorded)
    if recordCounter == length(DeviceSettings)
        deviceSettingsTable.action{entryNumber} = sprintf('Last record');
        deviceSettingsTable.recNum(entryNumber) = NaN;
        deviceSettingsTable.time{entryNumber} = HostUnixTime;
    end
    recordCounter = recordCounter + 1;
end


% KS: Check below (compare to FFTdata -- need to do anyting to accomodate
% power or FFT??)

%%
% Loop through deviceSettingsTable to determine start and stop time for each
% recording segment in the file. deviceSettingOutput pulls relevant
% information from deviceSettingsTable, only taking information about data
% which was streamed
deviceSettingsOut = table();

% Indices in table of start/stop actions
indices = ~isnan(deviceSettingsTable.recNum);
recordingChunks = unique(deviceSettingsTable.recNum(indices));

% Extract timing info and metadata about each recording chunk. Recording chunks are defined as
% having a start and stop time in the deviceSettingsTable; the last
% recording chunk in the file can use the last record time as the stop
% time.
for iChunk = 1:length(recordingChunks)
    currentIndices = deviceSettingsTable.recNum == recordingChunks(iChunk);
    selectData = deviceSettingsTable(currentIndices,:);
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
            timeStop = deviceSettingsTable.time{end};
        else
            if contains(selectData.action{2},'Stop')
                timeStop = selectData.time{2};
            else
                warning('Streaming of time domain data does not have stop time')
                missingTime = 1;
            end
        end
        
        % If no missing timestamps, populate deviceSettingsOut
        if missingTime == 0
            deviceSettingsOut.recNum(iChunk) = recordingChunks(iChunk);
            deviceSettingsOut.duration(iChunk) = timeStop - timeStart;
            deviceSettingsOut.timeStart(iChunk) = timeStart;
            deviceSettingsOut.timeStop(iChunk) = timeStop;
            
            % Loop through all channels to get sampling rate and acquistion parameters
            for iChan = 1:4
                if ~strcmp(selectData.tdDataStruc{1}(iChan).sampleRate,'disabled') &&...
                        ~strcmp(selectData.tdDataStruc{1}(iChan).sampleRate,'unexpected')
                    deviceSettingsOut.samplingRate(iChunk) = str2num(selectData.tdDataStruc{1}(iChan).sampleRate(1:end-2));
                    fieldName = sprintf('chan%d',iChan);
                    deviceSettingsOut.(fieldName){iChunk} = selectData.(fieldName){1};
                end
            end
            deviceSettingsOut.TimeDomainDataStruc{iChunk} = selectData.tdDataStruc{1};
        end
    end
end


%% load stimulation config
% this code (re stim sweep part) assumes no change in stimulation from initial states
% this code will fail for stim sweeps or if any changes were made to
% stimilation
% need to fix this to include stim changes and when the occured to color
% data properly according to stim changes and when the took place for in
% clinic testing

therapyStatus = DeviceSettings{1}.GeneralData.therapyStatusData;
groups = [0 1 2 3]; % max of 4 groups
groupNames = {'A','B','C','D'};
stimState = table();
counter = 1;

for iGroup = 1:length(groups)
    fn = sprintf('TherapyConfigGroup%d',groups(iGroup));
    for iProgram = 1:4 % max of 4 programs per group
        if DeviceSettings{1}.TherapyConfigGroup0.programs(iProgram).isEnabled == 0
            stimState.group(counter) = groupNames{iGroup};
            if (iGroup-1) == therapyStatus.activeGroup
                stimState.activeGroup(counter) = 1;
                if therapyStatus.therapyStatus
                    stimState.stimulation_on(counter) = 1;
                else
                    stimState.stimulation_on(counter) = 0;
                end
            else
                stimState.activeGroup(counter) = 0;
                stimState.stimulation_on(counter) = 0;
            end
            
            stimState.program(counter) = iProgram;
            stimState.pulseWidth_mcrSec(counter) = DeviceSettings{1}.(fn).programs(iProgram).pulseWidthInMicroseconds;
            stimState.amplitude_mA(counter) = DeviceSettings{1}.(fn).programs(iProgram).amplitudeInMilliamps;
            stimState.rate_Hz(counter) = DeviceSettings{1}.(fn).rateInHz;
            electrodes = DeviceSettings{1}.(fn).programs(iProgram).electrodes.electrodes;
            elecString = '';
            for iElectrode = 1:length(electrodes)
                if electrodes(iElectrode).isOff == 0 % Electrode is active
                    % Determine if electrode is used
                    if iElectrode == 17 % This refers to the can
                        elecUsed = 'c';
                    else
                        elecUsed = num2str(iElectrode-1); % Electrodes are zero indexed
                    end
                    
                    % Determine if electrode is anode or cathode
                    if electrodes(iElectrode).electrodeType == 1
                        elecSign = '-'; % Anode
                    else
                        elecSign = '+'; % Cathode
                    end
                    elecSnippet = [elecSign elecUsed ' '];
                    elecString = [elecString elecSnippet];
                end
            end
            
            stimState.electrodes{counter} = elecString;
            counter = counter + 1;
        end
    end
end
if ~isempty(stimState)
    stimStatus = stimState(logical(stimState.activeGroup),:);
else
    stimStatus = [];
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
