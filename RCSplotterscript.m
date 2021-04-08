% RCS plotter script
%  Some usage examples:

clear

PATIENTID = 'CPRCS01'
% 'RCS02R'
% 'CPRCS01';
rootdir = '/Volumes/Prasad_X5/' ;
github_dir = '/Users/pshirvalkar/Documents/GitHub/UCSF-rcs-data-analysis';



%%
localrootdir = fullfile(rootdir,char(regexp(PATIENTID,'\w*\d\d','match'))); %match the PATIENTID up to 2 digits: ie RCS02
scbsdir = fullfile(localrootdir,'/SummitData/SummitContinuousBilateralStreaming/', PATIENTID);
aDBSdir = fullfile(localrootdir, '/SummitData/StarrLab/', PATIENTID);

cd(github_dir)
addpath(genpath(github_dir))

%% make database of all files
D = makeDataBaseRCSdata(scbsdir,aDBSdir);

%%  LOAD Database
load(fullfile(scbsdir,[PATIENTID 'database_summary.mat']))
D = sorted_database;

% find the rec # to load
% recs_to_load = (381:392);
recs_to_load= 381:389


%%  LOAD ABOVE FILES AND PLOT CHANNELS OF INTEREST

rc = rcsPlotter()

for d = recs_to_load
    diruse = [D.path{d} '/'];
    rc.addFolder(diruse);
end
      rc.loadData()

% - Plot time domain channels, spectrogram, LD, 1 acteigraphy channel, etc

% create figure
hfig = figure('Color','w');
hsb = gobjects();

            nplots = 5;
            for i = 1:nplots; hsb(i,1) = subplot(nplots,1,i); end


            rc.plotTdChannel(1,hsb(1,1));
            rc.plotTdChannel(2,hsb(2,1));
            %                rc.plotActigraphyChannel('X',hsb(3,1));
            rc.plotTdChannelSpectral(1,hsb(3,1))
            rc.plotAdaptiveLd(0,hsb(4,1));
            rc.plotAdaptiveState(hsb(5,1));


            % link axes since time domain and others streams have diff sample rates
            linkaxes(hsb,'x');


% Using the `rc.addFolder` method multiple folders can be added and plotted.