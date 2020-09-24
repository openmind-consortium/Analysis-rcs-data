function [powerTable, pbOut]  = createPowerTable(folderPath)
%%
% Function to unravel Power data
% Input: 
%   jsonobj_Power: a structure of power data that is read from RawDataPower.json
%   (To transform *.json file into structure use deserializeJSON.m)
%
%   folderPath: path to the Device* folder, which contains all the .json
%   files for this recording
%
% Output: 
%%
% Load power data
rawPowerData = jsondecode(fixMalformedJson(fileread([folderPath filesep 'RawDataPower.json']),'EventLog'));

% Initalize output
powerTable = table();
pbOut = struct();

% If no power data, return empty tables, otherwise start parsing 
if isempty(rawPowerData) || isempty(rawPowerData.PowerDomainData)
    fprintf('Power data  is empty\n');
    fprintf('Creating dummy event table\n');
    powerTable  = [];
    pbOut = [];
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
    
    % Parsing data conatined in rawPowerData.PowerDomainData
    PowerDomainData = [rawPowerData.PowerDomainData];
    variableNames = {'PacketGenTime','PacketRxUnixTime',...
        'ExternalValuesMask','FftSize','IsPowerChannelOverrange','SampleRate','ValidDataMask'};
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
%%
    
    % load device settings file as well to find out power bins in Hz
    % this depends on running
    % loadDeviceSettings.m
    % and also depeends on having
    % DeviceSettings.json in the same folder
    % as the power data
    [rootdir,filename] = fileparts(fn);
    load(fullfile(rootdir,'DeviceSettings.mat'));
    pbOut = struct();
    for oo = 1:size(outRec,2)
        sampleRate = str2double(strrep( outRec(oo).tdData(1).sampleRate,'Hz',''));
        switch outRec(oo).fftConfig.size
            case 0
                fftSize = 64;
            case 1
                fftSize = 256;
            case 3
                fftSize = 1024;
        end
        powerChannelsIdxs = [];
        idxCnt = 1;
        for c = 1:4
            for iBand = 0:1
                fieldStart = sprintf('band%dStart',iBand);
                fieldStop = sprintf('band%dStop',iBand);
                powerChannelsIdxs(idxCnt,1) = outRec(oo).powerChannels(c).(fieldStart);
                powerChannelsIdxs(idxCnt,2) = outRec(oo).powerChannels(c).(fieldStop);
                idxCnt = idxCnt+1;
            end
        end
        
        % power data
        % notes to compute bins
        
        %%
        numBins = fftSize/2;
        binWidth = (sampleRate/2)/numBins;
        i = 0;
        bins = [];
        while i < numBins
            bins(i+1) = i*binWidth;
            i =  i + 1;
        end
        
        
        FFTSize = fftSize; % can be 64  256  1024
        sampleRate = sampleRate; % can be 250,500,1000
        
        numberOfBins = FFTSize/2;
        binWidth = sampleRate/2/numberOfBins;
        
        for i = 0:(numberOfBins-1)
            fftBins(i+1) = i*binWidth;
            %     fprintf('bins numbers %.2f\n',fftBins(i+1));
        end
        
        lower(1) = 0;
        for i = 2:length(fftBins)
            valInHz = fftBins(i)-fftBins(2)/2;
            lower(i) = valInHz;
        end
        
        for i = 1:length(fftBins)
            valInHz = fftBins(i)+fftBins(2)/2;
            upper(i) = valInHz;
        end
        
        %%
        powerChannelsIdxs = powerChannelsIdxs + 1; % since C# is 0 indexed and Matlab is 1 indexed.
        powerBandInHz = {};
        for pc = 1:size(powerChannelsIdxs,1)
            powerBandInHz{pc,1} = sprintf('%.2fHz-%.2fHz',...
                lower(powerChannelsIdxs(pc,1)),upper(powerChannelsIdxs(pc,2)));
        end
        pbOut(oo).powerBandInHz = powerBandInHz;
        pbOut(oo).powerChannelsIdxs = powerChannelsIdxs;
        pbOut(oo).fftSize = fftSize;
        pbOut(oo).bins = bins;
        pbOut(oo).numBins = numBins;
        pbOut(oo).binWidth = binWidth;
        pbOut(oo).sampleRate = sampleRate;
    end
end



