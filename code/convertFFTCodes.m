function [convertedFFTconfig] = convertFFTCodes(fftConfig)
%%
% Takes information from fftConfig fields and converts codes into 
% human readable information
%%
% Copy over all values to convertedFFTConfig
convertedFFTconfig = fftConfig;

% Update values for select fields
switch fftConfig.windowLoad
    case 2
        windowLoad = '100% Hann';
    case 22
        windowLoad = '50% Hann';
    case 42
        windowLoad = '25% Hann';
    otherwise
        windowLoad = 'Unexpected';
end
convertedFFTconfig.windowLoad = windowLoad;

switch fftConfig.size
    case 0
        size = 64; % Number of points
    case 1
        size = 256;
    case 3
        size = 1024;
    otherwise
        size = 'Unexpected';
end
convertedFFTconfig.size = size;

end