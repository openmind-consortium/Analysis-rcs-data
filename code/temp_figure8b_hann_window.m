close all
clear all
clc

%% Comparison of different Hann Windows on same signal

%% This code assumes you have run ProcessRCS and/or DEMO_LoadRCS.m
% Select file
[fileName,pathName] = uigetfile('AllDataTables.mat');

% Load file
disp('Loading selected .mat file')
load([pathName fileName])

% Create unified table with selected data streams -- use timeDomain data as
% time base
dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};
[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);

winLoad = ["100% Hann" "50% Hann" "25% Hann"];

freqBand = [20,23];
ch = 1;

fig1 = figure, hold on, set(gca,'FontSize',14)   
for i_winLoad = 1:3
    fftSettings.fftConfig.windowLoad = winLoad(i_winLoad);
    power = calculateNewPower(combinedDataTable,fftSettings,powerSettings,metaData,ch,freqBand);  
    idxpower = ~isnan(power.calculatedPower);
    tpwr = power.localTime(idxpower);
    plot(seconds(tpwr-tpwr(1)),power.calculatedPower(idxpower),'LineWidth',2,'DisplayName',char(winLoad(i_winLoad)))
end

legend show
title('Power off-device different Hann Window Loads')
xlabel('Time(s)')
ylabel('Power(rcs units)')

% save dir for paper
savedir = '/Users/juananso/Dropbox (Personal)/Work/UCSF/starrlab_local/2.Reporting/Manuscripts/DBS Think Tank/Figures';
firname = 'Figure8b'
saveas(fig1,fullfile(savedir,firname),'epsc')