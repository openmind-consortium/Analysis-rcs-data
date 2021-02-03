function [convertedFFTconfig] = convertFFTCodes(fftConfig)
%%
% Takes information from fftConfig fields and converts codes into
% human readable information
%%
% Copy over all values to convertedFFTConfig
convertedFFTconfig = fftConfig;

% Update values for select fields
switch fftConfig.bandFormationConfig
    case 8
        bandFormationConfig = 'Shift7, throw away upper 7 bits';
    case 9
        bandFormationConfig = 'Shift6, throw away upper 6 bits';
    case 10
        bandFormationConfig = 'Shift5, throw away upper 5 bits';
    case 11
        bandFormationConfig = 'Shift4, throw away upper 4 bits';
    case 12
        bandFormationConfig = 'Shift3, throw away upper 3 bits';
    case 13
        bandFormationConfig = 'Shift2, throw away upper 2 bits';
    case 14
        bandFormationConfig = 'Shift1, throw away upper 1 bit';
    case 15
        bandFormationConfig = 'Shift0, keep upper most 32 bits';
end
convertedFFTconfig.bandFormationConfig = bandFormationConfig;

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

switch fftConfig.streamSizeBins
    case 0
        % 0 indicates full FFT - number of bins depends on FFT size
        switch size
            case 64
                streamSizeBins = 32;
            case 256
                streamSizeBins = 128;
            case 1024
                streamSizeBins = 512;
            otherwise
                streamSizeBins = 'Unexpected';
        end
    otherwise
        % Non-zero indicates partial FFT, number of bins can vary depending
        % on user selection and FFT size
        streamSizeBins = fftConfig.streamSizeBins;
end
convertedFFTconfig.streamSizeBins = streamSizeBins;

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



end