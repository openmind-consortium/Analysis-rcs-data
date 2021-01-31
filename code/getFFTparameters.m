function [fftParameters] = getFFTparameters(currentFFTconfig,currentTDsampleRate)
%%
% Determine FFT parameters from FFTconfig and TD sample rate

%%
fftSize = currentFFTconfig.size;

% Determine frequency cutoffs for each FFT bin
numBins = fftSize/2;
binWidth = (currentTDsampleRate/2)/numBins;

lower = (0:numBins-1)*binWidth;
fftBins = lower + binWidth/2;          % Bin center
upper = lower + binWidth;

fftParameters.numBins = numBins;
fftParameters.binWidth = binWidth;
fftParameters.fftBins = fftBins;
fftParameters.lower = lower;
fftParameters.upper = upper;
fftParameters.fftSize = fftSize;

end
