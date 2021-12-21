% This will  preprocess RC+S data using the new deserialization pipeline
% This will create combined MAT files for all recording sessions and create
% a database index of all files 
% 
% Also will analyze TEXTLOG files which show group changes / adaptive state
% changes in the ambulatory settings
% 
% Finally, it will import redcap Pain scores to use for analysis
%
% Seems to be working on MATLAB 2020b (previously we thought had to use
% 2019a or earlier)
%
% Prasad Shirvalkar Sep 13, 2021

clear
clc

PATIENTIDside =  'RCS04L'
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

%% compile text logs of all Adaptive/ Stim changes
[textlog] = RCS_logs(rootdir,PATIENTIDside);


%%  LOAD Database and Textlogs
load(fullfile(patientrootdir,[PATIENTIDside '_database.mat']))
load(fullfile(patientrootdir,[PATIENTIDside '_textlogs.mat']))
%% Import Painscores
% painscores = RCS_redcap_painscores();
pain.VAS = painscores.(PATIENTIDside(1:5)).painVAS;
pain.NRS = painscores.(PATIENTIDside(1:5)).mayoNRS;
pain.time = painscores.(PATIENTIDside(1:5)).time;
pain.time.TimeZone = 'America/Los_Angeles';

%% now search for when  program D was activated and just before changing to D in textlog.groupchange, what were the group D settings from RCSdatabase_out?

% get time stamps for then, and switch to next program. then plot adaptive
% stim events between those  times
textlog.app.time.TimeZone = 'America/Los_Angeles';
close all
clear adbs

groupD_idx = strfind(cell2mat(textlog.groupchange.group)','D');

 % Here fix the rows where group D appears consecutively, because that is
 % not a true group change (but  make sure it's not a new group D with
 % different settings...) (NOT FINISHED)
 
 
 
starttimes  = textlog.groupchange.time(groupD_idx);
endtimes = textlog.groupchange.time(groupD_idx+1);
starttimes.TimeZone = 'America/Los_Angeles';
endtimes.TimeZone = 'America/Los_Angeles';


for d = 1:numel(groupD_idx)
    adbs(d).groupDstarttime = starttimes(d);
    adbs(d).groupDendtime = endtimes(d);
    adbs(d).duration = duration(adbs(d).groupDendtime - adbs(d).groupDstarttime);
    
    %collect the state changes between groupD start and the next program
    %start
    adbsIDX{d}= textlog.app.time >= starttimes(d) & textlog.app.time < endtimes(d);
    
    %     Get stim params AND adaptive params associated with that groupD from
    %     RCSdatabase_out
    sessionIDX = find(RCSdatabase_out.time < adbs(d).groupDstarttime,1,'last');
    
    adbs(d).stimparams = RCSdatabase_out.stimparams(sessionIDX);
    % collect the sense contacts for all 4 channels using regexp
    pat  = '^(+)\d*-\d*';
    c0 = regexp(RCSdatabase_out.TDchan0{sessionIDX},pat,'match');
    c1 = regexp(RCSdatabase_out.TDchan1{sessionIDX},pat,'match');
    c2 = regexp(RCSdatabase_out.TDchan2{sessionIDX},pat,'match');
    c3 = regexp(RCSdatabase_out.TDchan3{sessionIDX},pat,'match');
    contactlist = [c0;c1;c2;c3];
    adbs(d).sensecontacts = contactlist;
    adbs(d).updaterate = RCSdatabase_out.adaptive_updaterate(sessionIDX);
    adbs(d).statedef = RCSdatabase_out.adaptive_states(sessionIDX);
    adbs(d).thresh = RCSdatabase_out.adaptive_threshold(sessionIDX);
    adbs(d).onset = RCSdatabase_out.adaptive_onset_dur(sessionIDX);
    adbs(d).termination = RCSdatabase_out.adaptive_termination_dur(sessionIDX);
    adbs(d).weight = RCSdatabase_out.adaptive_weights(sessionIDX);
    adbs(d).pwr = RCSdatabase_out.powerbands(sessionIDX);
    adbs(d).inputs = RCSdatabase_out.adaptive_pwrinputchan{sessionIDX};
    
    
    if sum(adbsIDX{d})>0
        disp(sum(adbsIDX{d}));
        % Then get state changes etc corresponding to group D use, (if embedded was
        % turned on as per sessionDatabase) ** Use textlog.app to get state
        % changes, and you can find the current associated with state using
        % database_out.states
        
        adbs(d).statechanges = textlog.app(find(adbsIDX{d}),:);
        
    end
end




adbs = struct2table(adbs);


%% COLLECT The state changes for durations > 24 hours, and Plot the features below

mindur = hours(24);
mindurIDX = adbs.duration > mindur & cellfun(@(x) ~isempty(x),adbs.statedef);
mindurSub = find(mindurIDX);
numruns = sum(mindurIDX);
subs = numSubplots(numruns);

clear state*
figure
for x = 1:numruns
    %     Plot state changes
    
    subplot(subs(1), subs(2), x)
    if ~isempty(adbs.statechanges{mindurSub(x)})
        
        %get the current that corresponds to each state
        stateinfo = adbs.statedef{mindurSub(x)};
        totaldur = seconds(adbs.duration(mindurSub(x)));
        
        % list amps for states 0 ,1,2 and then find the amount of time in each
        % state
        statemAdef(x,1:3) = [stateinfo.state0_AmpInMilliamps(1), stateinfo.state1_AmpInMilliamps(1), stateinfo.state2_AmpInMilliamps(1)];
        
        clear statedur statenum statemA
        %     find the amount of time in each state and get the current, calculate % time on and TEED
        for s = 1:size(adbs.statechanges{mindurSub(x)},1)
            
            %         what about groupDstart and end times?
            if s < size(adbs.statechanges{mindurSub(x)},1)
                statedur(s) = seconds(adbs.statechanges{mindurSub(x)}.time(s+1)- adbs.statechanges{mindurSub(x)}.time(s));
                statenum(s) = adbs.statechanges{mindurSub(x)}.newstate(s);
                
                
            else %if last state change value, compare to endtime
                statedur(s) = seconds(adbs.groupDendtime(mindurSub(x)) - adbs.statechanges{mindurSub(x)}.time(s));
                statenum(s) = adbs.statechanges{mindurSub(x)}.newstate(s);
                statemA(s) = statemAdef(x,statenum(s)+1); %add 1 to statenum because it sta rts at 0
                
            end
            
            
        end
        
        
        
        
        %             now calculate the % time in each state, % time on, TEED and
        %             store with thresholds and avg duration of state changes etc
        %         ** DOES NOT TAKE INTO ACCOUNT THE RAMPING TIME ON/ OFF
        uqstates = unique(statenum);
        
        for u = 1: numel(uqstates)
            stateidx = (statenum == uqstates(u));
                            STATS(x).state(u) = uqstates(u);
                            STATS(x).percenttime(u) = sum(statedur(stateidx)) / totaldur;
            
            
            if ~isempty(adbs.stimparams{mindurSub(x)})
                q = statemAdef(x,uqstates(u)+1); %add 1 to uqstates because states start at 0
                pw = regexp(adbs.stimparams{mindurSub(x)}{1},'(\w\d*)us','tokens');
                pw = str2double(pw{1}{1});
                fq = adbs.statechanges{mindurSub(x)}.rateHz(1);
                
                %             TEED =  q^2 * pw * fq *  1s (or q= V/R)
                             STATS(x).teed(u) = (q^2 * pw * fq  * sum(statedur(stateidx)) ) / totaldur; %dividing by totaldur normalizes by total time
                
            end
            
        end
                             STATS(x).percenttimeON = sum(STATS(x).percenttime(statemAdef(x,1:numel(STATS(x).percenttime))>0));
                
                
                              
                              
                              
        % %        Plot the state changes, for long runs of group D
        
        yyaxis left
        stairs(adbs.statechanges{mindurSub(x)}.time,adbs.statechanges{mindurSub(x)}.newstate);
        ylabel('state')
        ylim1 = get(gca,'YLim');
        ylim([ylim1(1)-0.1 ylim1(2)+0.1])

        
        yyaxis right
        painscore_idx =  pain.time >=  adbs.statechanges{mindurSub(x)}.time(1) & pain.time <= adbs.statechanges{mindurSub(x)}.time(end);    
        plot(pain.time(painscore_idx),pain.NRS(painscore_idx));
        ylabel('pain NRS')
        ylim([0 10])
        
%         title([adbs.stimparams{mindurSub(x)} ' TEED= ' num2str(sum(STATS(x).teed))])
        title([adbs.stimparams{mindurSub(x)} ' %time on= ' num2str(STATS(x).percenttimeON)])
        
        
    end %If ~isempty statechanges
    
end %for x = 1:numruns

disp('done')

figure
histogram([STATS.percenttimeON],10)
title('Percent time on across all CL sessions')
ylabel('counts')
xlabel('% time ON stimuation with CL')
%% MAKE ANOTHER DATABASE WITH TIMESTAMPS OF UNIQUE a) sensing inputs b) stim
% params 3) thresholds 4) onset/offset times


% Plot
% 5. pain scores reported during each segment (group D but also other
% groups/ sessions)







%% LOAD ALL DATA FROM ALL SESSIONS - Process and load all data - skip if mat already exists

dirsdata = findFilesBVQX(scbsdir,'Sess*',struct('dirs',1,'depth',1));

% find out if a mat file was already created in this folder
% if so, just an update is needed and will not recreate mat file
dbout = [];
for d = 1:numel(dirsdata)
    diruse = findFilesBVQX(dirsdata{d},'Device*',struct('dirs',1,'depth',1));
    
    fprintf('\n \n Reading Session Folder %d of %d  \n',d,length(dirsdata))
    if isempty(diruse) % no data exists inside
        fprintf('No data...\n');
        %
        %     elseif exist(fullfile(diruse{1},'combinedDataTable.mat')) == 2
        %         fprintf('combinedDataTable mat file already exists... skipping \n');
        
    else % process the data
        try
            [unifiedDerivedTimes,...
                timeDomainData, timeDomainData_onlyTimeVariables, timeDomain_timeVariableNames,...
                AccelData, AccelData_onlyTimeVariables, Accel_timeVariableNames,...
                PowerData, PowerData_onlyTimeVariables, Power_timeVariableNames,...
                FFTData, FFTData_onlyTimeVariables, FFT_timeVariableNames,...
                AdaptiveData, AdaptiveData_onlyTimeVariables, Adaptive_timeVariableNames,...
                timeDomainSettings, powerSettings, fftSettings, eventLogTable,...
                metaData, stimSettingsOut, stimMetaData, stimLogSettings,...
                DetectorSettings, AdaptiveStimSettings, AdaptiveEmbeddedRuns_StimSettings,...
                versionInfo] = ProcessRCS(diruse{1});
        catch
        end
    end
end

disp('DONE!')
%%  Get files from DB and find where group D is active during recording,
% load raw data and concatenate and plot


load(fullfile(scbsdir,[PATIENTID 'database_summary.mat']))
D = database_out;

% find the rec # to load
% recs_to_load = (381:392);
recs_to_load= 401




for r = recs_to_load
    
    DT = load(fullfile(database_out.path{r},'combinedDataTable.mat'))
    
    
end

%%  plot power bands

% get rid of nans
% ~isnan(DT.combinedDataTable.Power_Band1)

plot(DT.combinedDataTable.localTime(~isnan(DT.combinedDataTable.Power_Band1)), DT.combinedDataTable.Power_Band1(~isnan(DT.combinedDataTable.Power_Band1)))


%%   Kurtosis find periods of stim

close all
winsize = 3000
noverlap = 0.1
d = data.key1;

k = movwin(d,winsize,noverlap,@kurtosis);
plot(linspace(1,numel(k),numel(d)),d)
hold on
plot(k)
%find periods of stimulation
[p,l]= findpeaks(k,'threshold',0.5,'MinPeakProminence',3)