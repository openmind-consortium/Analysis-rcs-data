close all
clear all
clc

%% Testing datasets
% This code has been tested with a set of datasets under
% ~/Box/UCSF-RCS_Test_Datasets_Analysis-rcs-data-Code/../Power/...
% Access to this folder is managed and restricted to UCSF employees under
% (https://ucsf.box.com/s/bolhachjv80rhywa5h0r9peo73mz3003)
%
% This example code can be run with a benchotp dataset that is shared for any user under
% https://ucsf.box.com/s/9bte1t8s4il7rr0ot4egwsae1exl5y7i

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

%% Example how to compare streamed power from device and 'off line' calculated power, given
% - predefined fftSettings
% - predefined powerSettings

% 'off-device'
    
% Here we get the power calculated 'off-line' using the time domain
% for each power channel that have been streamed
[combinedPowerTable, powerTablesBySetting] = getPowerFromTimeDomain(combinedDataTable,fftSettings, powerSettings, metaData,2); 
idxPowerRCS = ~isnan(combinedDataTable.Power_Band1);

% plot the result, comparing actual Streamed power with 'off line'
fig1 = figure, hold on, legend show, set(gca,'FontSize',14)       
plot(combinedDataTable.localTime(idxPowerRCS),...
            combinedDataTable.(['Power_Band',num2str(1)])(idxPowerRCS),...
            'Marker','*','MarkerSize',1,'Linewidth',1,...
            'DisplayName',['on-device, Band bins (Hz) = ',powerSettings.powerBands(1).powerBinsInHz{1}])

% on-device
% time domain channel (1, 2, 3 or 4) for a chosen power band [X,Y]Hz
freqBand = [powerSettings.powerBands.lowerBound(1) powerSettings.powerBands.upperBound(1)]
[newPowerFromTimeDomain, newSettings] = calculateNewPower(combinedDataTable, fftSettings, powerSettings, metaData, 1, freqBand);
idxPowerNewCalc = ~isnan(newPowerFromTimeDomain.calculatedPower);  

% plot the result
plot(newPowerFromTimeDomain.localTime(idxPowerNewCalc),...
            newPowerFromTimeDomain.calculatedPower(idxPowerNewCalc),...
            'Marker','o','MarkerSize',1,'LineWidth',1,...
            'DisplayName',['off-device, Band bins (Hz) = ',newSettings.powerSettings.powerBands.powerBinsInHz])
       
ylabel('Power (rcs units)')

% save dir for paper
savedir = '/Users/juananso/Dropbox (Personal)/Work/UCSF/starrlab_local/2.Reporting/Manuscripts/DBS Think Tank/Figures/';
firname = 'Figure10a';
saveas(fig1,fullfile(savedir,firname),'epsc')

% zoom into ~2seconds of data around the middle of dataset
% ax1 = fig1.Children;
% fig2 = figure, hold on, legend show, set(gca,'FontSize',14);  
% ax2 = copyobj(ax1,fig2);
t_zoomstart = combinedDataTable.localTime(round(length(idxPowerRCS)/2));
t_zoomsends = t_zoomstart + seconds(120);
xlim([t_zoomstart t_zoomsends])
legend off
firname = 'Figure10a_zoomed';
saveas(fig1,fullfile(savedir,firname),'epsc')

%% Compare calculation
% unify the data points given different idx
x = combinedDataTable.(['Power_Band',num2str(1)])(idxPowerRCS);
tx = combinedDataTable.localTime(idxPowerRCS);
y = newPowerFromTimeDomain.calculatedPower(idxPowerNewCalc);
ty = newPowerFromTimeDomain.localTime(idxPowerNewCalc);

for ii=1:length(y)
    tynext = ty(ii);
    idx = find(tx >= tynext,1);    
    txnext = tx(idx);
    tdiff = abs(milliseconds(tynext-txnext));
    if tdiff < 50
        px(ii) = x(idx);
        py(ii) = y(ii);
    end
end

% ROOT MEAN SQUARE ERROR
RMSE = sqrt((sum((px-py).^2))/length(px)); % or RMSE = sqrt(mean((px-py).^2));
NRMSE = RMSE/(max(py)-min(py));

% Percentage difference, "percentage difference" is via the standard
% Euclidean norm (% assuming they're sampled uniformly over the interval)
% the difference between two series divided by the average of the two series. Shown as a percentage.
% see: https://dsp.stackexchange.com/questions/14306/percentage-difference-between-two-signals
PERC_DIFF = 100 * (dot(px-py, px-py)/sqrt(dot(px,px)*dot(py,py)));

fig2 = figure
scatter(px,py)
xlabel('Power on-device (rcs units)')
ylabel('Power off-device (rcs units)')
text(1000,7000,['RMSE = ', num2str(RMSE,5), ' (rcs units)'],'FontSize',14)
text(1000,6500,['Percentage difference = ', num2str(PERC_DIFF,3), '%'],'FontSize',14)
set(gca,'FontSize',14)

firname = 'Figure10b1';
saveas(fig2,fullfile(savedir,firname),'epsc')

fig3 = figure
scatter(px/(max(px)-min(px)),py/(max(py)-min(py)),'filled','AlphaData',0.01,'SizeData',1)
hold on
hline = refline(1,0)
xlabel('Power on-device (normalized units)')
ylabel('Power off-device (normalized units)')
text(1000/(max(px)-min(px)),7000/(max(py)-min(py)),['NRMSE = ', num2str(NRMSE,2), ' (normalized RMSE)'],'FontSize',14)
text(1000/(max(px)-min(px)),6500/(max(py)-min(py)),['Percentage difference = ', num2str(PERC_DIFF,3), '%'],'FontSize',14)
set(gca,'FontSize',14)

firname = 'Figure10b2';
saveas(fig3,fullfile(savedir,firname),'epsc')