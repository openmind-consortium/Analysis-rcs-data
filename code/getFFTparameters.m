function [fftParameters] = getFFTparameters(currentFFTconfig,currentTDsampleRate)
%%
% Determine FFT parameters from FFTconfig and TD sample rate

%%
% Decode fftSize
switch currentFFTconfig.size
    case 0
        fftSize = 64;
    case 1
        fftSize = 256;
    case 3
        fftSize = 1024;
end

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

fftParameters.numBins = numBins;
fftParameters.binWidth = binWidth;
fftParameters.fftBins = fftBins;
fftParameters.lower = lower;
fftParameters.upper = upper;
fftParameters.fftSize = fftSize;

end