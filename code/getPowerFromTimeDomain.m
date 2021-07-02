function  [combinedPowerTable, powerTablesBySetting] = getPowerFromTimeDomain(combinedDataTable,fftSettings, powerSettings, metaData, calculationType)
% creates a table with power computed signals from time domain signal using
% equivalent process to internal power computation in the RC+S device. The
% user inputs with 'calculationType' '1' or '2' the desired output format
% of the power talbe ('1': assumes same setting through recording, and '2':
% several settings through recording and one power table per recodring).
% 
% Power is computed using
% - hann windowing of latest fft interval (new and old points, depending on overlapping)
% - fft is applied
% - power calculated as sum of power of all bins in the frequency band
% 
% Inputs:
%   (1) combinedDataTable
%   (2) fftSettings
%   (3) powerSettings
%   (4) metaData
%   (5) calculationType (integer) = 1 or 2
%        = 1 -> default: assumes same power settings throughout the whole recording
%        = 2 -> for each recording segments in a session calculates equivalent power
%
% outputs
%   default (calculationType == 1)
%       -> combinedPowerTable = table(harmoinized times, derived times, PB1,PB2,PB3,...,PB8)
%   calculationType == 2
%       --> combinedPowerTable
%       --> powerTablesBySettings
%
% If you find errors while using this code or want to help further develop
% it, contact juan.ansoromeo@ucsf.edu or juan.anso@gmail.com

if nargin <4 || nargin > 5
    error('input arguments must be at least the following 4 variables: combinedDataTable, fftSettings, powerSettings, metaData, calculationType (optional, 1 (default) or 2)')
elseif nargin == 4 % default, assume only 1 set of power settings (remove rest from powerSettings table)
        powerSettings(2:end,:) = []; 
elseif nargin == 5
    if calculationType == 1
        powerSettings(2:end,:) = []; % remove additional powerSetttings raw
    elseif calculationType == 2 % looks for potential different recordings within session        
        % don nothing here, it does in loop by only filling in a
        % powerTableBySetting if that's input by user and there is several
        % recording segments in the session
    else
        error('the last argument (calcualtionType) must be either (default, not passed) or an integer 1 or 2')
    end
end

% initialize tables
combinedPowerTable = table();
combinedPowerTable.localTime= combinedDataTable.localTime;
combinedPowerTable.DerivedTimes = combinedDataTable.DerivedTime;
for inumBands = 1:8, combinedPowerTable.(['Power_Band',num2str(inumBands)]) = nan(1,size(combinedDataTable,1))'; end % initialize bands
if calculationType == 2
    powerTablesBySetting = table();    
end

%   loop through combined data table in 1 shot (calculationType 1) or
%   indexing subsets of time series data based on the start and stop time
%   defined in powerSettings
for inumRec = 1:size(powerSettings,1)
    if size(powerSettings,1) > 1 % search power subdataset in the session 
        timeFormat = sprintf('%+03.0f:00',metaData.UTCoffset);
        timeStart = powerSettings.timeStart(inumRec);     
        localTimeStart = datetime(timeStart/1000,'ConvertFrom','posixTime','TimeZone',timeFormat,'Format','dd-MMM-yyyy HH:mm:ss.SSS');
        timeStop = powerSettings.timeStop(inumRec);
        localTimeStop = datetime(timeStop/1000,'ConvertFrom','posixTime','TimeZone',timeFormat,'Format','dd-MMM-yyyy HH:mm:ss.SSS');
        idxRecordA = find(combinedDataTable.localTime >= localTimeStart);
        idxRecordB = find(combinedDataTable.localTime <= localTimeStop);
        [C,idA] = intersect(idxRecordA,idxRecordB);
        idxRecordUse = C(idA);
    else
        idxRecordUse = 1:size(combinedDataTable,1);
    end        
    % initialize output power 
    powerTable = table();
    powerTable.localTime= combinedDataTable.localTime(idxRecordUse);
    powerTable.DerivedTimes = combinedDataTable.DerivedTime(idxRecordUse);    
    for inumBands = 1:8 % initialize bands
        powerTable.(['Power_Band',num2str(inumBands)]) = nan(1,length(idxRecordUse))';
    end
    % loop for each time domain channel
    for c=1:4
        % extract input parameters
        tch = combinedDataTable.DerivedTime(idxRecordUse);
        t = seconds(tch-tch(1))/1000;
        [interval,binStart,binEnd,fftSize] = readFFTsettings(powerSettings,inumRec);
        sr = fftSettings.TDsampleRates;
        switch fftSize % actual fft size of device for 64, 256, 1024 fftpoints
            case 64, fftSizeActual = 62;
            case 256, fftSizeActual = 250;
            case 1024, fftSizeActual = 1000;
        end
        keych = combinedDataTable.(['TD_key',num2str(c-1)]); % next channel
        keychUse = keych(idxRecordUse);
        td_rcs = transformTDtoRCS(keychUse,metaData.ampGains.(['Amp',num2str(c)])); % transform TD signal to rcs internal values
        overlap = 1-(sr*interval/1e3/fftSizeActual); % time window parameters
        L = fftSizeActual; % timeWin is now named L, number of time window points
        hann_win = hannWindow(L,fftSettings.fftConfig.windowLoad);
        stime = 1; % sample 1 of data set where window starts
        totalTimeWindows = ceil(length(td_rcs)/L/(1-overlap)); 
        counter = 1; % initialize counter
        while counter <= totalTimeWindows % loop through time singal
            if stime+L <= length(t) % check at least one time window available before reach end signal
                X = fft(td_rcs(stime:stime+L-1)'.*hann_win,fftSizeActual); % fft of the next window
                SSB = X(1:L/2); % from double to single sided FFT
                SSB(2:end) = 2*SSB(2:end); % scaling step 1, multiply by 2 bins 2 to end (all except DC)
                YFFT = abs(SSB/(L/2)); % scaling step 2, dividing by fft buffer size (L/2) (to be hoest i think this should be L)
                fftPower = 2*(YFFT.^2); % this factor 2 is necessary to match power values from RCS
                binStartBand1 = binStart(2*c-1);
                binEndBand1 = binEnd(2*c-1);
                binStartBand2 = binStart(2*c);
                binEndBand2 = binEnd(2*c);
                powerTable.(['Power_Band',num2str(2*c-1)])(stime+L-1) = sum(fftPower(binStartBand1:binEndBand1));
                powerTable.(['Power_Band',num2str(2*c)])(stime+L-1) = sum(fftPower(binStartBand2:binEndBand2));
            end
            counter = counter + 1;
            stime = stime + (L - ceil(L*overlap));
        end   
    end
    % only fills in partial power tables by settings if input by user
    % (calculation type ==2) && there is serveral recording segments
    if calculationType == 2 && size(powerSettings,1) > 1    
          changePowerSettings = array2table(inumRec*ones(size(powerTable,1),1));
          tempTable = [changePowerSettings,powerTable];
          powerTablesBySetting = [powerTablesBySetting ; tempTable];
          if inumRec == size(powerSettings,1)
              powerTablesBySetting.Properties.VariableNames(1) = "Power Settings Change Number";
          end
    end    
    combinedPowerTable(idxRecordUse(1):idxRecordUse(end),3:size(combinedPowerTable,2)) = powerTable(:,3:end);
end
end

function [interval,binStart,binEnd,fftSize] = readFFTsettings(powerSettings, inumRec)
    % at the moment assuming the only active Power Band is Band 0
    interval = powerSettings.fftConfig(inumRec).interval; % is given in ms
    for iBand = 1:size(powerSettings.powerBands(inumRec).indices_BandStart_BandStop,1)
        binStart(iBand) = powerSettings.powerBands(inumRec).indices_BandStart_BandStop(iBand,1);
        binEnd(iBand) = powerSettings.powerBands(inumRec).indices_BandStart_BandStop(iBand,2);
    end
    fftSize = powerSettings.fftConfig(inumRec).size;
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