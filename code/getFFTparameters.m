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

fftBins = (0:numBins-1)*binWidth;  % Center
lower = [fftBins(1),fftBins(2:end)-binWidth/2];
upper = fftBins+binWidth/2;

fftParameters.numBins = numBins;
fftParameters.binWidth = binWidth;
fftParameters.fftBins = fftBins;
fftParameters.lower = lower;
fftParameters.upper = upper;
fftParameters.fftSize = fftSize;

end