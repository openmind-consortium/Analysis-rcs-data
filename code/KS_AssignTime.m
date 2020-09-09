function timeDomainData = KS_AssignTime(outtable_TD)
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
% Input: Data table output from unravelData (data originating from RawDataTD.json)
%
% Output: Same as input table, with additional column of 'DerivedTimes' for
% each sample
%%

% Pull out info for each packet
indicesOfTimestamps = find(outtable_TD.timestamp ~= 0);
dataTable_original = outtable_TD(indicesOfTimestamps,:);

%%
% Identify packets for rejection

% TO DO: Check year of timestamp?

% Negative PacketGenTime
packetIndices_NegGenTime = find(dataTable_original.PacketGenTime <= 0);

% Consecutive packets with identical dataTypeSequence and systemTick;
% identify the second packet for removal; identify the first
% instance of these duplicates below
duplicate_firstIndex = intersect(find(diff(dataTable_original.dataTypeSequence) == 0),...;
    find(diff(dataTable_original.systemTick) == 0));

% Collect all packets to remove
packetsToRemove = [packetIndices_NegGenTime; duplicate_firstIndex + 1];

% Remove packets identified above for rejection
packetsToKeep = setdiff(1:size(dataTable_original,1),packetsToRemove);
dataTable = dataTable_original(packetsToKeep,:);

%%
% Identify gaps -- start with most obvious gaps, and then become more
% refined

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
allFlaggedIndices = unique([indices_timestampFlagged; indices_dataTypeSequenceFlagged;...
    indices_systemTickFlagged]) ;

%%
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

% PacketGenTime in ms; convert difference to 1e-4 seconds, units of
% systemTick and expectedElapsed
diff_PacketGenTime = [1; diff(dataTable.PacketGenTime) * 1e1];

numChunks = length(chunkIndices);
chunksToExclude = [];
for iChunk = 1:numChunks
    currentIndices = chunkIndices{iChunk};
    
    % Chunks must have at least 2 packets in order to have a valid
    % diff_systemTick -- thus if chunk only one packet, it must be excluded
    if length(currentIndices) == 1
        chunksToExclude = [chunksToExclude iChunk];
    end
    % Always exclude the first packet of the chunk, because don't have an
    % accurate diff_systemTick value for this first packet
    currentIndices = currentIndices(2:end);
    
    % Differences between adjacent PacketGenTimes (in units of 1e-4
    % seconds)
    error = expectedElapsed(currentIndices) - diff_PacketGenTime(currentIndices);
    meanError(iChunk) = median(error);
end
%%
% Create corrected timing for each chunk
for iChunk = 1:numChunks
    if ~ismember(iChunk,chunksToExclude)
        alignTime(iChunk) = dataTable.PacketGenTime(chunkIndices{iChunk}(1));
    end
end

% alignTime in ms; meanError in units of systemTick
correctedAlignTime = alignTime + meanError*1e-1;

% TO DO: add or subtract meanError above??

%%
% Indices in chunkIndices correspond to packets in dataTable.
% CorrectedAlignTime corresponds to first packet for each chunk in
% chunkIndices. Remove chunks identified above
chunkIndices(chunksToExclude) = [];
correctedAlignTime(find(isnan(correctedAlignTime))) = [];

% Full form data table
timeDomainData = outtable_TD;

% Remove packets and samples identified above as lacking proper metadata
samplesToRemove = [];
toRemove_start = indicesOfTimestamps(packetsToRemove - 1) + 1;
toRemove_stop = indicesOfTimestamps(packetsToRemove);
for iPacket = 1:length(packetsToRemove)
    samplesToRemove = [samplesToRemove toRemove_start(iPacket):toRemove_stop(iPacket)];
end
timeDomainData(samplesToRemove,:) = [];

% Indices referenced in chunkIndices can now be mapped back to timeDomainData
% using indicesOfTimestamps_cleaned
indicesOfTimestamps_cleaned = find(timeDomainData.timestamp ~= 0);

% Initalize column for derivedTimes
timeDomainData.DerivedTimes = zeros(size(timeDomainData,1),1);

% Map the chunk start/stop times back to samples
for iChunk = 1:length(chunkIndices)
    currentPackets = chunkIndices{iChunk};
    chunkPacketStart(iChunk) = indicesOfTimestamps_cleaned(currentPackets(1));
    chunkSampleStart(iChunk) = indicesOfTimestamps_cleaned(currentPackets(1) - 1) + 1;
    chunkSampleEnd(iChunk) = indicesOfTimestamps_cleaned(currentPackets(end)); 
end

% Use correctedAlignTime and sampling rate to assign each included sample a
% derivedTime
for iChunk = 1:length(chunkIndices)
    % Assign derivedTimes to samples before first packet time -- all same
    % sampling rate
    
    deltaTime = (chunkPacketStart(iChunk) - chunkSampleStart(iChunk))*1/timeDomainData.samplerate(chunkPacketStart(iChunk));
    
    timeDomainData.DerivedTime(chunkPacketStart(iChunk):-1:chunkSampleStart(iChunk)) = ...
    correctedAlignTime(iChunk):-1/timeDomainData.samplerate(chunkPacketStart(iChunk)):correctedAlignTime(iChunk) - deltaTime;
    
   % Assign derivedTimes to samples after first packetTime -- check for
   % differing sampling rates
   
   % KS HERE
    
end



% All samples which do not have a derivedTime should be removed from final
% timeDomainData table




end














%%
% TO DO: Current minimum chunk size is 2 packets -- make this larger?

% TO DO: Exclude chunksToExclude
