function [newPower, newSettings] = calculateNewPower(combinedDataTable, fftSettings, powerSettings, metaData, channel, freqBand)
% calculates a new fft band power series using the streamed time domain signal and based on new power and fft settings
%
% Assumption: only one set of fftSettings and powerSettings each time this function is invoked.
% (1) Either the default (initial) settings of the recording session, or (see DEMO_CalculatePowerRCS.m, line~44)
% (2) The fftSettings and powerSettings passed via the user (see DEMO_CalculatePowerRCS.m, line~100)
% 
% Input = 
% (1) combinedDataTable
% (2) fftSettings
% (3) powerSettings 
% (4) metaData (type = output from DEMO_Process)
% (5) channel (type = integer (1..4), eg usage, channel = 1)
% (6) freqBand (type = integer array, eg usage, freqBand = [20 25])
% 
% If you find errors while using this code or want to help further develop
% it, contact juan.ansoromeo@ucsf.edu or juan.anso@gmail.com

% Parse input variables
newSettings.metaData = metaData;
newSettings.tdChannel = channel;
newSettings.bandLimits = freqBand;

% initialize with the default sesttings to have access to default settings
% relying only on first set of power and fft settings (removing all other settings changes of the session)
powerSettings(2:end,:) = []; 
newSettings.powerSettings = powerSettings;
fftSettings(2:end,:) = [];
newSettings.fftSettings = fftSettings;
ampGains = newSettings.metaData.ampGains; % actual amplifier gains per channel

% initialize output power table
newPower = table();
newPower.localTime= combinedDataTable.localTime;
newPower.DerivedTimes = combinedDataTable.DerivedTime;
newPower.calculatedPower = nan(1,size(combinedDataTable,1))';

% initialize a newPowerSettings array
newSettings.powerSettings.powerBands.indices_BandStart_BandStop(:,:) = []; 
newSettings.powerSettings.powerBands.powerBandsInHz = [];
newSettings.powerSettings.powerBands.lowerBound = [];
newSettings.powerSettings.powerBands.upperBound = [];
newSettings.powerSettings.powerBands.powerBinsInHz = [];

% claculate new frequeny bins within band
tempIndecesBinsA = find(powerSettings.powerBands.fftBins>newSettings.bandLimits(1));
tempIndecesBinsB = find(powerSettings.powerBands.fftBins<newSettings.bandLimits(2));
[C,IA,IB] = intersect(tempIndecesBinsA,tempIndecesBinsB);
binIndecesInBand = tempIndecesBinsA(IA);
binsInBand = powerSettings.powerBands.fftBins(tempIndecesBinsA(IA));

disp('---')
disp('Calculating equivalent power based on input defined [TD channel (1..4)] and [Power Band]:')
disp(['TD channel = ', num2str(channel)])
disp(['Power Band = ', num2str(newSettings.bandLimits(1)),'Hz-',num2str(newSettings.bandLimits(2)),'Hz']);
disp(['Lower bin = ', num2str(binsInBand(1)), ' Hz']);
disp(['Upper bin = ', num2str(binsInBand(end)), 'Hz']);
disp(['Total bins = ', num2str(length(binsInBand))]);
disp('---')

% add new bins information to new power band in power newSettings
newSettings.powerSettings.powerBands.indices_BandStart_BandStop = [binIndecesInBand(1) binIndecesInBand(end)];
newSettings.powerSettings.powerBands.powerBinsInHz = strcat(sprintf('%0.2f',binsInBand(1)),'Hz-',sprintf('%0.2f',binsInBand(end)),'Hz');

% extract input parameters
tch = combinedDataTable.DerivedTime;
t = seconds(tch-tch(1))/1000;
[interval,binStart,binEnd,fftSize] = readFFTsettings(newSettings.powerSettings);
sr = fftSettings.TDsampleRates;
switch fftSize % actual fft size of device for 64, 250, 1024 fftpoints
    case 64, fftSizeActual = 62;
    case 256, fftSizeActual = 250;
    case 1024, fftSizeActual = 1000;
end
keych = combinedDataTable.(['TD_key',num2str(newSettings.tdChannel-1)]); % next channel
td_rcs = transformTDtoRCS(keych,ampGains.(['Amp',num2str(newSettings.tdChannel)])); % transform TD signal to rcs internal values
overlap = 1-((sr*interval/1e3)/fftSizeActual); % time window parameters
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
        YFFT = abs(SSB/(L/2)); % scaling step 2, dividing by fft buffer size (L/2)
        fftPower = 2*(YFFT.^2); % this factor 2 is necessary to match power values from RCS
        newPower.calculatedPower(stime+L-1) = sum(fftPower(binStart:binEnd));
    end
    counter = counter + 1;
    stime = stime + (L - ceil(L*overlap));
end   

end

%% local functions used
function [interval,binStart,binEnd,fftSize] = readFFTsettings(powerSettings)
    interval = powerSettings.fftConfig.interval; % is given in ms
    binStart = powerSettings.powerBands.indices_BandStart_BandStop(1,1);
    binEnd = powerSettings.powerBands.indices_BandStart_BandStop(1,2);
    fftSize = powerSettings.fftConfig.size;
end

% transform to rcs units (equation from manufacturer - hardware specific - same in all RC+S devices)
function td_rcs = transformTDtoRCS(keych,AmpGain)
    FP_READ_UNITS_VALUE = 48644.8683623726;    % constant
    lfp_mv = nan(1,length(keych))';
    lfp_mv(~isnan(keych)) = keych(~isnan(keych))-mean(keych(~isnan(keych))); % remove mean
    config_trim_ch = AmpGain; % read from device settins
    lfpGain_ch = 250*(config_trim_ch/255);  % actual amplifier gain ch
    lfp_rcs = lfp_mv * (lfpGain_ch*FP_READ_UNITS_VALUE) / (1000*1.2); 
    td_rcs = lfp_rcs;
end