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
indicesOfTimestamps = find(~isnan(inputDataTable.timestamp));
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
% packets. Automatically remove the next packet [diffIndices + 2], as this is easier than
% trying to confirm there is enough time to assign to samples without
% causing overlap.
% Remove at most 6 adjacent packets (to prevent large un-needed
% packet rejection driven by positive outliers)
numPackets = size(dataTable_original,1);
indices_backInTime = [];
for iIndex = 1:length(diffIndices)
    counter = 3; % Automatically removing two packets, start looking at the third
    
    % Check if next packet indices exists in the recording
    if (diffIndices(iIndex) + 1) <= numPackets
        indices_backInTime = [indices_backInTime (diffIndices(iIndex) + 1)];
    end
    if (diffIndices(iIndex) + 2) <= numPackets
        indices_backInTime = [indices_backInTime (diffIndices(iIndex) + 2)];
    end
    
    % If there are more packets after this, check if they need to also be
    % removed
    while (counter <= 6) &&  (diffIndices(iIndex) + counter) <= numPackets &&...
            dataTable_original.PacketGenTime(diffIndices(iIndex) + counter)...
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

clear dataTable_original
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

diff_systemTick = nan(numPackets,1);
for iPacket = 2:numPackets
    diff_systemTick(iPacket,1) = mod((dataTable.systemTick(iPacket) + (2^16)...
        - dataTable.systemTick(iPacket - 1)), 2^16);
end

% Expected elapsed time for each packet, based on sample rate and number of
% samples per packet; in units of systemTick (1e-4 seconds)
expectedElapsed = dataTable.packetsizes .* (1./dataTable.samplerate) * 1e4;

% If diff_systemTick and expectedElapsed differ by more than 20% of expectedElapsed,
% flag as gap
indices_systemTickFlagged = find (abs(expectedElapsed(2:end) - diff_systemTick(2:end)) > 0.2*expectedElapsed(2:end));

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
            % Edge case: Only one flagged index; automatically create
            % second chunk to end of data
            if length(allFlaggedIndices) == 1
                chunkIndices{counter} = allFlaggedIndices(currentStartIndex) + 1:numPackets;
            end
        elseif iChunk == length(allFlaggedIndices)
            chunkIndices{counter} = allFlaggedIndices(currentStartIndex) + 1:allFlaggedIndices(currentStartIndex + 1);
            chunkIndices{counter + 1} = allFlaggedIndices(currentStartIndex + 1) + 1:numPackets;
        else
            chunkIndices{counter} = allFlaggedIndices(currentStartIndex) + 1:allFlaggedIndices(currentStartIndex + 1);
            currentStartIndex = currentStartIndex + 1;
            counter = counter + 1;
        end
    end
else
    % No identified missing packets, all packets in one chunk
    chunkIndices{1} = 1:numPackets;
end

%%
% Two types of chunks -- those which come after gaps < 6 seconds (as determined by
% timestamp) and those which come after gaps > 6 seconds (potential for complete
% roll-over of systemTick). For chunks which follow a gap < 6 seconds,
% use systemTick to continue calculation of DerivedTime after the gap (rather
% than creating a new correctedAlignTime for that chunk); still honor 1/Fs
% spacing of DerivedTime. Note -- if new chunk is created because of change
% in sampling rate, calculate a new correctedAlignTime for that chunk

% Only need to do this calculation if more than 1 chunk
numChunks = length(chunkIndices);
chunksWithTimingFromPrevious = [];
if numChunks > 1
    % Get timestamps of first and last packet in chunks to calculate time gaps
    for iChunk = 1:numChunks
        indices_FirstPacket(iChunk) = chunkIndices{iChunk}(1);
        indices_LastPacket(iChunk) = chunkIndices{iChunk}(end);
    end
    timestamps_FirstPacket = dataTable.timestamp(indices_FirstPacket);
    timestamps_LastPacket = dataTable.timestamp(indices_LastPacket);
    timestamp_gaps = timestamps_FirstPacket(2:end) - timestamps_LastPacket(1:end-1); % in seconds
    
    % If the gap in timestamp between packets is < 6 seconds, flag this packet;
    % calculate elapsed time in systemTick
    
    % iTimegap + 1 is the index of the chunk which does not need a new
    % correctedAlignTime calculated (aka chunksWithTimingFromPrevious)
    elapsed_systemTick = NaN(1,length(timestamp_gaps));
    
    for iTimegap = 1:length(timestamp_gaps)
        % Check if timegap is < 6 seconds and if this chunk was not created
        % because of change in sampling rate
        if timestamp_gaps(iTimegap) < 6 && ~ismember(indices_LastPacket(iTimegap),indices_changeFs)
            chunksWithTimingFromPrevious = [chunksWithTimingFromPrevious iTimegap + 1];
            systemTick_FirstPacket = dataTable.systemTick(indices_FirstPacket(iTimegap + 1));
            systemTick_Preceeding = dataTable.systemTick(indices_LastPacket(iTimegap));
            
            % Need to use calculateDeltaSystemTick in order to handle situations when
            % systemTick rollover occurred
            elapsed_systemTick(iTimegap)= calculateDeltaSystemTick(systemTick_Preceeding,systemTick_FirstPacket);
        end
    end
end

%%
% Loop through each chunk to determine offset to apply (as determined by
% average difference between packetGenTime and expectedElapsed) --
% calculated for all chunks here, will subsequently only apply error for
% chunks which are preceeded by gaps >= 6 seconds
disp('Determining start time of each chunk')

% PacketGenTime in ms; convert difference to 1e-4 seconds, units of
% systemTick and expectedElapsed
diff_PacketGenTime = [1; diff(dataTable.PacketGenTime) * 1e1]; % multiply by 1e1 to convert to 1e-4 seconds

singlePacketChunks = [];
medianError = NaN(1,numChunks);
for iChunk = 1:numChunks
    currentTimestampIndices = chunkIndices{iChunk};
    
    % Chunks must have at least 2 packets in order to have a valid
    % diff_systemTick -- thus if chunk only one packet, it must be
    % identified. These chunks can remain if the timeGap before is < 6
    % seconds, but must be excluded if the timeGap before is >= 6 seconds
    
    if length(currentTimestampIndices) == 1
        singlePacketChunks = [singlePacketChunks iChunk];
    end
    % Always exclude the first packet of the chunk, because don't have an
    % accurate diff_systemTick value for this first packet
    currentTimestampIndices = currentTimestampIndices(2:end);
    
    % Differences between adjacent PacketGenTimes (in units of 1e-4
    % seconds)
    error = expectedElapsed(currentTimestampIndices) - diff_PacketGenTime(currentTimestampIndices);
    medianError(iChunk) = median(error);
end
%%
% Create corrected timing for each chunk
counter = 1;
counter_recalculatedFromPacketGenTime = 0;
chunksToRemove = [];
realignTime = 0; % If a chunk is flagged for removal, the next chunk will require
% calculation of correctedAlignTime from PacketGenTime; this would happen
% (for example) if chunk number x had one packet, with a timeGap of >=6 seconds
% immediately prior; chunk x + 1 should have correctedAlignTime calculated
% from PacketGenTime
for iChunk = 1:numChunks
    if ismember(iChunk,chunksWithTimingFromPrevious) && realignTime == 0 % First chunk will never fall into this category
        % Determine amount of cumulative time since the previous
        % packet's correctedAlignTime -- add this cumulative time to
        % the previous packet's correctedAlignTime in order to
        % calculate the current packet's correctedAlignTime
        
        % elapsed_systemTick accounts for time from last packet in the
        % preceeding chunk to the first packet in the current chunk
        
        % otherTime_previousChunk accounts for time from fist packet to
        % last packet in the previous chunk; do this as a function of
        % number of samples and Fs (these two chunks will have the same
        % Fs, as enforced above)
        Fs_previousChunk = dataTable.samplerate(chunkIndices{iChunk - 1}(1));
        
        allPacketSizes_previousChunk = dataTable.packetsizes(chunkIndices{iChunk - 1});
        
        % We just need to account for time from samples from packets two to end of the
        % previous chunk (in ms)
        otherTime_previousChunk = sum(allPacketSizes_previousChunk(2:end)) * (1/Fs_previousChunk) * 1000;
        
        correctedAlignTime(counter) = correctedAlignTime(counter - 1) +...
            (elapsed_systemTick(iChunk - 1)*1e-1) + otherTime_previousChunk;
        counter = counter + 1;
    elseif ~ismember(iChunk,singlePacketChunks)
        alignTime = dataTable.PacketGenTime(chunkIndices{iChunk}(1));
        % alignTime in ms; medianError in units of systemTick
        correctedAlignTime(counter) = alignTime + medianError(iChunk)*1e-1;
        % Development Note: The medianError calculated and applied here
        % only includes samples within an original chunk; thus, if
        % there are two chunks with < 6 second gap, only the error
        % calculated from the first chunk will be used to create the
        % correctedAlignTime
        
        % Adding error above because we assume the expectedElapsed time (function of
        % sampling rate and number of samples in packet) represents the
        % correct amount of elapsed time. We calculated the median difference
        % between the expected elapsed time according to the packet size
        % and the diff PacketGenTime. The number of time units will be
        % negative if the diff PacketGenTime is consistently larger than
        % the expected elapsed time, so adding removes the bias.
        % The alternatiave would be if we thought PacketGenTime was a more
        % accurate representation of time, then we would want to subtract the value in medianError.
        counter = counter + 1;
        realignTime = 0;
        counter_recalculatedFromPacketGenTime = counter_recalculatedFromPacketGenTime + 1;
    else
        chunksToRemove = [chunksToRemove iChunk];
        realignTime = 1;
    end
end

% Print metrics to command window
disp(['Number of chunks: ' num2str(numChunks)]);
disp(['Numer of chunks removed: ' num2str(length(chunksToRemove))])
disp(['Number of chunks with time calculated from PacketGenTime: ' num2str(counter_recalculatedFromPacketGenTime)])

%%
% At this point, possible that all chunks have been removed - check for
% this and only proceed with processing if chunks remain

if exist('correctedAlignTime','var')
    % Indices in chunkIndices correspond to packets in dataTable.
    % CorrectedAlignTime corresponds to first packet for each chunk in
    % chunkIndices. Remove chunks identified above
    chunkIndices(chunksToRemove) = [];
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
    clear inputDataTable
    
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
    indicesOfTimestamps_cleaned = find(~isnan(outputDataTable.timestamp));
    
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
    DerivedTime = nan(size(outputDataTable,1),1);
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
        
        DerivedTime(chunkSampleStart(iChunk):chunkSampleEnd(iChunk)) = ...
            correctedAlignTime_shifted(iChunk) - elapsedTime_before : 1000/currentFs : correctedAlignTime_shifted(iChunk) + elapsedTime_after;
    end
    
    % Check to ensure that the same DerivedTime was not assigned to multiple
    % samples; if yes, flag the second instance for removal; note: in matlab, nans
    % are not equal
    if ~isequal(length(DerivedTime), length(unique(DerivedTime)))
        [~,uniqueIndices] = unique(DerivedTime);
        duplicateIndices = setdiff([1:length(DerivedTime)],uniqueIndices);
    else
        duplicateIndices = [];
    end
    
    % All samples which do not have a derivedTime should be removed from final
    % data table, along with those with duplicate derivedTime values
    disp('Cleaning up output table')
    outputDataTable.DerivedTime = DerivedTime;
    rowsToRemove = [find(isnan(DerivedTime)); duplicateIndices'];
    outputDataTable(rowsToRemove,:) = [];
    
    % Make timing/metadata variables consistent across data streams
    outputDataTable = movevars(outputDataTable,{'DerivedTime','timestamp','systemTick','PacketGenTime','PacketRxUnixTime','dataTypeSequence','samplerate','packetsizes'},'Before',1);
else
    outputDataTable = [];
    
end
