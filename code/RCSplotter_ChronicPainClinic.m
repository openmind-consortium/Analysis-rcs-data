%% rcsplotter for in-clinic testing


rc = rcsPlotter();

% RCS01

rc.addFolder('/Users/ashlynschmitgen/Documents/RCS01_Current/CL_042621/Session1619468207806/DeviceNPC700435H/')

%RCS02


rc.loadData()

% create figure
hfig = figure('Color','w');
hsb = gobjects();
nplots = 6; %update
for i = 1:nplots
       hsb(i,1) = subplot(nplots,1,i); 
end
rc.plotTdChannel(1,hsb(1,1)); title('TD Channel')
rc.plotTdChannelSpectral(1,hsb(2,1)); title('Spectrogram')
rc.plotActigraphyChannel('X',hsb(3,1)); title('Accelerometry')
rc.plotAdaptiveLd(0, hsb(4,1)); title('LD0 Thresholds')
rc.plotAdaptiveCurrent(0, hsb(5,1)); title('Current Delivered (mA)')
rc.plotAdaptiveState(hsb(6,1)); title('Adaptive State');

% link axes since time domain and acc have differnt
% sample rates: 
%linkaxes(hsb,'x');

rc.reportPowerBands %prints