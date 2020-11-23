function [newDerivedTime,toShift_newDerivedTimes] = harmonizeTimeAcrossDataStreams(unifiedDerivedTimes, derivedTime_toShift, Fs_baseTime)
%%
% Shift derivedTime_toShift to align with
% unifiedDerivedTimes. Typically, unifiedDerivedTimes will be from timeDomain,
% and derivedTime_toShift will be accelerometer, FFT, or power. If needed,
% add more derivedTimes to beginning and/or end of unifiedDerivedTimes
% in order to accomodate times of derivedTime_toShift
%
% Output: newDerivedTime (to replace 'unifiedDerivedTimes', as this may
% have additional times added); toShift_newDerivedTimes (values from
% newDerivedTimes which correspond to samples in timeseries selected to shift)
%
%%
newDerivedTime = unifiedDerivedTimes;

% Determine if derivedTime_toShift extends more than one derivedTime step before or after
% derivedTime_baseTime; if yes, add values to derivedTime_baseTime as
% needed; all these times in ms
if derivedTime_toShift(1) < (unifiedDerivedTimes(1) - (1000/Fs_baseTime))
    % Need to add derivedTime values at the beginning; determine how many
    elapsedTime_before = unifiedDerivedTimes(1) - derivedTime_toShift(1); % in ms
    numTimePointsToAddBefore = ceil(elapsedTime_before/(1000/Fs_baseTime));
    
    timeToAppend = unifiedDerivedTimes(1) - numTimePointsToAddBefore*(1000/Fs_baseTime):...
        (1000/Fs_baseTime):unifiedDerivedTimes(1) - (1000/Fs_baseTime);
    
    newDerivedTime = [timeToAppend'; newDerivedTime];
    clear timeToAppend
end

if derivedTime_toShift(end) > (unifiedDerivedTimes(end) + (1000/Fs_baseTime))
    % Need to add derivedTime values at the end; determine how many
    elapsedTime_after = derivedTime_toShift(end) - unifiedDerivedTimes(end); % in ms
    numTimePointsToAddAfter = ceil(elapsedTime_after/(1000/Fs_baseTime));
    
    timeToAppend = unifiedDerivedTimes(end) + (1000/Fs_baseTime):...
        (1000/Fs_baseTime):unifiedDerivedTimes(end) + numTimePointsToAddAfter*(1000/Fs_baseTime);
    
    newDerivedTime = [newDerivedTime; timeToAppend'];
    clear timeToAppend
end

% Determine closest index of baseTime that can be used for
% derivedTime_toShift
[selectIndices, distance] = dsearchn(newDerivedTime,derivedTime_toShift);

% Check that there are no duplicate selectIndices
if ~isequal(length(unique(selectIndices)), length(selectIndices))
   warning('Same time assigned to more than one sample during time harmonization') 
end

% Confirm that no sample in derivedTime_toShift is being moved more than
% 1/Fs_baseTime. A shift larger than this should never occur, as additional
% timepoints were created; if there are such indices identified, not doing
% anything with them currently
threshold = 1000/Fs_baseTime; %in ms
indicesToRemove = find(distance > threshold);

if ~isempty(indicesToRemove)
    warning('Values in derivedTime_toShift are not being mapped to unifiedDerivedTimes within range')
end

toShift_newDerivedTimes = newDerivedTime(selectIndices);




