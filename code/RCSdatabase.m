function [RCSdatabase] = RCSdatabase(dirname,varargin)

% RCS Database

% This function loops through all session folders in the path to create a
% database of all RC+S metrics of interest

% INPUTS: directory pathname for all patient session files 
    % ** including AppLog.txt and EventLog.txt
    % **AppLog.txt: adaptive state changes 
    % **EventLog.txt: open loop group changes
    
% OUTPUTS: RCSdatabase.mat timetable with fields:

%    [{'time'}; {'rec'}; {'sessname'  };  {'duration'  }; ...
%     {'battery'   };{'TDfs'      };{'fft'};
%     {'power'     };{'stim'    };   {'stimName'  }; ...
%     {'stimparams'};  {'path'};  {'powerbands'}]; ...
%     {'adaptiveLD_mean'}; {'adaptiveLD_std'}; {'untsreamedGroupChanges'};

% function dependencies:
    % read_adaptive_txt_log (starr lab analysis repo) % by Ro'ee Gilron
    % makeDataBaseRCSdata (Chronic Pain RCS repo) % by Prasad Shirvalkar
%       Open Mind functions in makeDataBaseRCSData: % by Kristin Sellers
%       and Open Mind team
        %   	createDeviceSettingsTable
        %       createStimSettingsFromDeviceSettings
        %       deserializeJSON
        %       createStimSettingsTable
% other dependencies:
% https://github.com/JimHokanson/turtle_json
% in the a folder called "toolboxes" in the same directory as the processing scripts


% Ashlyn Schmitgen May2021
% For OpenMind

%% create loop through all text files for adaptive_read_log_txt.m for database
clc; clear;
warning("off", "all");

dirname = '/Users/ashlynschmitgen/Documents/RCS02_Current/RCSTxtDataBase'; 
filelist = dir(fullfile(dirname,'**/*.txt')); % all txt files contains within session files
filelist = filelist(~[filelist.isdir]);

AppLogData = []; % create empty tables
EventLogData = [];
% concatenates all App txt data and all Event txt data for the patient
for i = 1:numel(filelist)
    f = filelist(i);
    if endsWith(f.name,"AppLog.txt")
        [adaptiveLogTable, ~, ~, ~] = read_adaptive_txt_log(fullfile(f.folder, f.name));
        AppLogData = [AppLogData; adaptiveLogTable];
        fprintf("Done %s, %d/%d: %d\n", f.name, i, numel(filelist), size(adaptiveLogTable, 1));
    elseif endsWith(f.name,"EventLog.txt")
        [~, ~, groupChanges, ~] = read_adaptive_txt_log(fullfile(f.folder, f.name));
        EventLogData = [EventLogData; groupChanges];
        fprintf("Done %s, %d/%d: %d\n", f.name, i, numel(filelist), size(groupChanges, 1));
    end
end

fprintf("Done!\n");


%% format tables and eliminate duplicates from overlap

% make sure time is datetime
AppLogData.time = datetime(AppLogData.time);
EventLogData.time = datetime(EventLogData.time);

% sort all rows by date (
sorted_ALD = sortrows(AppLogData, 1);
sorted_ELD = sortrows(EventLogData, 1);

% remove all duplicate timestamps
[~, ALD_ind] = unique(sorted_ALD.time);
[~, ELD_ind] = unique(sorted_ELD.time);


unique_sorted_ALD = sorted_ALD(ALD_ind, :);
unique_sorted_ELD = sorted_ELD(ELD_ind, :);


unique_sorted_ALD = table2timetable(unique_sorted_ALD);
unique_sorted_ELD = table2timetable(unique_sorted_ELD);

unique_sorted_ELD.time.TimeZone = 'America/Los_Angeles'; % assign same time zone as ProcessRCS

%% concatenating json files with txt files

database_out = makeDataBaseRCSdata(dirname); % add AdaptiveData.Ld0_output

% clear empty sessions
loc = cellfun('isempty', database_out{:,'time'});
database_out(loc,:) = [];

% create new variable in database_out for group changes (in EventLog.txt)
% outside of streaming sessions
unstreamedGroupChanges = [{[]}];

% insert EventLog changes into the following session time
for row = 2:size(database_out, 1)
    prior_end_times = database_out{row-1, 'time'}{1} + database_out{row-1, 'duration'}{1};
    last_end_time = max(prior_end_times);
    
    curr_start_times = database_out{row, 'time'}{1};
    first_start_time = min(curr_start_times);
    
    TR = timerange(last_end_time, first_start_time);
    unstreamedGroupChanges = [unstreamedGroupChanges; {unique_sorted_ELD(TR, 'group')}];
end

% new column with group changes between sessions
database_out.unstreamedGroupChanges = unstreamedGroupChanges;

%% expanding all fields within each struct

expanded_timetable = [];

TD_chan1 = [];
TD_chan2 = [];
TD_chan3 = [];
TD_chan4 = [];

for row_idx = 1:size(database_out, 1)
    row = database_out(row_idx, :);
    if size(row.time{1}, 1) > 1  % duplicating entire row if there are multiple entries per session
        for database_row = 1:size(row.time{1}, 1)
            expanded_timetable = [expanded_timetable; database_out(row_idx, :)];
            for col_name = ["time", "duration", "TDfs"]
                expanded_timetable{end, col_name}{1} = expanded_timetable{end, col_name}{1}(database_row);
            end
            
            TD_chan1 = [TD_chan1; row.TDSettings{1, 'chan1'}{1}];
            TD_chan2 = [TD_chan2; row.TDSettings{1, 'chan2'}{1}];
            TD_chan3 = [TD_chan3; row.TDSettings{1, 'chan3'}{1}];
            TD_chan4 = [TD_chan4; row.TDSettings{1, 'chan4'}{1}];
        end
    elseif size(row.time{1}, 1) == 1 % print the single value  if only one entry per session
        expanded_timetable = [expanded_timetable; database_out(row_idx, :)];
        for col_name = ["time", "duration", "TDfs"]
            expanded_timetable{end, col_name}{1} = expanded_timetable{end, col_name}{1}(1);
        end
        
        TD_chan1 = [TD_chan1; row.TDSettings{1, 'chan1'}{1}];
        TD_chan2 = [TD_chan2; row.TDSettings{1, 'chan2'}{1}];
        TD_chan3 = [TD_chan3; row.TDSettings{1, 'chan3'}{1}];
        TD_chan4 = [TD_chan4; row.TDSettings{1, 'chan4'}{1}];
    else
        expanded_timetable = [expanded_timetable; database_out(row_idx, :)];
        
        TD_chan1 = [TD_chan1; row.TDSettings{1, 'chan1'}{1}];
        TD_chan2 = [TD_chan2; row.TDSettings{1, 'chan2'}{1}];
        TD_chan3 = [TD_chan3; row.TDSettings{1, 'chan3'}{1}];
        TD_chan4 = [TD_chan4; row.TDSettings{1, 'chan4'}{1}];
    end
end

% expand all variables for each row
expanded_timetable.time = transpose([expanded_timetable.time{:, 1}]);
expanded_timetable.duration = transpose([expanded_timetable.duration{:, 1}]);
expanded_timetable.TDfs = transpose([expanded_timetable.TDfs{:, 1}]);

expanded_timetable.TD_chan1 = TD_chan1;
expanded_timetable.TD_chan2 = TD_chan2;
expanded_timetable.TD_chan3 = TD_chan3;
expanded_timetable.TD_chan4 = TD_chan4;

expanded_timetable.TDSettings = [];

expanded_timetable = table2timetable(expanded_timetable);

expanded_timetable = movevars(expanded_timetable, {'TD_chan1', 'TD_chan2', 'TD_chan3', 'TD_chan4'}, 'After', 'TDfs');

RCSdatabase = expanded_timetable; % rename output for clarity

%% save

% Rename file to include patient ID
slashind = find((dirname=='/'),1,'last');
PTID = dirname(slashind+1:end);
%writetable(database_out,fullfile(dirname,[PTID 'database_summary.csv']))
save(fullfile(dirname,[PTID 'database_summary.mat']),'RCSdatabase')
fprintf('csv and mat of database saved as %s to %s \n',[PTID 'database_summary.mat'],dirname);

    
    
    