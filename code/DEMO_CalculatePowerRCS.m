close all
clear all
clc
%%
% Select file
[fileName,pathName] = uigetfile('AllDataTables.mat');

% Load file
disp('Loading selected .mat file')
load([pathName fileName])

% Create unified table with selected data streams -- use timeDomain data as
% time base
dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};
[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);

% Compare the 'postprocessing-calculated' power data with the RCS streamed
% for the default time domain and power band settings
[combinedPowerTable, powerTablesBySetting] = getPowerFromTimeDomain(combinedDataTable,fftSettings, powerSettings, metaData,2); 
idxPowerCalc = ~isnan(combinedPowerTable.Power_Band1); % these values are computed in getPowerFromTimeDomain based on the default time channels and power settings (harmonized time)
idxPowerRCS = ~isnan(combinedDataTable.Power_Band1); % these values come from RawDataPower.json (and are harmonized in time via the combinedDataTable)
% now calculate equivalent power series from time domain channel (1..4) and a given power band [X,Y] Hz
[newPowerFromTimeDomain, newSettings] = calculateEquivalentDevicePower(combinedDataTable, fftSettings, powerSettings, metaData, 1, [4 10]);
idxPowerNewCalc = ~isnan(newPowerFromTimeDomain.calculatedPower);

% plot the results
figure, hold on, legend show, set(gca,'FontSize',15)       

plot(combinedDataTable.localTime(idxPowerRCS),combinedDataTable.(['Power_Band',num2str(1)])(idxPowerRCS),...
                        'Marker','*','MarkerSize',1,'Linewidth',1,'DisplayName',['RCS Power Band, Bins(Hz) = ',powerSettings.powerBands(1).powerBinsInHz{1}])
plot(combinedPowerTable.localTime(idxPowerCalc),combinedPowerTable.(['Power_Band',num2str(1)])(idxPowerCalc),...
                        'Marker','o','MarkerSize',5,'LineWidth',2,'DisplayName',['Calculated Power Band, Bins(Hz) = ',powerSettings.powerBands(1).powerBinsInHz{1}])                 
plot(newPowerFromTimeDomain.localTime(idxPowerNewCalc),newPowerFromTimeDomain.calculatedPower(idxPowerNewCalc),...
                        'Marker','s','MarkerSize',1,'LineWidth',2,'DisplayName',['New Calculated Power Band, Bins(Hz) = ',newSettings.powerSettings.powerBands.powerBinsInHz])
                   