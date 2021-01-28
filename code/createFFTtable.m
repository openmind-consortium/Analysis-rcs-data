function [FFTtable] = createFFTtable(jsonobj_FFT)
%%
% Function for creating table with raw FFT data
%
% Input: jsonobj of raw FFT data 
%
% Output: FFTtable
%
%%
% Initalize output
FFTtable = table();
headerTable = table();
%%
% Parsing data contained in headers
Header = [jsonobj_FFT.FftData.Header];
variableNames = {'dataSize','dataType','dataTypeSequence','systemTick'};
headerData = struct();
for iVariable = 1:length(variableNames)
    headerData.(variableNames{iVariable}) = [Header.(variableNames{iVariable})]';
end

% Parsing timestamp (stored inside struct)
timestamps = [Header.timestamp];
headerData.timestamp =  struct2array(timestamps)';

% Convert headerData to table
headerTable = struct2table(headerData);

% Parsing data conatined in rawPowerData.PowerDomainData
FFTtable = struct2table(jsonobj_FFT.FftData);
FFTtable = FFTtable(:,{'PacketGenTime','PacketRxUnixTime','Channel','FftSize','FftOutput','Units'});

% Converting TD samplerate
FFTtable.TDsamplerate = getSampleRate([jsonobj_FFT.FftData.SampleRate]');

% Combine header and FFT table info
FFTtable = [FFTtable headerTable];
end