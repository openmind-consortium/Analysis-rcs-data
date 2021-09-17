% RCS plotter script
%  Some usage examples:

clear

PATIENTID = 'RCS05L'
% 'RCS02R'
% 'CPRCS01';
rootdir = '/Volumes/DBS Pain 3/' ;
github_dir = '/Users/pshirvalkar/Documents/GitHub/UCSF-rcs-data-analysis';



%%
localrootdir = fullfile(rootdir,char(regexp(PATIENTID,'\w*\d\d','match'))); %match the PATIENTID up to 2 digits: ie RCS02
scbsdir = fullfile(localrootdir,'/SummitData/SummitContinuousBilateralStreaming/', PATIENTID);
aDBSdir = fullfile(localrootdir, '/SummitData/StarrLab/', PATIENTID);

cd(github_dir)
addpath(genpath(github_dir))

%% make database of all files
[database_out,badsessions] = makeDataBaseRCSdata(localrootdir,PATIENTID); % add AdaptiveData.Ld0_output


%%  LOAD Database
load(fullfile(localrootdir,[PATIENTID '_database.mat']))
D = RCSdatabase_out;

% find the rec # to load
% recs_to_load = (381:392);



%%  LOAD ABOVE FILES AND PLOT CHANNELS OF INTEREST
% close all
recs_to_load= 864
rc = rcsPlotter()

for d = recs_to_load   %find the row indices corresponding to rec#
    d_idx =  find(D.rec == d);
    diruse = [D.path{d_idx(1)} '/'];
    rc.addFolder(diruse);
end
rc.loadData()

% - Plot time domain channels, spectrogram, LD, 1 acteigraphy channel, etc
% create figure
hfig = figure('Color','w');
hsb = gobjects();

nplots = 5;
for i = 1:nplots; hsb(i,1) = subplot(nplots,1,i); end


%             Time Domain
rc.plotTdChannel(1,hsb(1,1));
rc.plotTdChannel(2,hsb(2,1));
% rc.plotTdChannel(3,hsb(3,1));
rc.plotTdChannel(4,hsb(4,1));
rc.plotTdChannelSpectral(4,hsb(5,1));


% linkaxes(hsb,'x');

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





