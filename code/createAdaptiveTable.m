function [outtable] = createAdaptiveTable(Adaptive)
%% 
% Function to unravel Adaptive time series data, creating a table with all
% variables
%
% Input: a structure of time domain data that is read from AdaptiveLog.json
% (To transform *.json file into structure use deserializeJSON.m)
%%

numRecords = length(Adaptive); % If fix was required when opening JSON file, dimensions may be flipped

AdaptiveUpdate = [Adaptive.AdaptiveUpdate];
fieldNames = {'PacketGenTime','PacketRxUnixTime','CurrentAdaptiveState',...
    'CurrentProgramAmplitudesInMilliamps','IsInHoldOffOnStartup','Ld0DetectionStatus',...
    'Ld1DetectionStatus','PreviousAdaptiveState','SensingStatus','StateEntryCount',...
    'StateTime','StimFlags','StimRateInHz'};
for iName = 1:length(fieldNames)
    data.(fieldNames{iName}) = [AdaptiveUpdate.(fieldNames{iName})]';
end

Header = [AdaptiveUpdate.Header];
fieldNames = {'dataSize','dataType','info','dataTypeSequence','systemTick'}; % Under AdaptiveUpdate.Header
for iName = 1:length(fieldNames)
    data.(fieldNames{iName}) = [Header.(fieldNames{iName})]';
end

Timestamp = [Header.timestamp];
data.timestamp = struct2array(Timestamp)';

Ld0Status = [AdaptiveUpdate.Ld0Status];
fieldNames = {'featureInputs','fixedDecimalPoint','highThreshold',...
    'lowThreshold','output'};
for iName = 1:length(fieldNames)
    data.(['LD0_' fieldNames{iName}]) = [Ld0Status.(fieldNames{iName})]';
end

Ld1Status = [AdaptiveUpdate.Ld1Status];
fieldNames = {'featureInputs','fixedDecimalPoint','highThreshold',...
    'lowThreshold','output'};
for iName = 1:length(fieldNames)
    data.(['LD1_' fieldNames{iName}]) = [Ld1Status.(fieldNames{iName})]';
end

outtable = struct2table(data);
end
