function  [powerFromTimeDomain] = getPowerFromTimeDomain(combinedDataTable,fftSettings, powerSettings, metaData)
% creates a table with power computed signals from time domain signal using
% an equivalent process to the internal power computation in the device
% power is computed using
% - hann windowing of latest fft interval (new and old points, depending on overlapping)
% - fft is applied
% - power calculated as sum of power of all bins in the frequency band
% 
% Inputs:
%   (1) combinedDataTable
%   (2) fftSettings
%   (3) powerSettings
%   (4) metaData
%
% output
%   powerFromTimeDomain = table(harmoinized times, derived times, PB1,PB2,PB3,...,PB8)
%
% Assumptions:
% - hann window 100%
% - no change in fft and power settings in data set
%

% initialize output power 
powerFromTimeDomain = table();
powerFromTimeDomain.localTime= combinedDataTable.localTime;
powerFromTimeDomain.DerivedTimes = combinedDataTable.DerivedTime;
for inumBands = 1:8 % initialize bands
    powerFromTimeDomain.(['PowerCh',num2str(inumBands)]) = nan(1,size(combinedDataTable,1))';
end

% loop for each time domain channel
for c=1:4
    % extract input parameters
    tch = combinedDataTable.DerivedTime;
    t = seconds(tch-tch(1))/1000;
    [interval,binStart,binEnd,fftSize] = readFFTsettings(powerSettings,c);
    sr = fftSettings.TDsampleRates;
    switch fftSize % actual fft size of device for 64, 250, 1024 fftpoints
        case 64, fftSizeActual = 62;
        case 256, fftSizeActual = 250;
        case 1024, fftSizeActual = 1000;
    end
    keych = combinedDataTable.(['TD_key',num2str(c-1)]); % next channel
    td_rcs = transformTDtoRCS(keych,metaData.ampGains.(['Amp',num2str(c)])); % transform TD signal to rcs internal values
    overlap = 1-(sr*interval/1e3/fftSizeActual); % time window parameters
    L = fftSize; % timeWin is now named L, number of time window points
    hann_win = hannWindow(L,fftSettings.fftConfig.windowLoad);
    stime = 1; % sample 1 of data set where window starts
    totalTimeWindows = ceil(length(td_rcs)/L/(1-overlap)); 
    counter = 1; % initialize counter
    while counter <= totalTimeWindows % loop through time singal
        if stime+L <= length(t) % check at least one time window available before reach end signal
            X = fft(td_rcs(stime:stime+L-1)'.*hann_win,fftSize); % fft of the next window
            SSB = X(1:L/2); % from double to single sided FFT
            SSB(2:end) = 2*SSB(2:end); % scaling step 1, multiply by 2 bins 2 to end (all except DC)
            YFFT = abs(SSB/(L/2)); % scaling step 2, dividing by fft buffer size (L/2) (to be hoest i think this should be L)
            fftPower = 2*(YFFT.^2); % this factor 2 is necessary to match power values from RCS
            binStartBand1 = binStart(2*c-1);
            binEndBand1 = binEnd(2*c-1);
            binStartBand2 = binStart(2*c);
            binEndBand2 = binEnd(2*c);
            powerFromTimeDomain.(['PowerCh',num2str(2*c-1)])(stime+L-1) = sum(fftPower(binStartBand1:binEndBand1));
            powerFromTimeDomain.(['PowerCh',num2str(2*c)])(stime+L-1) = sum(fftPower(binStartBand2:binEndBand2));
        end
        counter = counter + 1;
        stime = stime + (L - ceil(L*overlap));
    end   
end
end

function [interval,binStart,binEnd,fftSize] = readFFTsettings(powerSettings,c)
    % at the moment assuming the only active Power Band is Band 0
    interval = powerSettings.fftConfig.interval; % is given in ms
    for iBand = 1:size(powerSettings.powerBands.indices_BandStart_BandStop,1)
        binStart(iBand) = powerSettings.powerBands.indices_BandStart_BandStop(iBand,1);
        binEnd(iBand) = powerSettings.powerBands.indices_BandStart_BandStop(iBand,2);
    end
    fftSize = powerSettings.fftConfig.size;
end

% transform to rcs units (equation from manufacturer - hardware specific - same in all RC+S devices)
function td_rcs = transformTDtoRCS(keych,AmpGain)
    FP_READ_UNITS_VALUE = 48644.8683623726;    % constant
    lfp_mv = nan(1,length(keych))';
    lfp_mv(~isnan(keych)) = keych(~isnan(keych))-mean(keych(~isnan(keych))); % remove mean
    config_trim_ch = AmpGain; % read from device settins
    lfpGain_ch = 250*(config_trim_ch/255);  % actual gain amplifier ch
    lfp_rcs = lfp_mv * (lfpGain_ch*FP_READ_UNITS_VALUE) / (1000*1.2);
    td_rcs = lfp_rcs;
end

end