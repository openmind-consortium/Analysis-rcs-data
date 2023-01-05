function [textlog] = RCS_logs(rootdir,PATIENTIDside)

% RCS Database

% This function loops through all session folders in the path to create a
% database of all RC+S metrics of interest including processing of the
% adaptive text logs

% INPUTS:
% 1. ROOTDIR is the local root directory pathname for all patient session files
%       ! ! Make sure patient name is NOT included (e.g RCS02 would be a subfolder in the input folder)
%        This should look something like 'C:/Desktop/'
%            ** including:
%            ** AppLog.txt: adaptive state changes
%            ** EventLog.txt: open loop group changes
%
% 2. PATIENTIDside (this should indicate the side (L/R) of which device you are
%       analyzing (i.e. RCS02R) - EXCEPT for CPRCS01, there is no letter after
%       the name

% OUTPUT:
% 1. textlog.mat timetable with fields:

%    [{'time'}; {'rec'}; {'sessname'  };  {'duration'  }; ...
%     {'battery'   };{'TDfs'      };{'fft'};
%     {'power'     };{'stim'    };   {'stimName'  }; ...
%     {'stimparams'};  {'path'};  {'powerbands'}]; ...
%     {'adaptiveLD_mean'}; {'adaptiveLD_std'}; {'untsreamedGroupChanges'};


% function dependencies:
%    read_adaptive_txt_log (starr lab analysis repo) % by Ro'ee Gilron
%    makeDataBaseRCSdata (Chronic Pain RCS repo)x % by Prasad Shirvalkar
%       Open Mind functions in makeDataBaseRCSData: % by Kristin Sellers
%       and Open Mind team
%   	createDeviceSettingsTable
%       createStimSettingsFromDeviceSettings
%       deserializeJSON
%       createStimSettingsTable
% other dependencies:
% https://github.com/JimHokanson/turtle_json
% in the a folder called "toolboxes" in the same directory as the processing scripts


%%% Updates %%%
%   P Shirvalkar July 28 2021
%   -  Updated redundant calculations and included recharge sessions, group
%      changes and detector changes to output
%   - created new plotting tools for this analysis (as part of RCS_CL which
%   calls this function)
% 
%  12/2022 - combines old textlogs
%%%


%% create loop through all text files for adaptive_read_log_txt.m for database

warning("off", "all");
tic

% exception for CPRCS01
if ~ (contains(PATIENTIDside,'CPRCS01'))
    PATIENTID = PATIENTIDside(1:end-1); %remove the L or R letter
else
    PATIENTID = PATIENTIDside;
end



fprintf('Compiling Textlogs for %s \n', PATIENTIDside)
scbsdir = fullfile(rootdir,PATIENTID,'/SummitData/SummitContinuousBilateralStreaming/', PATIENTIDside);

filelist= dir(fullfile(scbsdir,'**/*.txt')); % all txt files contains within session files
%adbs does not contain txt files (but for RCS02, some text files are outside RCS02R from 2021)


% remove the files that start with ._  (some icloud issue of duplicate files to ignore)
badfiles = arrayfun(@(x) contains(x.name,{'._','error'}),filelist);
filelist(badfiles)=[];
filelist = filelist(~[filelist.isdir]);

% CHECK IF PRIOR TEXTLOG EXISTS.  IF SO, Load and combine with filelist to avoid reprocessing old files
fn = [PATIENTIDside '_textlogs.mat'];
if exist(fullfile(rootdir,PATIENTID,fn),'file')
    fprintf('Prior textlog found, combining with %s \n',fn);
    OLD = load(fullfile(rootdir,PATIENTID,fn),'textlog');
    [~,newfilesidx]= setdiff({filelist.name},{OLD.textlog.filelist.name});
    fprintf('%d new textlog files found... \n',length(newfilesidx));
    filelistnew = filelist(newfilesidx);
    filelist = filelistnew;
end



AppLogData = table(); % create empty tables
GroupchangeData = table();
RechargeData=table();
AdaptiveDetect=table();

parfor i = 1:numel(filelist)
    f = filelist(i);
    if endsWith(f.name,"AppLog.txt")
        [adaptiveLogTable, ~, ~,adaptiveDetectionEvents] = read_adaptive_txt_log(fullfile(f.folder, f.name));
        AppLogData = [AppLogData; adaptiveLogTable];
        AdaptiveDetect = [AdaptiveDetect; adaptiveDetectionEvents];
        fprintf("Done %s, %d of %d: %d detection changes \n", f.name, i, numel(filelist), size(adaptiveLogTable, 1));

    elseif endsWith(f.name,"EventLog.txt")
        [~, rechargeSessions, groupChanges,~] = read_adaptive_txt_log(fullfile(f.folder, f.name));
        GroupchangeData = [GroupchangeData; groupChanges];
        RechargeData =[RechargeData; rechargeSessions];
        fprintf("Done %s, %d of %d: %d groupchanges \n", f.name, i, numel(filelist), size(groupChanges, 1));
    end
end

fprintf("Done!\n");
toc


%% format Text Log tables and eliminate duplicates from overlap
if ~isempty(filelist)
    % make sure time is datetime
    AppLogData.time = datetime(AppLogData.time);
    GroupchangeData.time = datetime(GroupchangeData.time);
    AdaptiveDetect.time = datetime(AdaptiveDetect.time);
    RechargeData.time = datetime(RechargeData.time);

    % sort all rows by date
    sorted_ALD = sortrows(AppLogData, 1);
    sorted_ELD = sortrows(GroupchangeData, 1);
    sorted_AD = sortrows(AdaptiveDetect, 1);
    sorted_RD = sortrows(RechargeData, 1);

    % remove all duplicate timestamps
    [~, ALD_ind] = unique(sorted_ALD.time);
    [~, ELD_ind] = unique(sorted_ELD.time);
    [~, AD_ind] = unique(sorted_AD.time);  %comment out if detections may occur at below 1sec timescale
    [~, RD_ind] = unique(sorted_RD.time);

    unique_sorted_ALD = table2timetable(sorted_ALD(ALD_ind, :));
    unique_sorted_ELD = table2timetable(sorted_ELD(ELD_ind, :));
    unique_sorted_AD =  table2timetable(sorted_AD(AD_ind, :));
    unique_sorted_RD = table2timetable(sorted_RD(RD_ind, :));

    if exist('OLD','var')
    % if OLD textlog exists, combine with new one
        textlog.app = [OLD.textlog.app; unique_sorted_ALD];
        textlog.groupchange = [OLD.textlog.groupchange; unique_sorted_ELD];
        textlog.adaptive = [OLD.textlog.adaptive; unique_sorted_AD];
        textlog.recharge = [OLD.textlog.recharge; unique_sorted_RD];
        textlog.filelist  = [OLD.textlog.filelist; filelist];

    else
        % rename final variables for Text logs
        textlog.app = unique_sorted_ALD;
        textlog.groupchange = unique_sorted_ELD;
        textlog.groupchange.time.TimeZone = 'America/Los_Angeles'; % assign same time zone as ProcessRCS
        textlog.adaptive = unique_sorted_AD;
        textlog.recharge = unique_sorted_RD;
        textlog.filelist  = filelist; % use this in the future to avoid running all old files again
    end

    %% SAVE The Text Log structure
    fn = [PATIENTIDside '_textlogs.mat'];
    save(fullfile(rootdir,PATIENTID,fn),'textlog','-v7.3','-nocompression')
    fprintf('mat of Text Logs (Log structure) saved to \n %s \n',fullfile(rootdir,PATIENTID,fn));

elseif exist('OLD','var')
    textlog  = OLD.textlog;
else
    textlog = [];
    fprintf('No textlogs found  :( .... \n')
end

