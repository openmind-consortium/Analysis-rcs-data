function [outtable] = createAdaptiveTable(Adaptive)
%% 
% Function to unravel Adaptive time series data, creating a table with all
% variables
%
% Input: a structure of time domain data that is read from AdaptiveLog.json
% (To transform *.json file into structure use deserializeJSON.m)
%%

numRecords = size(Adaptive,2);
outtable = table();

% Collect all data from the records
for iRecord = 1:numRecords
    clear newEntry
    
    newEntry.PacketGenTime = Adaptive(iRecord).AdaptiveUpdate.PacketGenTime;
    newEntry.PacketRxUnixTime = Adaptive(iRecord).AdaptiveUpdate.PacketRxUnixTime;
    newEntry.dataSize = Adaptive(iRecord).AdaptiveUpdate.Header.dataSize;
    newEntry.dataType = Adaptive(iRecord).AdaptiveUpdate.Header.dataType;
    newEntry.info = Adaptive(iRecord).AdaptiveUpdate.Header.info;
    newEntry.dataTypeSequence = Adaptive(iRecord).AdaptiveUpdate.Header.dataTypeSequence;
    newEntry.systemTick = Adaptive(iRecord).AdaptiveUpdate.Header.systemTick;
    newEntry.timestamp = Adaptive(iRecord).AdaptiveUpdate.Header.timestamp.seconds;
    
    newEntry.CurrentAdaptiveState = Adaptive(iRecord).AdaptiveUpdate.CurrentAdaptiveState;
    newEntry.CurrentProgramAmplitudesInMilliamps = Adaptive(iRecord).AdaptiveUpdate.CurrentProgramAmplitudesInMilliamps;
    newEntry.IsInHoldOffOnStartup = Adaptive(iRecord).AdaptiveUpdate.IsInHoldOffOnStartup;
    newEntry.Ld0DetectionStatus = Adaptive(iRecord).AdaptiveUpdate.Ld0DetectionStatus;
    newEntry.Ld1DetectionStatus = Adaptive(iRecord).AdaptiveUpdate.Ld1DetectionStatus;
    newEntry.PreviousAdaptiveState = Adaptive(iRecord).AdaptiveUpdate.PreviousAdaptiveState;
    newEntry.SensingStatus = Adaptive(iRecord).AdaptiveUpdate.SensingStatus;
    newEntry.StateEntryCount = Adaptive(iRecord).AdaptiveUpdate.StateEntryCount;
    newEntry.StateTime = Adaptive(iRecord).AdaptiveUpdate.StateTime;
    newEntry.StimFlags = Adaptive(iRecord).AdaptiveUpdate.StimFlags;
    newEntry.StimRateInHz = Adaptive(iRecord).AdaptiveUpdate.StimRateInHz;
    
    newEntry.Ld0_featureInputs = Adaptive(iRecord).AdaptiveUpdate.Ld0Status.featureInputs;
    newEntry.Ld0_fixedDecimalPoint = Adaptive(iRecord).AdaptiveUpdate.Ld0Status.fixedDecimalPoint;
    newEntry.Ld0_highThreshold = Adaptive(iRecord).AdaptiveUpdate.Ld0Status.highThreshold;
    newEntry.Ld0_lowThreshold = Adaptive(iRecord).AdaptiveUpdate.Ld0Status.lowThreshold;
    newEntry.Ld0_output = Adaptive(iRecord).AdaptiveUpdate.Ld0Status.output;
    
    newEntry.Ld1_featureInputs = Adaptive(iRecord).AdaptiveUpdate.Ld1Status.featureInputs;
    newEntry.Ld1_fixedDecimalPoint = Adaptive(iRecord).AdaptiveUpdate.Ld1Status.fixedDecimalPoint;
    newEntry.Ld1_highThreshold = Adaptive(iRecord).AdaptiveUpdate.Ld1Status.highThreshold;
    newEntry.Ld1_lowThreshold = Adaptive(iRecord).AdaptiveUpdate.Ld1Status.lowThreshold;
    newEntry.Ld1_output = Adaptive(iRecord).AdaptiveUpdate.Ld1Status.output;
    
    outtable = addRowToTable(newEntry,outtable);
end
end
