function [powerBands] = getPowerBands(powerBands_toConvert,currentTDsampleRate,currentFFTconfig)
%%
% Calculate lower and upper bounds, in Hz, for each power domain timeseries
%
% Input:
% powerBands_toConvert - Struct with power band info (still in code format)
% currentTDsampleRate - TD sampling rate for this chunk of data, in Hz
%
% Output: powerBands

%%
% Initalize powerBand output
powerBands = struct();

% Decode fftSize
switch currentFFTconfig.size
    case 0
        fftSize = 64;
    case 1
        fftSize = 256;
    case 3
        fftSize = 1024;
end

% Unwrap powerBands_toConvert
%   Ch1: band0
%   Ch1: band1
%   Ch2: band0
%   Ch2: band1
%   ...

unwrapped_powerBandsToConvert = [];
counter = 1;
for iChan = 1:4 % Up to 4 bipolar electrode pairs
    for iBand = 0:1 % Up to  2 bands on each bipolar electrode pair
        fieldStart = sprintf('band%dStart',iBand);
        fieldStop = sprintf('band%dStop',iBand);
        unwrapped_powerBandsToConvert(counter,1) = powerBands_toConvert(iChan).(fieldStart);
        unwrapped_powerBandsToConvert(counter,2) = powerBands_toConvert(iChan).(fieldStop);
        counter = counter+1;
    end
end

%%
% Determine frequency cutoffs for each FFT bin
numBins = fftSize/2;
binWidth = (currentTDsampleRate/2)/numBins;

iCounter = 0;
for iCounter = 0:numBins-1
    fftBins(iCounter+1) = iCounter*binWidth;
end

lower(1) = 0;
for iCounter = 2:length(fftBins)
    valInHz = fftBins(iCounter)-fftBins(2)/2;
    lower(iCounter) = valInHz;
end

for iCounter = 1:length(fftBins)
    valInHz = fftBins(iCounter)+fftBins(2)/2;
    upper(iCounter) = valInHz;
end

%%
unwrapped_powerBandsToConvert = unwrapped_powerBandsToConvert + 1; % since C# is 0 indexed and Matlab is 1 indexed.

% Convert powerBands to Hz, based on upper and lower bounds of bins
% calculated above
powerBandsInHz = {};
for iBand = 1:size(unwrapped_powerBandsToConvert,1)
    lowerBounds(iBand) = lower(unwrapped_powerBandsToConvert(iBand,1));
    upperBounds(iBand) = upper(unwrapped_powerBandsToConvert(iBand,2));
    powerBandsInHz{iBand,1} = sprintf('%.2fHz-%.2fHz',...
        lowerBounds(iBand),upperBounds(iBand));
end

powerBands.powerBandsInHz = powerBandsInHz;
powerBands.lowerBound = lowerBounds';
powerBands.upperBound = upperBounds';
powerBands.fftSize = fftSize;
powerBands.fftBins = fftBins;
powerBands.binWidth = binWidth;
powerBands.TDsampleRate = currentTDsampleRate;

end

