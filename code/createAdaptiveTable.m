function [outtable] = createAdaptiveTable(jsonobj_Adaptive)
%% 
% Function to unravel Adaptive time series data, creating a table with all
% variables
%
% Input: a structure of time domain data that is read from AdaptiveLog.json
% (To transform *.json file into structure use deserializeJSON.m)
%%

numRecords = length(jsonobj_Adaptive); % If fix was required when opening JSON file, dimensions may be flipped

AdaptiveUpdate = [jsonobj_Adaptive.AdaptiveUpdate];
fieldNames = {'PacketGenTime','PacketRxUnixTime','CurrentProgramAmplitudesInMilliamps',...
    'IsInHoldOffOnStartup','StateEntryCount',...
    'StateTime','StimRateInHz'};
for iName = 1:length(fieldNames)
    data.(fieldNames{iName}) = [AdaptiveUpdate.(fieldNames{iName})]';
end

% Convert CurrentAdaptiveState
temp_currentAdaptiveState = [AdaptiveUpdate.CurrentAdaptiveState]';
CurrentAdaptiveState = cell(1,length(temp_currentAdaptiveState));
CurrentAdaptiveState(temp_currentAdaptiveState == 0) = {'State 0'};
CurrentAdaptiveState(temp_currentAdaptiveState == 1) = {'State 1'};
CurrentAdaptiveState(temp_currentAdaptiveState == 2) = {'State 2'};
CurrentAdaptiveState(temp_currentAdaptiveState == 3) = {'State 3'};
CurrentAdaptiveState(temp_currentAdaptiveState == 4) = {'State 4'};
CurrentAdaptiveState(temp_currentAdaptiveState == 5) = {'State 5'};
CurrentAdaptiveState(temp_currentAdaptiveState == 6) = {'State 6'};
CurrentAdaptiveState(temp_currentAdaptiveState == 7) = {'State 7'};
CurrentAdaptiveState(temp_currentAdaptiveState == 8) = {'State 8'};
CurrentAdaptiveState(temp_currentAdaptiveState == 15) = {'No State'};
data.('CurrentAdaptiveState') = CurrentAdaptiveState';

% Convert detector status
temp_Ld0DetectionStatus = [AdaptiveUpdate.Ld0DetectionStatus]';
data.('Ld0DetectionStatus') = dec2bin(temp_Ld0DetectionStatus,8);

% Convert detector status
temp_Ld1DetectionStatus = [AdaptiveUpdate.Ld1DetectionStatus]';
data.('Ld1DetectionStatus') = dec2bin(temp_Ld1DetectionStatus,8);

% Convert PreviousAdaptiveState
temp_previousAdaptiveState = [AdaptiveUpdate.PreviousAdaptiveState]';
PreviousAdaptiveState = cell(1,length(temp_previousAdaptiveState));
PreviousAdaptiveState(temp_previousAdaptiveState == 0) = {'State 0'};
PreviousAdaptiveState(temp_previousAdaptiveState == 1) = {'State 1'};
PreviousAdaptiveState(temp_previousAdaptiveState == 2) = {'State 2'};
PreviousAdaptiveState(temp_previousAdaptiveState == 3) = {'State 3'};
PreviousAdaptiveState(temp_previousAdaptiveState == 4) = {'State 4'};
PreviousAdaptiveState(temp_previousAdaptiveState == 5) = {'State 5'};
PreviousAdaptiveState(temp_previousAdaptiveState == 6) = {'State 6'};
PreviousAdaptiveState(temp_previousAdaptiveState == 7) = {'State 7'};
PreviousAdaptiveState(temp_previousAdaptiveState == 8) = {'State 8'};
PreviousAdaptiveState(temp_previousAdaptiveState == 15) = {'No State'};
data.('PreviousAdaptiveState') = PreviousAdaptiveState';

% Convert SensingStatus
temp_SensingStatus = [AdaptiveUpdate.SensingStatus]';
data.('SensingStatus') = cellstr(dec2bin(temp_SensingStatus,8));

% Convert StimFlags
temp_StimFlags = [AdaptiveUpdate.StimFlags]';
data.('StimFlags') = cellstr(dec2bin(temp_StimFlags,8));

% Extract info from Header
Header = [AdaptiveUpdate.Header];
fieldNames = {'dataTypeSequence','systemTick'}; % Under AdaptiveUpdate.Header
for iName = 1:length(fieldNames)
    data.(fieldNames{iName}) = [Header.(fieldNames{iName})]';
end

% Extract more info from within Header
Timestamp = [Header.timestamp];
data.timestamp = struct2array(Timestamp)';

% Extract info from Ld0Status
Ld0Status = [AdaptiveUpdate.Ld0Status];
fieldNames = {'featureInputs','fixedDecimalPoint','highThreshold',...
    'lowThreshold','output'};
for iName = 1:length(fieldNames)
    data.(['Ld0_' fieldNames{iName}]) = [Ld0Status.(fieldNames{iName})]';
end

Ld1Status = [AdaptiveUpdate.Ld1Status];
fieldNames = {'featureInputs','fixedDecimalPoint','highThreshold',...
    'lowThreshold','output'};
for iName = 1:length(fieldNames)
    data.(['Ld1_' fieldNames{iName}]) = [Ld1Status.(fieldNames{iName})]';
end

outtable = struct2table(data);
end
