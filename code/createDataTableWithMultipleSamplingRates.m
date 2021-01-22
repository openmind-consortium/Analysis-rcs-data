function [outputData] = createDataTableWithMultipleSamplingRates(all_Fs, dataStreamSettings, outtable_data)
%%
% Function to handle multiple sampling rates in a data stream
%
% Input: all sampling rates (one per entry in settings), settings, and raw
% data
%
% Output: data table with derivedTimes
%
%%
% Need to loop through each setting - if
% sampling rate has changed from previous setting, find
% closest times between *Settings (using timeStart) and
% outtable_* (using PacketGenTime) to
% assign corresponding samplerate (in other words, only
% find time if sampling rate has changed, not all entries
% in *Settings have different sample rates)

% Determine number of segments, defined as chunks without
% change in sampling rate
numSettings = length(all_Fs);
segmentIndices = [];
for iSetting = 1:numSettings
    if iSetting == 1 || ~isequal(all_Fs(iSetting), all_Fs(iSetting - 1))
        segmentIndices = [segmentIndices; iSetting];
    end
end

numSegments = length(segmentIndices);
for iSegment = 1:numSegments
    timeStart = dataStreamSettings.timeStart(segmentIndices(iSegment));
    timeStop = dataStreamSettings.timeStop(segmentIndices(iSegment));
    
    [tempStartIndex, ~] = knnsearch(outtable_data.PacketGenTime,timeStart);
    [tempStopIndex, ~] = knnsearch(outtable_data.PacketGenTime,timeStop);
    
    % In some cases, entries in dataStreamSettings may not have data associated
    % with those settings (e.g. sensing turned on, streaming turned off). Thus,
    % need to make sure times ~align. Acceptable if start time is before data
    % as long as stop time is during data
    if tempStartIndex ~= tempStopIndex
        % Indicates that from timeStart to timeStop of this segment, data were
        % acquired
        startIndices(iSegment) = tempStartIndex;
    else
        % Indicates that from timeStart to timeStop of this segment, there
        % were no data streamed
        startIndices(iSegment) = NaN;
    end
end

% Determine stopIndices (one sample before the next start
% index, or the last sample)
stopIndices = [startIndices(2:end) - 1 size(outtable_data,1)];
stopIndices(isnan(startIndices)) = NaN;

% Create separate matrics for each sampling
% rate, creating a new matrix each time sampling rate changes,
% and run assignTime on these segments; will then need to stitch back together
outputData = [];
if sum(isnan(startIndices)) == length(startIndices)
    % None of the startTimes intersect with the data -- take the values from
    % the last setting entry
    temp_outtable = outtable_data;
    temp_outtable.samplerate(:) = all_Fs(end);
    temp_outtable.packetsizes(:) = 1;
    outputData = assignTime(temp_outtable);
else
    for iSegment = 1:numSegments
        if ~isnan(startIndices(iSegment))
            temp_outtable = outtable_data(startIndices(iSegment):stopIndices(iSegment),:);
            temp_outtable.samplerate(:) = all_Fs(iSegment);
            temp_outtable.packetsizes(:) = 1;
            outputData = [outputData; assignTime(temp_outtable)];
        end
    end
end
end