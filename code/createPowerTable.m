function [powerTable]  = createPowerTable(folderPath)
%%
% Function to unravel Power data
% Input:
%   folderPath: path to the Device* folder, which contains all the .json
%   files for this recording
%
% Output: powerTable (power data in table format, without band limits
% decoded)
%%
% Load power data
rawPowerData = jsondecode(fixMalformedJson(fileread([folderPath filesep 'RawDataPower.json']),'EventLog'));

% Initalize output
powerTable = table();

% If no power data, return empty tables, otherwise start parsing
if isempty(rawPowerData) || isempty(rawPowerData.PowerDomainData)
    fprintf('Power data  is empty\n');
    fprintf('Creating dummy event table\n');
    powerTable  = [];
else
    % Parsing data contained in headers
    Header = [rawPowerData.PowerDomainData.Header];
    variableNames = {'dataSize','dataType','dataTypeSequence',...
        'globalSequence','info','systemTick'};
    powerData = struct();
    for iVariable = 1:length(variableNames)
        powerData.(variableNames{iVariable}) = [Header.(variableNames{iVariable})]';
    end
    % Parsing timestamp (stored inside struct)
    timestamps = [Header.timestamp];
    powerData.timestamp =  struct2array(timestamps)';
    
    % Converting TD samplerate
    powerData.TDsamplerate = getSampleRate([rawPowerData.PowerDomainData.SampleRate]');
    
    % Parsing data conatined in rawPowerData.PowerDomainData
    PowerDomainData = [rawPowerData.PowerDomainData];
    variableNames = {'PacketGenTime','PacketRxUnixTime',...
        'ExternalValuesMask','FftSize','IsPowerChannelOverrange','ValidDataMask'};
    for iVariable = 1:length(variableNames)
        powerData.(variableNames{iVariable}) = [PowerDomainData.(variableNames{iVariable})]';
    end
    
    % Parsing data conatined in Bands
    bands = [PowerDomainData.Bands]';
    for iBand = 1:size(bands,2)
        bandName = sprintf('Band%d',iBand);
        powerData.(bandName) = bands(:,iBand);
    end
    
    powerTable = struct2table(powerData);
end



