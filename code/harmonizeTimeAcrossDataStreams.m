function [baseTimeIndices,indicesToRemove] = harmonizeTimeAcrossDataStreams(derivedTime_baseTime, derivedTime_toShift, Fs)
%%
% Shift derivedTime of derivedTime_toShift to align with
% derivedTime_baseTime. Typically, derivedTime_baseTime will be timeDomain,
% and derivedTime_toShift will be accelerometer, FFT, and power. Fs is
% sampling rate of data stream to shift.

%%
% Determine closest index of baseTime that can be used for
% derivedTime_toShift
[baseTimeIndices, distance] = dsearchn(derivedTime_baseTime,derivedTime_toShift);

if length(unique(Fs)) > 1
    warning('Changing sampling rate in dataStream with derivedTimes to be shifted -- not accounted for in current implementation')
end

currentFs = mode(Fs);
% Set max distance between values as threshold
expectedDelta = (1/currentFs)*1000; % in milliseconds
threshold = expectedDelta * 0.1; % 10% of expectedDelta 
indicesToRemove = find(distance > threshold);

end