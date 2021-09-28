
%  prasad 2021-jan21
% RCS
%
% This script performs the following basic analyses of power channel data
% for RCS data using aDBS single sessions
%
% 1. Load data
% 2. plot or image the actual power channels recorded in the session (PWR)
% 3. Plot power over Time of DAY
% 4. Plot Histograms of Power value distribution
% 5. Define a threshold, and see what the distibutions of continuous time
% spent ABOVE and BELOW threshold are (to help determine ONSET and OFFSET
% times)
%
% Prasad SEP 2021
%

% DECLARE YOUR PERSONAL PATHS HERE YO!

clear
clc

PATIENTIDside =  'RCS02R'
% 'RCS02R'
% 'CPRCS01';
rootdir = '/Volumes/PrasadX5/' ;
github_dir = '/Users/pshirvalkar/Documents/GitHub/UCSF-rcs-data-analysis';
patientrootdir = fullfile(rootdir,char(regexp(PATIENTIDside,'\w*\d\d','match'))); %match the PATIENTID up to 2 digits: ie RCS02
scbsdir = fullfile(patientrootdir,'/SummitData/SummitContinuousBilateralStreaming/', PATIENTIDside);
adbsdir = fullfile(patientrootdir, '/SummitData/StarrLab/', PATIENTIDside);

cd(github_dir)
addpath(genpath(github_dir))

%% make database of all files
[database_out,badsessions] = makeDataBaseRCSdata(patientrootdir,PATIENTIDside); % add AdaptiveData.Ld0_output

%%  LOAD Database
load(fullfile(patientrootdir,[PATIENTIDside '_database.mat']))
D = RCSdatabase_out;
%%  LOAD DATA of interest, Concatenate it, and KEEP in temporary Variables
 

% find the rec # to load
% recs_to_load = (381:392);
recs_to_load= 913




% find out if a mat file was already created in this folder
% if so, just an update is needed and will not recreate mat file
clear cat* ch* Pwr*
catPWR.time=[];
catPWRmeta=[];
catLD0 = [];
catLD0time = [];
catstate = [];
for p1=1:8
    catPWR.(['ch' num2str(p1)]) = [];
end

idx=1;
for d = recs_to_load
    diruse = D.path{d};
    
    fprintf('\n \n Reading Session Folder %d of %d  \n',d,recs_to_load(end));
    if isempty(diruse) % no data exists inside
        fprintf('No data...\n');
        
    else % process the data
        try
            clear combinedDataTable timeDomainData AccelData PowerData FFTData AdaptiveData *Settings
            [unifiedDerivedTimes,...
                timeDomainData, timeDomainData_onlyTimeVariables, timeDomain_timeVariableNames,...
                AccelData, AccelData_onlyTimeVariables, Accel_timeVariableNames,...
                PowerData, PowerData_onlyTimeVariables, Power_timeVariableNames,...
                FFTData, FFTData_onlyTimeVariables, FFT_timeVariableNames,...
                AdaptiveData, AdaptiveData_onlyTimeVariables, Adaptive_timeVariableNames,...
                timeDomainSettings, powerSettings, fftSettings, eventLogTable,...
                metaData, stimSettingsOut, stimMetaData, stimLogSettings,...
                DetectorSettings, AdaptiveStimSettings, AdaptiveEmbeddedRuns_StimSettings,...
                versionInfo] = ProcessRCS(diruse,3);
            %        do not save
            
            % load(fullfile(diruse,'AllDataTables.mat'));
            
            % Create unified table with selected data streams -- use timeDomain data as
            % time base
            dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};
            [combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);

            catPWRmeta(idx).bands=powerSettings.powerBands.powerBandsInHz;
            catPWRmeta(idx).ch = {timeDomainSettings.chan1{1},timeDomainSettings.chan2{1},timeDomainSettings.chan3{1},timeDomainSettings.chan4{1}};
            catPWR.time = [catPWR.time;combinedDataTable.localTime(~isnan(combinedDataTable.Power_Band1))];
            catLD0 = [catLD0;combinedDataTable.Adaptive_Ld0_output(~isnan(combinedDataTable.Power_Band1))];
            catLD0time= [catLD0time;combinedDataTable.localTime(~isnan(combinedDataTable.Power_Band1))];
            catstate = [catstate;combinedDataTable.Adaptive_CurrentAdaptiveState(~isnan(combinedDataTable.Power_Band1))];
            
            catPWR.ld0 = catLD0;
            catPWR.ld0time = catLD0time;
            catPWR.state = catstate; %convert this to numbers and nan for no state
            
            chpat  = '^(+)\d*-\d*';
            chidx = [1,1,2,2,3,3,4,4];
            
            for p1 = 1:8
                
                catPWR.(['ch' num2str(p1)]) = [catPWR.(['ch' num2str(p1)]);combinedDataTable.(['Power_Band' num2str(p1)])(~isnan(combinedDataTable.Power_Band1))];
                ch_name = regexp(catPWRmeta.ch{chidx(p1)},chpat,'match');
                PwrChan{p1}  = [ch_name{1} '  ' catPWRmeta.bands{p1}];
                
                if p1 < 5 % first four power bands
                 chloc{p1} = [metaData.leadLocations{1}(1:5) ' '  metaData.leadTargets{1}];
                else
                  chloc{p1} = [metaData.leadLocations{3}(1:5) ' '  metaData.leadTargets{3}];  
                end
                
                 
            end
            
            PwrChan = cellstr(PwrChan');
            chloc = cellstr(chloc');
            catPWRmeta(idx).chpwr = PwrChan;
            catPWRmeta(idx).chloc = chloc;
            
            idx=idx+1;
            disp('file read')
        catch
            idx=idx+1;
        end
    end
end

disp('DONE!')

%%
% Show channel and power settings
fprintf('Power Ch settings: \n')  

for x= 1:length(catPWRmeta) 
chdisp = table((1:8)',string(catPWRmeta(end).chpwr),string(catPWRmeta).chloc),'VariableNames',{'Channel','contact/pwr','location'})
end 

%% 1.0 define the FEATURE and STIM channels and plot them
%  *** YOU can technically do all of this with RCSplotter ***
% just feed it the session of interest and then do the stim on /off analysis below!

% =================
featurechannel = 5;
stimchannel = 4;
% =================

channels=[featurechannel,stimchannel];
chname = {'Feature';'Stim'};
pwrdetails = catPWRmeta(end).chpwr(channels);
chloc = catPWRmeta(end).chloc(channels);

% 2.0 Plotting of concatenated raw power over REAL time

for f = 1: numel(channels) 
    %     hasdata = find(arrayfun(@(PWR) any(PWR.(fnames{f})),PWR));
    
    
    subplot(2,1,f)
    plot(catPWR.time,catPWR.(['ch' num2str(channels(f))]));
    hold on
    xlabel('time')
    
    
    titlestr = [chname{f} pwrdetails(f) chloc(f)];
    title(titlestr);
end


%% 3.0 Plot recordings over TIME OF DAY

% fnames = {stimchannel,featurechannel};
% stimOFFonly = 1; %for only plotting stim off data
%
%
% for f = 1:numel(fnames)
%     hasdata = find(arrayfun(@(PWR) any(PWR.(fnames{f})),PWR));
%
%     figure
%
%     for h=1:numel(hasdata)
%
%         pwrplot= PWR(hasdata(h)).(fnames{f});
%         tod = timeofday(PWRmeta(hasdata(h)).time);
%         timevec = linspace(tod,tod + seconds(PWRmeta(hasdata(h)).duration), numel(pwrplot));
%         if stimOFFonly == 1
%         plot(timevec(PWR(hasdata(h)).(stimchannel)<stim_thresh),pwrplot(PWR(hasdata(h)).(stimchannel)<stim_thresh));
%
%         else
%             plot(timevec,pwrplot);
%
%         end
%         hold on
%
%     end
%
%  if contains(fnames{f},'ch')
%        titlestr{f}=PWRmeta(1).(fnames{f});
%    else
%        titlestr{f} = fnames{f};
%  end
%  title(titlestr{f});
%   xlabel('Time of DAY')
% end

%% 4.0 Power Distribution Histograms - - separate stim on and stim off data - generates STIM and NOSTIM

close all
stim_thresh = 10000; %value above which stim is occurring on the stim channel (including the ramp time)
% filter out stim data, and then include only stim data
stimQ={'stimOFF','stimON'};
channels={featurechannel,stimchannel};
idx=1;
for s=1:2
    stimidx = catPWR.ch2 > stim_thresh;
    holdpwr = [];
    
    for f = 1:numel(channels)
        holdpwr=catPWR.(['ch' num2str(channels{f})]);
        %create separate vars for stimOFF and stimON data
        if s==1
            holdpwr(stimidx)=nan; %only no stim data
            nostim.(['ch' num2str(channels{f})]) = holdpwr;
        elseif s==2
            holdpwr(~stimidx)=nan; %only stim data
            stim.(['ch' num2str(channels{f})]) = holdpwr;
        end
        ss= subplot(numel(channels),2,idx); idx=idx+1;
        h=histogram(ss,holdpwr,100,'Normalization','probability');
        hold on
        plot([nanmedian(holdpwr) nanmedian(holdpwr)],[0,max(h.Values)],'LineWidth',2,'LineStyle','--')   %plot the median value
        
        xlabel('Power value')
        %      add useful stats
        statinfo = {['median = ' num2str(nanmedian(holdpwr))]; ['Range = ' num2str(min(holdpwr)) ' to ' num2str(max(holdpwr))]};
        text(0.5,0.5,statinfo,'Units','normalized');
        
        titlestr=[stimQ{s} '-' pwrdetails{f}]
        title(titlestr);
    end
    
end
tilefigs()

%% 5.0 2 channel case - Calculate the LDA distance and plot against reported distance
% ASSUMES Fs of 2 Hz for FFT/ Power

close all

% ### DEFINE Threshold
Threshold = 40000; %  Default weight vector (stim channel should have weight 1, all others -1)

% % ### Constants for LDA equation
weights = [-1, 0];
norm_const.a = [0, 0];
norm_const.b = [1, 1];
SampleRate=2;
UpdateRate = 10;




input1 = [catPWR.ch1,catPWR.ch2];
%     detect = cell2mat(cellfun(@(x) regexp(x,'\d'),catstate,'UniformOutput',false));

% Calculate LDA
mvinput1 = movmean(input1,[UpdateRate 0]);
calcLDA = calc_lda(mvinput1,weights,norm_const,Threshold);

time = catPWR.time;

h=figure;
s1 = subplot(4,1,1);
stairs(catLD0time,catLD0)
title('embedded RC+S LD0 and state')
hold on
% stairs(detect)
plot([catLD0time(1) catLD0time(end)],[Threshold Threshold],'r')
xlim([min(catLD0time) max(catLD0time)])
% xlim([0 numel(catLD0)/SampleRate])
ylimvals = s1.YLim;

subplot 412
stairs(time,calcLDA)
title('offline computed LDA')
hold on
plot([catLD0time(1) catLD0time(end)],[Threshold Threshold],'r')
xlim([min(catLD0time) max(catLD0time)])
% xlim([0 numel(calcLDA)/SampleRate]);
ylim(s1.YLim)

subplot 413
area(time,input1(:,1),'FaceColor','red')
title('Stimulation Channel Power')
xlim([min(catLD0time) max(catLD0time)])
% xlim([0 numel(calcLDA)/SampleRate]);

subplot 414
plot(time,input1(:,2))
title('Feature Channel Power')
xlabel('time (sec)')
h.Position =[848 886 2248 535];
sgtitle(['Weights [' num2str(weights) ']  Threshold = ' num2str(Threshold)])
xlim([min(catLD0time) max(catLD0time)])
% xlim([0 numel(calcLDA)/SampleRate]);

figure
plot(input1(:,1),input1(:,2),'o')
xlabel('Stimulation Channel PWR')
ylabel('Feature Channel PWR')


%% calculate B / threshold for LD using STIM AND FEATURE channel inputs
close all
format longg
% how many quartiles for feature channel?  q2 =median

Q = quantile(nostim.(featurechannel),[0.25,0.5,0.75])
% Q = q2;

% x1 = Q; %you could also calculate one std above nanmean to make threshold?
x1= nanmean(nostim.(featurechannel)) + nanstd(nostim.(featurechannel));
x2 = nanmean(stim.(featurechannel));
y1 = nanmean(nostim.(stimchannel));
y2 = nanmean(stim.(stimchannel));
W= [-1, 1];

b_lb = (x1*W(1) + y1*W(2));
b_ub = (x2*W(2) + y2*W(2));
fprintf('%0.1f < Threshold < %0.1f \n',b_lb,b_ub)

%% 6.0 ONSET and OFFSET DURATION helper
% calculate how long the power signal of interest is above some threshold value before dropping below it (and vice versa)
% do this for each recording separately

Threshold = 350000
num_bins = 100;
UpdateRate = 10; % LdA update rate multiple of FFT Fs
usedata= catLD0;
pwrhold = zeros(numel(catLD0),1);
% usedata = find(arrayfun(@(PWR) any(PWR.(ch_num)),PWR)); % sme as hasdata
% Threshold = 130;
%

close all
h=figure;


alltimes_aboveT=[];
alltimes_belowT=[];


timeaboveT=[];
timebelowT=[];
clear belowT aboveT samples_*

% get non-overlapping mean of windows of length UpdateRate
pwrhold1 = mean(reshape(usedata(1:UpdateRate * floor(numel(usedata) / UpdateRate)), [], UpdateRate), 2);
pwrhold2 =  (repmat(pwrhold1',1,UpdateRate))';
pwrhold(1:numel(pwrhold2)) = pwrhold2(:);

%  find samples where pwr < threshold
belowT = find(pwrhold < Threshold);

% OFFSET duration where pwr > threshold
aboveT = find(pwrhold > Threshold);

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


% stim_ch = 'ch1';
% stim_thresh = 415; %value above which stim is occurring
%
% close all
% % filter out stim data, and then include only stim data
% stimQ={'stim off','stim on only'};
% for s=1:2
%
%
% if strcmp(fnames{f},stim_ch) %define stim periods based on stim channel
%     stimidx = catpower > stim_thresh;
% end
%
%
% if s==1
%     catpower(stimidx)=nan; %only no stim data
%     nostim.(fnames{f}) = catpower;
% elseif s==2
%     catpower(~stimidx)=nan; %only stim data
%     stim.(fnames{f}) = catpower;
% end
%

%
s1 = subplot(1,2,1);
histogram(s1,alltimes_aboveT,num_bins,'Normalization','count');
statinfo = {'LD'; ['Threshold = ' num2str(Threshold)]; ['median = ' num2str(nanmedian(alltimes_aboveT)) ' sec']; ['std = ' num2str(std(alltimes_aboveT))]};
text(0.7,0.7,statinfo,'Units','normalized','FontSize',14);
ylabel('probability')
xlabel('time (sec)')
title({'ONSET duration';'Distribution of continuous time that LD > Threshold before dropping below'})

s2 = subplot(1,2,2);
histogram(s2,alltimes_belowT,num_bins,'Normalization','count');
statinfo2 = {'LD'; ['Threshold = ' num2str(Threshold)]; ['median = ' num2str(nanmedian(alltimes_belowT)) ' sec']; ['std = ' num2str(std(alltimes_belowT))]};
text(0.7,0.7,statinfo2,'Units','normalized','FontSize',14);
ylabel('probability')
xlabel('time (sec)')
title({'OFFSET duration';'Distribution of continuous time that LD < Threshold before rising above'})

h.Position =[1436 799 1361 368];
%% Pain correlations NOT FUNCTIONAL RN

figure

for f = 1:length(fnames)
    
    subplot(numf,1,f)
    scatter(nanmeanpwr{f},PWRmeta.pain)
    title([num2str(PWRmeta.ctrFq{f}) ' Hz:  ' PWRmeta.contacts{f}])
end

xlabel('power')
ylabel('pain')
