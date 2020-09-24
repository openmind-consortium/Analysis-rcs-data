function outputDataTable = assignTime(inputDataTable)
%%
% Function for creating timestamps for each sample of valid RC+S data. Given
% known limitations of all recorded timestamps, need to use multiple variables
% to derive time.
%
% General approach: Remove packets with faulty meta-data.
% Identify gaps in data (by checking deltas in timestamp, systemTick,
% and dataTypeSequence). Consecutive packets of data without gaps
% are referred to as 'chunks'. For each chunk, determine best estimate of
% the first packet time, and then calculate time for each  sample based on
% sampling rate -- assume no missing samples. Best estimate of start time
% for each chunk is determined by taking median (across all packets in that
% chunk) of the offset between delta PacketGenTime and expected time to
% have elapsed (as a function of sampling rate and number of samples
% per packet).
%
% Input: Data table output from createTimeDomainTable or createAccelTable
% (data originating from RawDataTD.json or RawDataAccel.json)
%
% Output: Same as input table, with additional column of 'DerivedTimes' for
% each sample
%%

% Pull out info for each packet
indicesOfTimestamps = find(inputDataTable.timestamp ~= 0);
dataTable_original = inputDataTable(indicesOfTimestamps,:);

%%
% Identify packets for rejection

disp('Identifying and removing bad packets')
% Remove any packets with timestamp that are more than 24 hours from median timestamp
medianTimestamp = median(dataTable_original.timestamp);
numSecs = 24*60*60;
badDatePackets = union(find(dataTable_original.timestamp > medianTimestamp + numSecs),find(dataTable_original.timestamp < medianTimestamp - numSecs));

% Negative PacketGenTime
packetIndices_NegGenTime = find(dataTable_original.PacketGenTime <= 0);

% Consecutive packets with identical dataTypeSequence and systemTick;
% identify the second packet for removal; identify the first
% instance of these duplicates below
duplicate_firstIndex = intersect(find(diff(dataTable_original.dataTypeSequence) == 0),...
    find(diff(dataTable_original.systemTick) == 0));

% Packets with outlier PacketGenTime, as determined by differences between
% timestamp and PacketGenTime. This does not address packets which have
% both 'bad' timestamp and PacketGenTime. Packets with only bad timestamp
% may also be flagged

% Determine first packet with non-negative PacketGenTime -- use this packet
% for normalizing timestamps and PacketGenTime
firstGoodIndex = find(dataTable_original.PacketGenTime > 0,1);

normedTimestamps = dataTable_original.timestamp - dataTable_original(firstGoodIndex,:).timestamp;
normedGenTime_inSecs = (dataTable_original.PacketGenTime - dataTable_original(firstGoodIndex,:).PacketGenTime)/1000;

timeDifferences = normedTimestamps - normedGenTime_inSecs;
indices_outlierPacketGenTimes = find(abs(timeDifferences) > 1);

% Identify packetGenTimes that go backwards in time; should overlap with negative PacketGenTime
packetGenTime_diffs = diff(dataTable_original.PacketGenTime);
diffIndices = find(packetGenTime_diffs < 0 );

% Need to remove [diffIndices + 1], but may also need to remove subsequent
% packets. Remove at most 5 adjacent packets (to prevent large un-needed
% packet rejection driven by positive outliers)
indices_backInTime = [];
for iIndex = 1:length(diffIndices)
    counter = 1;
    while (counter < 6) && dataTable_original.PacketGenTime(diffIndices(iIndex) + counter)...
            < dataTable_original.PacketGenTime(diffIndices(iIndex))
        
        indices_backInTime = [indices_backInTime (diffIndices(iIndex) + counter)];
        counter = counter + 1;
    end
end

% Collect all packets to remove
packetsToRemove = unique([badDatePackets; packetIndices_NegGenTime;...
    duplicate_firstIndex + 1; indices_outlierPacketGenTimes; indices_backInTime']);

% Remove packets identified above for rejection
packetsToKeep = setdiff(1:size(dataTable_original,1),packetsToRemove);
dataTable = dataTable_original(packetsToKeep,:);

%%
% Identify gaps -- start with most obvious gaps, and then become more
% refined

% Change in sampling rate should start a new chunk; identify indices of
% last packet of a chunk
if ~isequal(length(unique(dataTable.samplerate)),1)
    indices_changeFs = find(diff(dataTable.samplerate) ~=0);
else
    indices_changeFs = [];
end
maxFs = max(unique(dataTable.samplerate));

% Timestamp difference from previous packet not 0 or 1 -- indicates gap or
% other abnormality; these indices indicate the end of a continuous chunk
indices_timestampFlagged = intersect(find(diff(dataTable.timestamp) ~= 0),find(diff(dataTable.timestamp) ~= 1));

% Instances where dataTypeSequence doesn't iterate by 1; these indices
% indicate the end of a continuous chunk
indices_dataTypeSequenceFlagged = intersect(find(diff(dataTable.dataTypeSequence) ~= 1),find(diff(dataTable.dataTypeSequence) ~= -255));

% Lastly, check systemTick to ensure there are no packets missing.
% Determine delta time between systemTicks in adjacent packets.
% Exclude first packet from those to test, because need to compare times from
% 'previous' to 'current' packets; diff_systemTick written to index of
% second packet associated with that calculation
numPackets = size(dataTable,1);
for iPacket = 2:numPackets
    diff_systemTick(iPacket,1) = mod((dataTable.systemTick(iPacket) + (2^16)...
        - dataTable.systemTick(iPacket - 1)), 2^16);
end

% Expected elapsed time for each packet, based on sample rate and number of
% samples per packet; in units of systemTick (1e-4 seconds)
expectedElapsed = dataTable.packetsizes .* (1./dataTable.samplerate) * 1e4;

% If diff_systemTick and expectedElapsed differ by more than 10% of expectedElapsed,
% flag as gap
indices_systemTickFlagged = find (abs(expectedElapsed(2:end) - diff_systemTick(2:end)) > 0.1*expectedElapsed(2:end));

% All packets flagged as end of continuous chunks
allFlaggedIndices = unique([indices_changeFs; indices_timestampFlagged;...
    indices_dataTypeSequenceFlagged; indices_systemTickFlagged],'sorted') ;

%%
disp('Chunking data')
% Determine indices of packets which correspond to each data chunk
if ~isempty(allFlaggedIndices)
    counter = 1;
    chunkIndices = cell(1,length(allFlaggedIndices) + 1);
    for iChunk = 1:length(allFlaggedIndices)
        if iChunk == 1
            chunkIndices{counter} = (1:allFlaggedIndices(1));
            currentStartIndex = 1;
            counter = counter + 1;
        else
            chunkIndices{counter} = allFlaggedIndices(currentStartIndex) + 1:allFlaggedIndices(currentStartIndex + 1);
            currentStartIndex = currentStartIndex + 1;
            counter = counter + 1;
        end
        % Last chunk, finishing with last packet
        chunkIndices{counter} = allFlaggedIndices(currentStartIndex) + 1:numPackets;
    end
else
    % No identified missing packets, all packets in one chunk
    chunkIndices{1} = 1:numPackets;
end

%%
% Loop through each chunk to determine offset to apply (as determined by
% average difference between packetGenTime and expectedElapsed)
disp('Determining start time of each chunk')

% PacketGenTime in ms; convert difference to 1e-4 seconds, units of
% systemTick and expectedElapsed
diff_PacketGenTime = [1; diff(dataTable.PacketGenTime) * 1e1];

numChunks = length(chunkIndices);
chunksToExclude = [];
meanError = NaN(1,numChunks);
for iChunk = 1:numChunks
    currentTimestampIndices = chunkIndices{iChunk};
    
    % Chunks must have at least 2 packets in order to have a valid
    % diff_systemTick -- thus if chunk only one packet, it must be excluded
    if length(currentTimestampIndices) == 1
        chunksToExclude = [chunksToExclude iChunk];
    end
    % Always exclude the first packet of the chunk, because don't have an
    % accurate diff_systemTick value for this first packet
    currentTimestampIndices = currentTimestampIndices(2:end);
    
    % Differences between adjacent PacketGenTimes (in units of 1e-4
    % seconds)
    error = expectedElapsed(currentTimestampIndices) - diff_PacketGenTime(currentTimestampIndices);
    meanError(iChunk) = median(error);
end
%%
% Create corrected timing for each chunk
counter = 1;
for iChunk = 1:numChunks
    if ~ismember(iChunk,chunksToExclude)
        alignTime = dataTable.PacketGenTime(chunkIndices{iChunk}(1));
        % alignTime in ms; meanError in units of systemTick
        correctedAlignTime(counter) = alignTime + meanError(iChunk)*1e-1;
        % TO DO: add or subtract meanError above??
        counter = counter + 1;
    end
end

%%
% Indices in chunkIndices correspond to packets in dataTable.
% CorrectedAlignTime corresponds to first packet for each chunk in
% chunkIndices. Remove chunks identified above
chunkIndices(chunksToExclude) = [];
correctedAlignTime(find(isnan(correctedAlignTime))) = [];

% correctedAlignTime is shifted slightly to keep times exactly aligned to
% sampling rate; use maxFs for alignment points. In other words, take first
% correctedAlignTime, and place all other correctedAlignTimes at multiples of
% (1/Fs)
deltaTime = 1/maxFs * 1000; % in milliseconds

disp('Shifting chunks to align with sampling rate')
multiples = floor(((correctedAlignTime - correctedAlignTime(1))/deltaTime) + 0.5);
correctedAlignTime_shifted = correctedAlignTime(1) + (multiples * deltaTime);

% Full form data table
outputDataTable = inputDataTable;

% Remove packets and samples identified above as lacking proper metadata
samplesToRemove = [];
% If first packet is included, collect those samples separately
if ismember(1,packetsToRemove)
    samplesToRemove = 1:indicesOfTimestamps(1);
    packetsToRemove = setdiff(packetsToRemove,1);
end
% Loop through all other packetsToRemove
toRemove_start = indicesOfTimestamps(packetsToRemove - 1) + 1;
toRemove_stop = indicesOfTimestamps(packetsToRemove);
for iPacket = 1:length(packetsToRemove)
    samplesToRemove = [samplesToRemove toRemove_start(iPacket):toRemove_stop(iPacket)];
end
outputDataTable(samplesToRemove,:) = [];

% Indices referenced in chunkIndices can now be mapped back to timeDomainData
% using indicesOfTimestamps_cleaned
indicesOfTimestamps_cleaned = find(outputDataTable.timestamp ~= 0);

% Map the chunk start/stop times back to samples
for iChunk = 1:length(chunkIndices)
    currentPackets = chunkIndices{iChunk};
    chunkPacketStart(iChunk) = indicesOfTimestamps_cleaned(currentPackets(1));
    if currentPackets(1) == 1 % First packet, thus take first sample
        chunkSampleStart(iChunk) = 1;
    else
        chunkSampleStart(iChunk) = indicesOfTimestamps_cleaned(currentPackets(1) - 1) + 1;
    end
    chunkSampleEnd(iChunk) = indicesOfTimestamps_cleaned(currentPackets(end));
end

disp('Creating derivedTime for each sample')
% Use correctedAlignTime and sampling rate to assign each included sample a
% derivedTime

% Initalize DerivedTime
outputDataTable.DerivedTime = nan(size(outputDataTable,1),1);
for iChunk = 1:length(chunkIndices)
    % Display status
    if iChunk > 0 && mod(iChunk, 1000) == 0
        disp(['Currently on chunk ' num2str(iChunk) ' of ' num2str(length(chunkIndices))])
    end
    % Assign derivedTimes to all samples (from before first packet time to end) -- all same
    % sampling rate
    currentFs = outputDataTable.samplerate(chunkPacketStart(iChunk));
    elapsedTime_before = (chunkPacketStart(iChunk) - chunkSampleStart(iChunk)) * (1000/currentFs);
    elapsedTime_after = (chunkSampleEnd(iChunk) - chunkPacketStart(iChunk)) * (1000/currentFs);
    
    outputDataTable.DerivedTime(chunkSampleStart(iChunk):chunkSampleEnd(iChunk)) = ...
        correctedAlignTime_shifted(iChunk) - elapsedTime_before : 1000/currentFs : correctedAlignTime_shifted(iChunk) + elapsedTime_after;
end

% All samples which do not have a derivedTime should be removed from final
% data table
disp('Cleaning up output table')
rowsToRemove = find(outputDataTable.DerivedTime == 0);
outputDataTable(rowsToRemove,:) = [];

end
