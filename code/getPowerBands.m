

function [powerBands] = getPowerBands(*)

    % Get device settings
    outRec = loadDeviceSettings([folderPath filesep 'DeviceSettings.json']);
        
    % Initalize powerBand output
    pbOut = struct();
    
    % KS HERE
    for iSetting = 1:size(outRec,2)
        sampleRate = str2double(strrep( outRec(iSetting).tdData(1).sampleRate,'Hz',''));
        % Decode fftSize
        switch outRec(iSetting).fftConfig.size
            case 0
                fftSize = 64;
            case 1
                fftSize = 256;
            case 3
                fftSize = 1024;
        end
        
        powerChannelsIdxs = [];
        counter = 1;
        for iChan = 1:4 % max of 4 bipolar electrode pairs
            for iBand = 0:1 % max of 2 bands on each bipolar electrode pair
                fieldStart = sprintf('band%dStart',iBand);
                fieldStop = sprintf('band%dStop',iBand);
                powerChannelsIdxs(counter,1) = outRec(iSetting).powerChannels(iChan).(fieldStart);
                powerChannelsIdxs(counter,2) = outRec(iSetting).powerChannels(iChan).(fieldStop);
                counter = counter+1;
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
        pbOut(iSetting).powerBandInHz = powerBandInHz;
        pbOut(iSetting).powerChannelsIdxs = powerChannelsIdxs;
        pbOut(iSetting).fftSize = fftSize;
        pbOut(iSetting).bins = bins;
        pbOut(iSetting).numBins = numBins;
        pbOut(iSetting).binWidth = binWidth;
        pbOut(iSetting).sampleRate = sampleRate;