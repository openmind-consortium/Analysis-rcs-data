function [powerBands] = getPowerBands(powerBands_toConvert,fftConfig,currentTDsampleRate)
%%
% Calculate lower and upper bounds, in Hz, for each power domain timeseries
%
% Input:
% powerBands_toConvert - Struct with power band info (still in code format)
% currentFFTconfig - FFT info
% currentTDsampleRate - TD sampling rate for this chunk of data, in Hz
% 
% Output: powerBands

%%
% Initalize powerBand output
powerBands = struct();

% Get FFT parameters
fftParameters = getFFTparameters(fftConfig,currentTDsampleRate);

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
unwrapped_powerBandsToConvert = unwrapped_powerBandsToConvert + 1; % since C# is 0 indexed and Matlab is 1 indexed.

% Convert powerBands to Hz, based on upper and lower bounds of bins
% calculated above
powerBandsInHz = {};
powerBinsInHz = {};
for iBand = 1:size(unwrapped_powerBandsToConvert,1)
    % Lower and upper bounds of the power band (a BAND being difined by 3 frequencies: lower, center, and upper frequencies)
    lowerBounds(iBand) = fftParameters.lower(unwrapped_powerBandsToConvert(iBand,1));
    upperBounds(iBand) = fftParameters.upper(unwrapped_powerBandsToConvert(iBand,2));
    powerBandsInHz{iBand,1} = sprintf('%.2fHz-%.2fHz', lowerBounds(iBand),upperBounds(iBand));
    
    % Bins used for FFT computed power in band (number of pins in a power
    % band are >=1)
    lowerBin(iBand) = fftParameters.fftBins(unwrapped_powerBandsToConvert(iBand,1));
    upperBin(iBand) = fftParameters.fftBins(unwrapped_powerBandsToConvert(iBand,2));
    powerBinsInHz{iBand,1} = sprintf('%.2fHz-%.2fHz', lowerBin(iBand),upperBin(iBand));
end

powerBands.powerBandsInHz = powerBandsInHz;
powerBands.powerBinsInHz = powerBinsInHz;
powerBands.lowerBound = lowerBounds';
powerBands.upperBound = upperBounds';
powerBands.fftSize = fftParameters.fftSize;
powerBands.fftBins = fftParameters.fftBins;
powerBands.binWidth = fftParameters.binWidth;
powerBands.TDsampleRate = currentTDsampleRate;

end

