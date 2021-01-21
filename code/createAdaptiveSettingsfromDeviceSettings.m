function [DetectorSettings,AdaptiveStimSettings,AdaptiveRuns_StimSettings] = createAdaptiveSettingsfromDeviceSettings(folderPath)
%%
% Extract information from DeviceSettings.json relevant to adaptive
% detector and stimulation settings
%
% Input: Folder path to Device* folder containing json files
% Output:
%%
% Load in DeviceSettings.json file
DeviceSettings = jsondecode(fixMalformedJson(fileread([folderPath filesep 'DeviceSettings.json']),'DeviceSettings'));

%%
% Fix format - Sometimes device settings is a struct or cell array
if isstruct(DeviceSettings)
    DeviceSettings = {DeviceSettings};
end

%%
DetectorSettings = table;
AdaptiveStimSettings = table;
%%
addEntry = 0;
adaptiveFields = {'adaptiveMode','adaptiveStatus','currentState',...
    'deltaLimitsValid','deltasValid'};
tempStateTable = table();
allStates = {'state0','state1','state2','state3','state4','state5',...
    'state6','state7','state8'};
rate = NaN;

for iRecord = 1:length(DeviceSettings)
    currentSettings = DeviceSettings{iRecord};
    HostUnixTime = currentSettings.RecordInfo.HostUnixTime;
    
    % If applicable, update DetectorSettings
    if isfield(currentSettings,'DetectionConfig') && ((isfield(currentSettings.DetectionConfig,'Ld0') || isfield(currentSettings.DetectionConfig,'Ld1')))
        updatedParameters = {};
        % Create variable with Ld0 and Ld1 settings
        if isfield(currentSettings.DetectionConfig,'Ld0')
            Ld0 = currentSettings.DetectionConfig.Ld0;
        end
        if isfield(currentSettings.DetectionConfig,'Ld1')
            Ld1 = currentSettings.DetectionConfig.Ld1;
        end
        % If first record, need to initalize and flag to add entry to table
        if iRecord == 1
            updatedLd0 = Ld0;
            updatedLd1 = Ld1;
            addEntry = 1;
            updatedParameters = [updatedParameters; 'Ld0'; 'Ld1'];
        end
        % If Ld0 has changed, update and flag to add entry to table
        if ~isequal(updatedLd0,Ld0)
            updatedLd0 = Ld0;
            addEntry = 1;
            updatedParameters = [updatedParameters;'Ld0'];
        end
        % If Ld1 has changed, update and flag to add entry to table
        if ~isequal(updatedLd1,Ld1)
            updatedLd1 = Ld1;
            addEntry = 1;
            updatedParameters = [updatedParameters;'Ld1'];
        end
    end
    
    % If flagged, add entry to table
    if addEntry == 1
        newEntry.HostUnixTime = HostUnixTime;
        newEntry.Ld0 = updatedLd0;
        newEntry.Ld1 = updatedLd1;
        newEntry.DetectorStatus = updatedLd0.detectionEnable + updatedLd1.detectionEnable;
        newEntry.updatedParameters = updatedParameters;
        [DetectorSettings] = addRowToTable(newEntry,DetectorSettings);
        addEntry = 0;
        clear newEntry
    end
    
    % If applicable, udpate AdaptiveSettings
    if isfield(currentSettings,'AdaptiveConfig')
        updatedParameters = {};
        % Create variable with adaptive metadata
        for iField = 1:length(adaptiveFields)
            if isfield(currentSettings.AdaptiveConfig,adaptiveFields{iField})
                adaptiveMetaData.(adaptiveFields{iField}) = currentSettings.AdaptiveConfig.(adaptiveFields{iField});
            end
        end
        % Create variable with delta settings
        if isfield(currentSettings.AdaptiveConfig,'deltas')
            deltas = {currentSettings.AdaptiveConfig.deltas};
        end
        % If first record, need to initalize and flag to add entry to table
        if iRecord == 1
            updatedAdaptive = adaptiveMetaData;
            updatedDeltas = deltas;
            
            for iDelta = 1:4
                % Convert to mA/sec
                updatedDeltas{1}(iDelta).fall = (updatedDeltas{1}(iDelta).fall / 655360)*10;
                updatedDeltas{1}(iDelta).rise = (updatedDeltas{1}(iDelta).rise / 655360)*10;
            end
            
            addEntry = 1;
            updatedParameters = [updatedParameters; 'adaptiveMetadata'; 'deltas'];
        end
        % If adaptive meta data have changed, update and flag to add entry to table
        if ~isequal(updatedAdaptive, adaptiveMetaData)
            updatedAdaptive = adaptiveMetaData;
            addEntry = 1;
            updatedParameters = [updatedParameters; 'adaptiveMetadata'];
        end
        % If deltas have changed, update and flag to add entry to table
        if ~isequal(updatedDeltas, deltas)
            updatedDeltas = deltas;
            for iDelta = 1:4
                % Convert to mA/sec
                updatedDeltas{1}(iDelta).fall = (updatedDeltas{1}(iDelta).fall / 655360)*10;
                updatedDeltas{1}(iDelta).rise = (updatedDeltas{1}(iDelta).rise / 655360)*10;
            end
            addEntry = 1;
            updatedParameters = [updatedParameters; 'deltas'];
        end
        
        % Check for state information
        temp = [];
        for iState = 1:length(allStates)
            if isfield(currentSettings.AdaptiveConfig,allStates{iState})
                % Check if the state is valid
                temp.([allStates{iState} '_isValid']) = currentSettings.AdaptiveConfig.(allStates{iState}).isValid;
                % If the state is valid, get program amplitudes; otherwise fill with NaNs
                if currentSettings.AdaptiveConfig.(allStates{iState}).isValid
                    for iProgram = 0:3
                        % 25.5 indicates hold -- record as -1
                        if isequal(currentSettings.AdaptiveConfig.(allStates{iState}).(['prog' num2str(iProgram) 'AmpInMilliamps']),25.5)
                            currentAmps(iProgram + 1) = -1;
                        else
                            currentAmps(iProgram + 1) = currentSettings.AdaptiveConfig.(allStates{iState}).(['prog' num2str(iProgram) 'AmpInMilliamps']);
                        end
                    end
                    temp.([allStates{iState} '_AmpInMilliamps']) = currentAmps;
                    rate = currentSettings.AdaptiveConfig.(allStates{iState}).rateTargetInHz;
                else
                    % Use -2 to temporarily indicate that state is invalid,
                    % and thus do not need to record amp
                    temp.([allStates{iState} '_AmpInMilliamps']) = [-2, -2, -2, -2];
                end
            end
        end
        
        % If first record, all variables should be in temp
        if iRecord == 1
            for iField = 1:length(fieldnames(temp))
                allFieldnames = fieldnames(temp);
                % Convert ampInMilliamp values that are -2 to NaN
                if isequal(temp.(allFieldnames{iField}),[-2 -2 -2 -2])
                    temp.(allFieldnames{iField}) = [NaN, NaN, NaN, NaN];
                end
            end
            updatedStates = temp;
            updatedRate = rate;
            addEntry = 1;
            updatedParameters = [updatedParameters; 'states'; 'rate'];
            % Beyond first record, loop through fields in temp and compare to
            % updatedStates to determine if change has occurred
        elseif ~isempty(temp)
            for iField = 1:length(fieldnames(temp))
                allFieldnames = fieldnames(temp);
                if ~isequal(updatedStates.(allFieldnames{iField}), temp.(allFieldnames{iField}))
                    % Convert ampInMilliamp values that are -2 to NaN; did
                    % not do this previously, because NaN ~= NaN
                    if isequal(temp.(allFieldnames{iField}),[-2 -2 -2 -2])
                        temp.(allFieldnames{iField}) = [NaN, NaN, NaN, NaN];
                    end
                    
                    updatedStates.(allFieldnames{iField}) = temp.(allFieldnames{iField});
                    updatedParameters = [updatedParameters; allFieldnames{iField}];
                    addEntry = 1;
                end
            end
        end
        % Other than first record, see if rate has changed
        if ~isequal(updatedRate,rate)
            updatedRate = rate;
            addEntry = 1;
            updatedParameters = [updatedParameters; 'rate'];
        end
        
        
        % If flagged, add entry to table
        if addEntry == 1
            newEntry.HostUnixTime = HostUnixTime;
            newEntry.adaptiveMetaData = updatedAdaptive;
            newEntry.deltas = updatedDeltas;
            newEntry.states = updatedStates;
            newEntry.stimRate = updatedRate;
            newEntry.adaptiveStatus = updatedAdaptive.adaptiveMode;
            newEntry.updatedParameters = updatedParameters;
            [AdaptiveStimSettings] = addRowToTable(newEntry,AdaptiveStimSettings);
            addEntry = 0;
            clear newEntry
        end
    end
end

% Create a 'cleaned' version of the AdaptiveStimSettings table, only
% reporting values when adaptive status was 2, or switch from 2->0

indices_AdaptiveOn = find(AdaptiveStimSettings.adaptiveStatus == 2);
allIndices = sort([indices_AdaptiveOn; indices_AdaptiveOn + 1]);

AdaptiveRuns_StimSettings = table;
if ~isempty(indices_AdaptiveOn)
    % Check that we haven't exceeded the number of entries in the table
    if allIndices(end) > size(AdaptiveStimSettings,1)
        allIndices(end) = [];
    end
    AdaptiveRuns_StimSettings = AdaptiveStimSettings(allIndices,:);
    AdaptiveRuns_StimSettings = removevars(AdaptiveRuns_StimSettings,'updatedParameters');
end

end