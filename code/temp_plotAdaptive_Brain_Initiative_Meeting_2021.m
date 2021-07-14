close all, clear all, clc

% add library
addpath('/Users/juananso/Dropbox (Personal)/Work/Git_Repo/UCSF-rcs-data-analysis/code')

% create figure
fig1 = figure(1)

%% off period
rc_off = rcsPlotter();
rc_off.addFolder('~/Starr Lab Dropbox/RC+S Patient Un-Synced Data/RCS09 Un-Synced Data/SummitData/StarrLab/RCS09R/Session1615585294490/DeviceNPC700449H'); % stim off
rc_off.loadData();

% time domain channel
t_off = rc_off.Data.combinedDataTable.localTime;
t_off = seconds(t_off-t_off(1));

lfp_off = rc_off.Data.combinedDataTable.TD_key0;
lfp_off = (lfp_off-nanmean(lfp_off))*1e3;
sbp1 = subplot(3,1,1);
plot(t_off,lfp_off)
title('LFP Signal in Stim Off period before Starting Stim Ramp')
ylabel('voltage (\muV)')
% ignore first 5 seconds data
% xlabel('time (seconds)')
xlim([5 10])
ylim([-500 500])


%% aDBS period
rc = rcsPlotter();
% rc.addFolder('~/Starr Lab Dropbox/RC+S Patient Un-Synced Data/RCS09 Un-Synced Data/SummitData/StarrLab/RCS09R/Session1615587984302/DeviceNPC700449H'); % adpative DBS 
rc.addFolder('/Users/juananso/Starr Lab Dropbox/RC+S Patient Un-Synced Data/RCS09 Un-Synced Data/SummitData/StarrLab/RCS09R/Session1615588648277/DeviceNPC700449H'); % lock out 700ms
rc.loadData();

% time domain channel
t = rc.Data.combinedDataTable.localTime;
t = seconds(t-t(1));

lfp = rc.Data.combinedDataTable.TD_key0;
lfp = (lfp-nanmean(lfp))*1e3;
sbp2 = subplot(3,1,2);
plot(t,lfp)
title('Transient Effect in LFP Signal during Stim Ramp')
ylabel('voltage (\muV)')
% ignore first 5 seconds data
% xlabel('time (seconds)')
xlim([10 15])
ylim([-500 500])

%% power and stimulation serier
pwr = rc.Data.combinedDataTable.Power_Band1;
idxpwr = ~isnan(pwr);
LD0 = rc.Data.combinedDataTable.Adaptive_Ld0_output;
idxLD = ~isnan(LD0);

detectThH = rc.Data.combinedDataTable.Adaptive_Ld0_highThreshold(idxLD);
detectThL = rc.Data.combinedDataTable.Adaptive_Ld0_lowThreshold(idxLD);

stimAmp = rc.Data.combinedDataTable.Adaptive_CurrentProgramAmplitudesInMilliamps(idxLD);
ycurrent = cell2mat(stimAmp);

sbp3 = subplot(3,1,3);
yyaxis left
plot(t(idxLD),LD0(idxLD))
hold on
plot(t(idxLD),detectThH,':')
ylabel('LD (au)')

yyaxis right
plot(t(idxLD),ycurrent)
xlim([10 15])
ylabel('Stimulation (mA)')
xlabel('time (seconds)')
title('Linear Detector follows Stimulation Ramp') 

linkaxes([sbp1,sbp2],'x')

%% Save figure to pdf
set( findall(fig1, '-property', 'fontsize'), 'fontsize', 14)

set(fig1,'Units','Inches');
pos = get(fig1,'Position');
set(fig1,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])

figdir = '~/Dropbox (Personal)/Work/UCSF/starrlab_local/2.Reporting/Posters/BrainInitiative_2021/Figures';
figureName = fullfile(figdir,'Off_And_Fast-aDBS-5s-LockOut700ms-RCS09');
print(fig1,figureName,'-dpdf','-r0')