function [newPowerFromTimeDomain, newSettings] = calculateEquivalentDevicePower(combinedDataTable, settings)
% calculates equivalent device power as a function of chosen power bands
% this function assumest to have in the workspace the output from DEMO_ProcessRCS.m
% Input = 
% (1) combinedDataTable
% (2) settings: cell with following structures {fftSettings, powerSettings, metaData}
%       1 = fftSettings (type = output from DEMO_Process)
%       2 = powerSettings (type = output from DEMO_Process)
%       3 = metaData (type = output from DEMO_Process)
%
% intermediate: the function will ask the user to define new power band
%       lower and upper frequencies within limits defined samplingRate/2
% 
% First prototype focuses only on user selecting a power band
%

% Parse input variables
newSettings.fftSettings = settings{1}; % fftSettings
powerSettings = settings{2}; % powerSettings
newSettings.metaData = settings{3}; % metaData

% initialize with the default sesttings to have access to default settings
newSettings.powerSettings = powerSettings;
ampGains = newSettings.metaData.ampGains; % actual amplifier gains per channel

% initialize output power table
newPowerFromTimeDomain = table();
newPowerFromTimeDomain.localTime= combinedDataTable.localTime;
newPowerFromTimeDomain.DerivedTimes = combinedDataTable.DerivedTime;
newPowerFromTimeDomain.calculatedPower = nan(1,size(combinedDataTable,1))';

% initialize a newPowerSettings array
newSettings.powerSettings.powerBands.indices_BandStart_BandStop(:,:) = []; 
newSettings.powerSettings.powerBands.powerBandsInHz = [];
newSettings.powerSettings.powerBands.lowerBound = [];
newSettings.powerSettings.powerBands.upperBound = [];
newSettings.powerSettings.powerBands.powerBinsInHz = [];

% visualize current frequency band
figure, stem(powerSettings.powerBands.fftBins,ones(1,length(powerSettings.powerBands.fftBins)))

% ask user for time domain channel and new power band limits
newSettings.tdChannel = input('time domain channel to apply power transformaiton (enter ch number 1, 2, 3 or 4)?: ');
newSettings.bandLimits = input('define lower and upper freuqncies (enter integer number in Hz, eg. [20 25])?');

% claculate new frequeny bins within band
tempIndecesBinsA = find(powerSettings.powerBands.fftBins>newSettings.bandLimits(1));
tempIndecesBinsB = find(powerSettings.powerBands.fftBins<newSettings.bandLimits(2));
[C,IA,IB] = intersect(tempIndecesBinsA,tempIndecesBinsB);
binIndecesInBand = tempIndecesBinsA(IA);
binsInBand = powerSettings.powerBands.fftBins(tempIndecesBinsA(IA))
disp(['The bins within the proposed band (', num2str(newSettings.bandLimits(1)),'Hz-',num2str(newSettings.bandLimits(2)),'Hz) limits are:']);
disp(['Lower bin = ', num2str(binsInBand(1)), ' Hz']);
disp(['Upper bin = ', num2str(binsInBand(end)), 'Hz']);
disp(['Total bins = ', num2str(length(binsInBand))]);

% add new bins information to new power band in power newSettings
newSettings.powerSettings.powerBands.indices_BandStart_BandStop = [binIndecesInBand(1) binIndecesInBand(end)];
newSettings.powerSettings.powerBands.powerBinsInHz = strcat(num2str(binsInBand(1)),'Hz-',num2str(binsInBand(end)),'Hz');

% extract input parameters
tch = combinedDataTable.DerivedTime;
t = seconds(tch-tch(1))/1000;
[interval,binStart,binEnd,fftSize] = readFFTsettings(newSettings.powerSettings);
sr = newSettings.fftSettings.TDsampleRates;
switch fftSize % actual fft size of device for 64, 250, 1024 fftpoints
    case 64, fftSizeActual = 62;
    case 256, fftSizeActual = 250;
    case 1024, fftSizeActual = 1000;
end
keych = combinedDataTable.(['TD_key',num2str(newSettings.tdChannel-1)]); % next channel
td_rcs = transformTDtoRCS(keych,ampGains.(['Amp',num2str(newSettings.tdChannel)])); % transform TD signal to rcs internal values
overlap = 1-(sr*interval/1e3/fftSizeActual); % time window parameters
L = fftSize; % timeWin is now named L, number of time window points
hann_win = 0.5*(1-cos(2*pi*(0:L-1)/(L-1))); % create hann taper function, equivalent to the Hann 100% 
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
        newPowerFromTimeDomain.calculatedPower(stime+L-1) = sum(fftPower(binStart:binEnd));
    end
    counter = counter + 1;
    stime = stime + (L - ceil(L*overlap));
end   

end

function [interval,binStart,binEnd,fftSize] = readFFTsettings(powerSettings)
    interval = powerSettings.fftConfig.interval; % is given in ms
    binStart = powerSettings.powerBands.indices_BandStart_BandStop(1,1);
    binEnd = powerSettings.powerBands.indices_BandStart_BandStop(1,2);
    fftSize = powerSettings.fftConfig.size;
end

function td_rcs = transformTDtoRCS(keych,AmpGain)
    FP_READ_UNITS_VALUE = 48644.8683623726;    % predefined value from hardware 
    lfp_mv = nan(1,length(keych))';
    lfp_mv(~isnan(keych)) = keych(~isnan(keych))-mean(keych(~isnan(keych))); % remove mean
    config_trim_ch = AmpGain; % read from device settins (see above) 
    lfpGain_ch = 250*(config_trim_ch/255);  % actual gain amplifier ch
    lfp_rcs = lfp_mv * (lfpGain_ch*FP_READ_UNITS_VALUE) / (1000*1.2); % transform to rcs units
    td_rcs = lfp_rcs;
end