function [fftParameters] = getFFTparameters(currentFFTconfig,currentTDsampleRate)
%%
% Determine FFT parameters from FFTconfig and TD sample rate

%%
fftSize = currentFFTconfig.size;

% Determine frequency cutoffs for each FFT bin
numBins = fftSize/2;
binWidth = (currentTDsampleRate/2)/numBins;

%% OLD CODE
%lower = (0:numBins-1)*binWidth;
%fftBins = lower + binWidth/2;          % Bin center
%upper = lower + binWidth;

%% NEW CODE: 
% This fix aligns FFT bin labeling with the way it is processed 
% by Medtornic hardware. This code takes into consideration that
% the first bin is centered at zero, rather than at binwidth/2. 

upper = (0:numBins-1)*binWidth + binWidth/2; 
lower = upper - binWidth;
fftBins = upper - binWidth/2;     

fftParameters.numBins = numBins;
fftParameters.binWidth = binWidth;
fftParameters.fftBins = fftBins;
fftParameters.lower = lower;
fftParameters.upper = upper;
fftParameters.fftSize = fftSize;

end
