% RCS plotter script
%  Some usage examples:

clear

PATIENTIDside =  'RCS02R'
% 'RCS02R'
% 'CPRCS01';
rootdir = '/Volumes/PrasadX5/' ;
github_dir = '/Users/pshirvalkar/Documents/GitHub/UCSF-rcs-data-analysis';
patientrootdir = fullfile(rootdir,char(regexp(PATIENTIDside,'\w*\d\d','match'))); %match the PATIENTID up to 2 digits: ie RCS02

cd(github_dir)
addpath(genpath(github_dir))

%% make database of all files
[database_out,badsessions] = makeDataBaseRCSdata(patientrootdir,PATIENTIDside ); % add AdaptiveData.Ld0_output


%%  LOAD Database
load(fullfile(patientrootdir,[PATIENTIDside '_database.mat']))
D = RCSdatabase_out; 

D(end-30:end,:) 


%%  LOAD ABOVE FILES AND PLOT CHANNELS OF INTEREST
% close all

%%%%%%%%%%%%%%
% recs_to_load =   D.rec(end-60:end-30)
recs_to_load =   10:16
%%%%%%%%%%%%%%

rc = rcsPlotter();

for d = 1:numel(recs_to_load)  %find the row indices corresponding to rec#
    d_idx =  find(D.rec == recs_to_load(d));
    diruse = [D.path{d_idx(1)} '/'];
    rc.addFolder(diruse);
end
rc.loadData()

% report out the channel names  / locations etc. 
rc.reportDataQualityAndGaps(1)
rc.reportStimSettings
rc.reportPowerBands
%% SET your feature and stim channels

pwr_to_time_ch_idx = [1,1,2,2,3,3,4,4];

% ========Change below =======
pd.feature =5;
pd.stim = 4;
% ============================ 

td.feature = pwr_to_time_ch_idx(pd.feature);
td.stim = pwr_to_time_ch_idx(pd.stim);




%% - Plot time domain channels, spectrogram, LD, 1 acteigraphy channel, etc
% create figure
close all
hfig = figure('Color','w');
hsb = gobjects();

nplots = 4;
for i = 1:nplots; hsb(i,1) = subplot(nplots,1,i); end


%             Time Domain
rc.plotTdChannel(td.feature,hsb(1,1));
rc.plotTdChannelSpectral(td.feature,hsb(2,1));
rc.plotTdChannel(td.stim,hsb(3,1));
rc.plotTdChannelSpectral(td.stim,hsb(4,1)); 
% rc.plotAdaptiveLd(0,hsb(5,1));ylim([0 100])
% rc.plotAdaptiveCurrent(0,(hsb(6,1)))
% rc.plotAdaptiveState(0,hsb(7,1))

linkaxes(hsb,'x');

%%             SPECTRA

% create figure
hfig = figure('Color','w');
hsb = gobjects();
nplots = 5;
for i = 1:nplots; hsb(i,1) = subplot(nplots,1,i); end


rc.plotTdChannel(1,hsb(1,1));
rc.plotTdChannelSpectral(1,hsb(2,1));
rc.plotTdChannelSpectral(2,hsb(3,1))
rc.plotTdChannelSpectral(3,hsb(4,1))
rc.plotTdChannelSpectral(4,hsb(5,1))

linkaxes(hsb,'x');
%%             ADAPTIVE STATE

% create figure
hfig = figure('Color','w');
hsb = gobjects();
nplots = 5;
for i = 1:nplots; hsb(i,1) = subplot(nplots,1,i); end

rc.plotAdaptiveLd(0,hsb(1,1));
rc.plotAdaptiveState(hsb(2,1));
rc.plotAdaptiveCurrent(hsb(3,1));

% link axes since time domain and others streams have diff sample rates
linkaxes(hsb,'x');


% Using the `rc.addFolder` method multiple folders can be added and plotted.

%% Plot and report the gaps


% create figure
hfig = figure('Color','w');
hsb = gobjects();
nplots = 5;
for i = 1:nplots; hsb(i,1) = subplot(nplots,1,i); end


rc.plotTdChannelDataGaps(1,hsb(1,1))
rc.plotTdChannelDataGaps(2,hsb(2,1))
rc.plotTdChannelDataGaps(3,hsb(3,1))
rc.plotTdChannelDataGaps(4,hsb(4,1))
% rc.plotActigraphyChannel(1)
% linkaxes(hsb,'x');
rc.reportDataQualityAndGaps(1)





