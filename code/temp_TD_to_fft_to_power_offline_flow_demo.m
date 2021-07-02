close all
clear all
clc

% graphical representation of 'off-line' power calculation 

% Input User Parameters
saveFigure = 1;
stringTitleInputSignal = 'Clay example XXX' % 'Benchtop sinusoidal s(n), 50 \muV, 20Hz';
savedir = '~/Box/UCSF-RCS_Test_Datasets_Analysis-rcs-data-Code/For-Internal-Debugging/Benchtop/Power/DEBUGGING';
firname = 'Figure_DS4';
td_ch = 1
fontSize = 14;

%% This code assumes you have run ProcessRCS and/or DEMO_LoadRCS.m
% select file
[fileName,pathName] = uigetfile('AllDataTables.mat');

%% Load file
disp('Loading selected .mat file')
load([pathName fileName])

%% Create unified table with selected data streams -- use timeDomain data as time base
dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};
[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);

%% Init Figure
fig1 = figure(1); fontSize = 16;
set(gcf, 'Units', 'Normalized', 'OuterPosition', [1/2, 0, 1/2, 1]);

% extract input time and default power band from rcs (ch1)
tch = combinedDataTable.localTime;
t = seconds(tch-tch(1));
pwrB1 = combinedDataTable.Power_Band1;
idxpwr = ~isnan(pwrB1);
tpwr = t(idxpwr);

[interval,binStart,binEnd,fftSize] = readFFTsettings(powerSettings);
fftBinsHz = powerSettings.powerBands.fftBins;
sr = fftSettings.TDsampleRates;
switch fftSize % actual fft size of device for 64, 250, 1024 fftpoints
    case 64, fftSizeActual = 62.5;
    case 256, fftSizeActual = 250;
    case 1024, fftSizeActual = 1000;
end

keych = combinedDataTable.(['TD_key',num2str(td_ch-1)]); % next channel
td_rcs = transformTDtoRCS(keych,metaData.ampGains.(['Amp',num2str(td_ch)])); % transform TD signal to rcs internal values

subplot(411)
title(stringTitleInputSignal)
yyaxis left, hold on
plot(t,keych)
ylabel('voltage (mV)')
yyaxis right
plot(t,td_rcs,'Marker','.','LineWidth',0.1)
ylabel('voltage (rcs units)')
axis tight

overlap = 1-((sr*interval/1e3)/fftSizeActual); % time window parameters
L = fftSize; % timeWin is now named L, number of time window points
hann_win = hannWindow(L,fftSettings.fftConfig.windowLoad);
stime = 1; % sample 1 of data set where window starts
totalTimeWindows = ceil(length(td_rcs)/L/(1-overlap)); 
counter = 1; % initialize counter

% output fft parameter
subplot(424), hold on, axis off, 
startCol1 = 0; startY = 0.75;
text(startCol1,startY,'FFT settings','FontWeight','bold')
text(startCol1,startY-.125,['Sampling rate = ', num2str(sr),' Hz'])
text(startCol1,startY-.25,['FFT size (L) = ', num2str(L), ' pnts'])
text(startCol1,startY-.375,['FFT interval = ', num2str(interval), ' ms'])
text(startCol1,startY-.500,['FFT overlap = ', num2str(overlap*100), ' %'])
text(startCol1,startY-.65,['Freq band = ', num2str(powerSettings.powerBands.lowerBound(1),4), ' - ' , num2str(powerSettings.powerBands.upperBound(1),4),' Hz'])
text(startCol1,startY-.775,['Freq bins = ', num2str(fftBinsHz(binStart),4), ' - ' , num2str(fftBinsHz(binEnd),4),' Hz'])

% plot signal and hann window signal
subplot(423), hold on
plot(t(stime:stime+L-1),td_rcs(stime:stime+L-1))
plot(t(stime:stime+L-1),td_rcs(stime:stime+L-1)'.*hann_win,'r')
title('s(n) windowed')
legend('s(n)','s(n) * hann')
axis tight
set(gca,'fontsize', fontSize)

% plot power signal from RCS
subplot(414)
plot(tpwr,pwrB1(idxpwr),'color','b','LineWidth',2)
ylabel('power (rcs units)')
xlabel('time (s)')
axis tight

while counter <= round(totalTimeWindows*(1/2)) % loop through time singal
    if stime+L <= length(t) % check at least one time window available before reach end signal
        
        % indicate where in time the running window is on time domain signal
        subplot(411), yyaxis right, hold on
        plot(t(stime+L),0,'sk')
        legend('s(n) raw','s(n) rcs','fft window i')
        
        % plot signal and hann window signal
        subplot(423), hold off
        plot(t(stime:stime+L-1),td_rcs(stime:stime+L-1)), hold on
        plot(t(stime:stime+L-1),td_rcs(stime:stime+L-1)'.*hann_win,'r')
        title('next s(n) RCS Hann windowed')
        legend('s(i-L:i)','s(i-L:i) * hann')
        ylabel('voltage (rcs units)')
        xlabel('time (s)')
        axis tight
        set(gca,'fontsize', fontSize)
        
        %% FFT
        X = fft(td_rcs(stime:stime+L-1)'.*hann_win,fftSize); % fft of the next window
        SSB = X(1:L/2); % from double to single sided FFT
        SSB(2:end) = 2*SSB(2:end); % scaling step 1, multiply by 2 bins 2 to end (all except DC)
        YFFT = abs(SSB/(L/2)); % scaling step 2, dividing by fft buffer size (L/2)
        
        % plot calculated fft of last time window
        subplot(413), yyaxis right, hold off
        stem(fftBinsHz(1:length(YFFT)),YFFT,'LineWidth',2); hold on
        plot(fftBinsHz(1:length(YFFT)),YFFT,'LineWidth',1);
        title('fft last time window'), xlabel('Center frequency bins (Hz)')
        ylabel('|FFT calculated| (rcs units)')
        set(gca,'fontsize', fontSize)
        
        % superimpose actual fft from RCS
        if counter<=size(FFTData,1)
            yyaxis left, hold off
            plot(fftBinsHz,1e4*FFTData.FftOutput{counter},'-o');
            ylabel('FFT_{API} (x 1e4)')
            xlabel('Center frequency bins (Hz)')
%             legend('fft rcs','fft calculated')
        end
        
        %% POWER
        fftPower = 2*(YFFT.^2); % this factor 2 is necessary to match power values from RCS
        newPower(stime+L-1) = sum(fftPower(binStart:binEnd));
        
        % plot caculated power (red +) on same pannel as RCS (magenta)
        if counter<=length(tpwr)
            subplot(414), hold on          
            stem(t(1:(stime+L-1)),newPower(1:(stime+L-1)),'color','r','LineWidth',0.1)
            title('Power series "on-device" vs "off-device"'), ylabel('power (rcs units)')
            legend('on-device', 'off-device')
            axis tight
            set(gca,'fontsize', fontSize)
        end
        
    end
    
    counter = counter + 1;
    stime = stime + (L - ceil(L*overlap));
    
    % to let plot process be visualized
    pause(0.01)    
    set( findall(fig1, '-property', 'fontsize'), 'fontsize', fontSize)
    
end

%% save figure for paper
if saveFigure
    saveas(fig1,fullfile(savedir,firname),'epsc')
    saveas(fig1,fullfile(savedir,firname),'fig')
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
