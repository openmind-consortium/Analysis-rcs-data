%Pain  CL optimizer using RCSplotter
% This will make databases and then help to visualize data and combine it
% to analyze the power bands/ FFT bands of interest. 
% 
% 

clear
clc

PATIENTIDside =  ['RCS02R']
% 'RCS02R'
% 'CPRCS01';
rootdir = '/Volumes/PrasadX5/' ;
github_dir = '/Users/pshirvalkar/Documents/GitHub/UCSF-rcs-data-analysis';
patientrootdir = fullfile(rootdir,char(regexp(PATIENTIDside,'\w*\d\d','match'))); %match the PATIENTID up to 2 digits: ie RCS02

cd(github_dir)
addpath(genpath(github_dir))

%% make database of all files
[RCSdatabase_out,badsessions] = makeDataBaseRCSdata(patientrootdir,PATIENTIDside,1); % add AdaptiveData.Ld0_output

%%  LOAD Database
load(fullfile(patientrootdir,[PATIENTIDside '_database.mat']))


% Plot the 50 most recent subsessions
RCSdatabase_out(end-100:end,:)


%%  LOAD ABOVE FILES AND PLOT CHANNELS OF INTEREST
% close all

%%%%%%%%%%%%%%
% *** NOTE - only load INTEGER sessions, such as 201, 202, 207, etc.  no need to
% load subsessions (e.g. 201.2) as these are all loaded automatically.

% recs_to_load =   D.rec(end-60:end-30)
recs_to_load =  [928]
%%%%%%%%%%%%%%

rc = rcsPlotter();

for d = 1:numel(recs_to_load)  %find the row indices corresponding to rec#
    d_idx =  find(RCSdatabase_out.rec == recs_to_load(d));
    diruse = [RCSdatabase_out.path{d_idx}];
    if ~isempty(diruse)
        rc.addFolder(diruse);
    end
end
rc.loadData()

% report out the channel names  / locations etc.

rc.reportStimSettings
rc.reportPowerBands
rc.reportDataQualityAndGaps(1)
%% SET your feature and stim channels
% ========Change below =======
pd.feature = 5;
pd.stim = 4;

% RCS02R - feat/stim = 5/4  (ACC/Vp Thalamus)
% RCS04L - 2/8
% RCS04R - 
% RCS05L - 5/4  ACC/ LCaudate
% RCS05R - 5/4 IFG/ Thal
% ============================


pwr_to_time_ch_idx = [1,1,2,2,3,3,4,4];
td.feature = pwr_to_time_ch_idx(pd.feature);
td.stim = pwr_to_time_ch_idx(pd.stim);

fprintf('Feature = %s %s \nStim    = %s %s \n',rc.Data(1).timeDomainSettings.(['chan' num2str(td.feature)]){1}(1:5),...
    rc.Data(1).powerSettings.powerBands(end).powerBandsInHz{pd.feature},...
    rc.Data(1).timeDomainSettings.(['chan' num2str(td.stim)]){1}(1:5),...
    rc.Data(1).powerSettings.powerBands(end).powerBandsInHz{pd.stim})
%% - Plot time domain channels, spectrogram, LD, actigraphy etc. as you wish


close all
hfig = figure('Color','w');
hsb = gobjects();

nplots = 5;
for i = 1:nplots; hsb(i,1) = subplot(nplots,1,i); end


%             Time Domain
rc.plotTdChannel(td.feature,hsb(1,1));
rc.plotTdChannelSpectral(td.feature,hsb(2,1));
rc.plotTdChannel(td.stim,hsb(3,1));
rc.plotTdChannelSpectral(td.stim,hsb(4,1));
rc.plotActigraphyRms(1,hsb(5,1));
linkaxes(hsb,'x');

%%            TD and Raw
close all
% create figure
hfig = figure('Color','w');
hsb = gobjects()
nplots = 10;
for i = 1:nplots; hsb(i,1) = subplot(nplots,1,i); end


rc.plotTdChannel(1,hsb(1,1));
rc.plotTdChannelSpectral(1,hsb(2,1));
rc.plotTdChannel(2,hsb(3,1));
rc.plotTdChannelSpectral(2,hsb(4,1));
rc.plotTdChannel(3,hsb(5,1));
rc.plotTdChannelSpectral(3,hsb(6,1));
rc.plotTdChannel(4,hsb(7,1));
rc.plotTdChannelSpectral(4,hsb(8,1));

rc.plotPowerRaw(pd.feature,hsb(9,1))
rc.plotPowerRaw(pd.stim,hsb(10,1))

linkaxes(hsb,'x');
%%             ADAPTIVE STATE
% Assumes that programmed current amplitudes only occur in 0.5mA increments
% (all else is ramping)

hfig = figure('Color','w');
hsb = gobjects();
nplots = 3;
for i = 1:nplots; hsb(i,1) = subplot(nplots,1,i); end
rc.plotAdaptiveLd(0,hsb(1,1));
ylim([0 hsb(1,1).UserData.prctiles(end-2,2)]); %limit y axis to 90%ile
rc.plotAdaptiveState(0,hsb(2,1));
rc.plotAdaptiveCurrent(0,hsb(3,1));

% link axes since time domain and others streams have diff sample rates
linkaxes(hsb,'x');

%%  plot the distributions Ld0 state, separated by stim on/ off / ramp
% USES actual STIM Current! (at present it assumes stim is in whole #s)

holdLD = []; holdcurrent = []; holdmA=[];
holdfeatpwr = [];
holdstimpwr = [];

for x = 1:numel(rc.Data)
    if sum(contains(rc.Data(x).combinedDataTable.Properties.VariableNames,'Adaptive_Ld0_output'))
        holdLD = [holdLD ; rc.Data(x).combinedDataTable.Adaptive_Ld0_output];
        holdcurrent = [holdcurrent; rc.Data(x).combinedDataTable.Adaptive_CurrentProgramAmplitudesInMilliamps];
        holdfeatpwr = [holdfeatpwr;rc.Data(x).combinedDataTable.(['Power_Band' num2str(pd.feature)])];
        holdstimpwr = [holdstimpwr;rc.Data(x).combinedDataTable.(['Power_Band' num2str(pd.stim)])];

        %     get the state definitions for current amplitudes
        statefields =fields(rc.Data(x).AdaptiveStimSettings.states);
        idxmA = find(contains(statefields,'AmpInMilliamps'));
        statecurrent = cell2mat(arrayfun(@(i) rc.Data(x).AdaptiveStimSettings.states.(statefields{i}),idxmA,'UniformOutput',false));
        statecurrent = statecurrent(:,1);

        holdmA(:,x) =  statecurrent;

  
    end
end

statemA = (0:1:5);
% unique(holdmA);
idx_ld = ~isnan(holdLD);
LDvals  = holdLD(idx_ld);
featpwr = holdfeatpwr(idx_ld);
stimpwr = holdstimpwr(idx_ld);

if isempty(holdLD)
    disp('    :(  no LD data!!!!! ')
else
    

currentvals = cell2mat(holdcurrent(idx_ld));
currentvals  = currentvals(:,1); %only program 0




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% change this to indicate LDvals or powervals to plot %%%%%%%%%%%
plotvals = LDvals;
% plotvals = featpwr;
% plotvals = stimpwr;

binlims = [0 200];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




figure
% filter out stim data, and then include only stim data
stimQ={'stimOFF','stimON','rampON'};
idx=1;
stim =[]; nostim=[]; ramp=[];
for s=1:numel(stimQ)
    stimidx = currentvals >0 & ismember(currentvals,statemA); % if defined current value
    rampidx = ~(ismember(currentvals,statemA)); %if not defined current value (assumed 0mA is defined in a state)
    nostimidx = (currentvals == 0);


    Ldplot = plotvals;

    %create separate vars for stimOFF and stimON  and transition data
    if s==1
        Ldplot(~nostimidx)=nan; %only no stim data
        nostim = Ldplot;
    elseif s==2
        Ldplot(~stimidx)=nan; %only stim data
        stim = Ldplot;
    elseif s==3     %transition / ramp points
        Ldplot(~rampidx)=nan; %only stim data
        ramp = Ldplot;
    end
    ss(s) = subplot(3,1,idx); idx=idx+1;
    h=histogram(ss(s),Ldplot,200,'BinLimits',binlims, 'Normalization','count');
    hold on
    plot([nanmedian(Ldplot) nanmedian(Ldplot)],[0,max(h.Values)],'LineWidth',2,'LineStyle','--')   %plot the median value

    xlabel('LD value')


    %      add useful stats
    statinfo = ["%ile","0","2.5","10","25","50","75","97.5"];
    statinfo2=  string(prctile(Ldplot,[0,2.5,10,25,50,75,97.5]));

    %Fix this to plot on top of dashed lines
    text(0.7,0.5,[statinfo],'Units','normalized','FontSize',16);
    text(0.75,0.5,[" ",statinfo2],'Units','normalized','FontSize',16);
    titlestr=[stimQ{s}];
    title(titlestr);


end
set(gcf,'Position', [561 210 1016 739])
% linkaxes(ss,'y')
end




%% 6.0 ONSET and OFFSET DURATION helper
% calculate how long the LD0 signal of interest is above some threshold value before dropping below it (and vice versa)



%%%%%%%%%%% CHANGE ME!%%%%%%%%%%%%%%%%
Threshold = [rc.Data(1).DetectorSettings.Ld0.biasTerm(1)];
Threshold = 100;
num_bins = 50;
plot_duration = 60; %(in seconds)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Ramp_duration =  enter ramp duration here and plot, so you know that
% offset duration must be longer than this
SampleRate = rc.Data(1).DetectorSettings.Ld0.updateRate; % LdA update rate multiple of FFT Fs
usedata= rc.Data(1).combinedDataTable.Adaptive_Ld0_output ;
ldhold = usedata(~isnan(usedata));

% close all
h=figure;


alltimes_aboveT=[];
alltimes_belowT=[];


timeaboveT=[];
timebelowT=[];
clear belowT aboveT samples_*

% get non-overlapping mean of windows of length UpdateRate
% pwrhold1 = mean(reshape(usedata(1:UpdateRate * floor(numel(usedata) / UpdateRate)), [], UpdateRate), 2);
% pwrhold2 =  (repmat(pwrhold1',1,UpdateRate))';
% pwrhold(1:numel(pwrhold2)) = pwrhold2(:);

%  find samples where pwr < threshold
belowT = find(ldhold < Threshold);

% OFFSET duration where pwr > threshold
aboveT = find(ldhold > Threshold);

% how many samples until > threshold again?
% what is this in time?
diffbelowT = diff(belowT); %when diffbelowT > 1, this nanmeans  that signal went above threshold for diffbelowT(n) samples before returning below
samples_aboveT =  diffbelowT(diffbelowT>1);
timeaboveT = samples_aboveT ./ SampleRate;

diffaboveT = diff(aboveT);
samples_belowT =  diffaboveT(diffaboveT>1);
timebelowT = samples_belowT ./ SampleRate;

alltimes_aboveT = [alltimes_aboveT; timeaboveT];
alltimes_belowT = [alltimes_belowT; timebelowT];


%
s1 = subplot(1,2,1);
histogram(s1,alltimes_aboveT,num_bins,'BinLimits',[0 plot_duration],'Normalization','probability');
prcnt = ["%ile  ","10%  ","25%  ","50%  ","75%  ";" ",string(prctile(alltimes_aboveT,[10,25,50,75]))];
statinfo = ["LD"," "; "Threshold = ", num2str(Threshold)];
prcnt_txt = cat(1,statinfo,prcnt');
text(0.7,0.7,strcat(prcnt_txt(:,1),prcnt_txt(:,2)),'Units','normalized','FontSize',14);
% ylabel('probability')
xlabel('time (sec)')
title({'ONSET duration';'Distribution of continuous time that LD > Threshold before dropping below'})

s2 = subplot(1,2,2);
histogram(s2,alltimes_belowT,num_bins,'BinLimits',[0 plot_duration],'Normalization','probability');
prcnt2 = ["%ile  ","10%  ","25%  ","50%  ","75%  ";" ",string(prctile(alltimes_belowT,[10,25,50,75]))];
statinfo2 = ["LD"," "; "Threshold = ", num2str(Threshold)];
prcnt_txt = cat(1,statinfo2,prcnt2');
text(0.7,0.7,strcat(prcnt_txt(:,1),prcnt_txt(:,2)),'Units','normalized','FontSize',14);
% ylabel('probability')
xlabel('time (sec)')
title({'OFFSET duration';'Distribution of continuous time that LD < Threshold before rising above'})

h.Position =[1436 799 1361 368];




%   RECREATE THE THEORETICAL STATE CHANGES THAT WOULD OCCUR GIVEN THAT
%   THRESHOLD
%% Pain correlations NOT FUNCTIONAL RN

figure

for f = 1:length(fnames)

    subplot(numf,1,f)
    scatter(nanmeanpwr{f},PWRmeta.pain) 
    title([num2str(PWRmeta.ctrFq{f}) ' Hz:  ' PWRmeta.contacts{f}])
end

xlabel('power')
ylabel('pain')



