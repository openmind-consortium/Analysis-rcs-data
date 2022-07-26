function [RCSdatabase_out,varargout] = makeDataBaseRCSdata(dirname,PATIENTIDside,varargin)
% function database_out = makeDataBaseRCSdata(dirname)
%
%
% This function creates a database of rcs data
%
% INPUT:   DIRNAME should be the root folder of the Session Files (e.g. SCBS folder)
%               e.g. DIRNAME = '/Desktop/[PATIENTID]/'
%               e.g. DIRNAME = '/Volumes/Prasad_X5/RCS02/;
%
%
%           PATIENTIDside = should specify what the Patient ID name is, and
%           should be same as subfolder (e.g. 'RCS02R')
%
%           (OPTIONAL INPUT) 'ignoreold' will ignore old databases and
%           start fresh. Third input should be lowercase as written.
%
%
%
% OUTPUT:   RCSdatabase_out is a table with fields ordered in importance, which will
%            be saved as a mat file and csv to DIRNAME
%
%           (OPTIONAL)
%           SECOND OUTPUT could be provided to collect list of bad sessions
%           (e.g. those with no data in Jsons)
%
% %          Included fields include + more:
%     'rec',[],...
%     'time',[],...
%     'sessname',[],...
%     'duration',[],...
%     'battery',[],...
%     'TDfs',[],...
%     'fftbin',[],...
%     'fft_chan',[],...
%     'fft_interval',[],...
%     'stim',[],...
%     'stimName',[],...
%     'stimparams',[],...
%     'cycleOn',[],...
%     'cycleOff',[],...
%     'path',[],...
%     'powerbands',[],...
%     'adaptive_threshold',[],...
%     'adaptive_onset_dur',[],...
%     'adaptive_termination_dur',[],...
%     'adaptive_states',[],...
%     'adaptive_weights',[],...
%     'adaptive_pwrinputchan',[],...
%     'adaptive_updaterate',[]);
% %
% ***** NOTE THAT ONLY LD0 data is populated in the adaptive fields (not LD1)******
%
%
%  USING CELL DATA IN THE TABLE:
%       to concatenate all cell variables in the table (such as duration)
%       use:
%           alldurations =cat(1,database_out.duration{:})
%
%
%  **** This will check to see if there is an existing database, if so, it will
%  update that database table.
%  *****
%
%
%
% Depedencies:
% https://github.com/JimHokanson/turtle_json
% in the a folder called "toolboxes" in the same directory as the processing scripts
%
%
% Prasad Shirvalkar Sep 13,2021
%  updated july 2022, to remove duplicate sessions between aDBS And SCBS based on SessionID and
%  updated  fields to add fftchan and cycleOnSec, cycleOffsec



tic

%  Define the directories to search in (SCBS and aDBS)
scbsdir = fullfile(dirname,'/SummitData/SummitContinuousBilateralStreaming/', PATIENTIDside);
adbsdir = fullfile(dirname, '/SummitData/StarrLab/', PATIENTIDside);

dirsdata1 = findFilesBVQX(scbsdir,'Sess*',struct('dirs',1,'depth',1));
dirsdata2 =  findFilesBVQX(adbsdir,'Sess*',struct('dirs',1,'depth',1));

 
% Filter the dirsdata by Session # to remove duplicate sessions between SCBS and ADBS which
% sometimes occur  
session1 = string(regexp(string(dirsdata1),'Session.*','match'));
session2 = string(regexp(string(dirsdata2),'Session.*','match')); 
dup2 = contains(session2,session1);
dirsdata2(dup2) = [];
% combine to form dirsdata to use
dirsdata = [dirsdata1;dirsdata2];

dbout = struct('rec',[],...
    'time',[],...
    'sessname',[],...
    'duration',[],...
    'battery',[],...
    'TDfs',[],...
    'fftbin',[],...
    'fft_chan',[],...
    'fft_interval',[],...
    'stim',[],...
    'stimName',[],...
    'stimparams',[],...
    'cycleOn',[],...
    'cycleOff',[],...
    'path',[],...
    'powerbands',[],...
    'adaptive_threshold',[],...
    'adaptive_onset_dur',[],...
    'adaptive_termination_dur',[],...
    'adaptive_states',[],...
    'adaptive_weights',[],...
    'adaptive_pwrinputchan',[],...
    'adaptive_updaterate',[]);

%%
% insert section here to load old database, and just add rows to it if
% needed, so as not to replicate whole thing.
% Can be turned off with third input 'ignoreold'
[~,PtIDside]=fileparts(scbsdir);
outputFileName = fullfile(dirname,[PtIDside '_database.mat']);


if isfile(outputFileName) && nargin<3
    disp(['Loading previously saved database for ' PtIDside]);
    D = load(outputFileName,'RCSdatabase_out','badsessions');
    old_database = D.RCSdatabase_out;
    old_badsessions = D.badsessions;
    oldsess = D.RCSdatabase_out.sessname;
    oldbadsess = D.badsessions.sessname;
    olddirs = contains(dirsdata,oldsess) | contains(dirsdata,oldbadsess) ;
    dirsdata(olddirs)= [];

    if isempty(dirsdata)
        fprintf("No new data to add!  Existing database returned \n")
        RCSdatabase_out = old_database;
        varargout{1}= old_badsessions;
        return
    end

else
    disp(['Compiling database from scratch... ' PtIDside])
    old_database= [];
end





%%
for d = 500:700
%     length(dirsdata)
    diruse = findFilesBVQX(dirsdata{d},'Device*',struct('dirs',1,'depth',1));

%     if nargin==2 &&  d > numel(dirsdata1)
%         dbout(d).aDBS = 1;
%     else
%         dbout(d).aDBS= 0;
%     end

    fprintf('Reading folder %d of %d  \n',d,length(dirsdata))
    if isempty(diruse) % no data exists inside

        dbout(d).time = [];
        [~,fn] = fileparts(dirsdata{d});
        dbout(d).sessname = fn;
        disp('no data.. moving on');

    else % data may exist, check for time domain data
        clear devicepath settingsfile
        tdfile = findFilesBVQX(dirsdata{d},'EventLog.json');
        devfile = findFilesBVQX(dirsdata{d},'DeviceSettings.json');
        if ~isempty(tdfile) && ~isempty(devfile)  % time data file doesn't exist

            %
            [~,fn] = fileparts(dirsdata{d});
            dbout(d).sessname = fn;
            [path,~,~] = fileparts(tdfile{1});
            dbout(d).path = path;


            % extract times and .mat status
            % load device settings file
            try
                settingsfile = findFilesBVQX(dirsdata{d},'DeviceSettings.json');
                [devicepath,~,~]= fileparts(settingsfile{1}); 
 
                [timeDomainSettings, powerSettings, fftSettings, metaData] = createDeviceSettingsTable(devicepath);


                %IF there is time/ power domain data
                if ~isempty(timeDomainSettings) && ~isempty(powerSettings)


                    %   Get recording start time/ duration
                    startTime = timeDomainSettings.timeStart;
                    timeFormat = sprintf('%+03.0f:00',metaData.UTCoffset);
                    startTimeDt = datetime(startTime/1000,'ConvertFrom','posixTime','TimeZone',timeFormat,'Format','dd-MMM-yyyy HH:mm:ss.SSS');
                    dbout(d).time = startTimeDt(1); %take the first value of all subsessions
                    dbout(d).duration = sum(duration(seconds(timeDomainSettings.duration/1000),'Format','hh:mm:ss.SSS')); %take the sum of all durations




                    % Get time domain sensing info
                    dbout(d).TDfs = timeDomainSettings.samplingRate(1);
                    dbout(d).chan0= timeDomainSettings.chan1{1};
                    dbout(d).chan1= timeDomainSettings.chan2{1};
                    dbout(d).chan2= timeDomainSettings.chan3{1};
                    dbout(d).chan3= timeDomainSettings.chan4{1};
                    dbout(d).battery = metaData.batteryLevelPercent;



                    %  Get FFT length info
                    if ~isnan(fftSettings.recNum)
                        dbout(d).fftbin = fftSettings.fftConfig.size;
                        dbout(d).fft_chan = metaData.fftstreamChan;
                        dbout(d).fft_interval = fftSettings.fftConfig.interval;
                    end


                    % Get powerbands and whether recorded info

                    if ~isnan(powerSettings.recNum)
             
                        dbout(d).powerbands = powerSettings.powerBands.powerBandsInHz;
                    end



                end
            catch
            end







            try

                % Get Adaptive settings info
                [DetectorSettings,~,AdaptiveEmbeddedRuns_StimSettings] = createAdaptiveSettingsfromDeviceSettings(devicepath);

                % Look for adaptive Embedded Run
                if ~isempty(AdaptiveEmbeddedRuns_StimSettings)
                    dbout(d).adaptive_states=AdaptiveEmbeddedRuns_StimSettings.states(end);
                end

                dbout(d).adaptive_onset_dur = DetectorSettings.Ld0.onsetDuration;
                dbout(d).adaptive_termination_dur = DetectorSettings.Ld0.terminationDuration;
                dbout(d).adaptive_weights{1}(1:4) = cat(1,DetectorSettings.Ld0.features.weightVector);
                dbout(d).adaptive_pwrinputchan = DetectorSettings.Ld0.detectionInputs_BinaryCode  ;
                dbout(d).adaptive_threshold = DetectorSettings.Ld0.biasTerm;
                dbout(d).adaptive_updaterate = DetectorSettings.Ld0.updateRate;
            catch
            end



            try

                % Get stim settings
                [stimSettingsOut, stimMetaData] = createStimSettingsFromDeviceSettings(devicepath);
                dbout(d).stim = stimSettingsOut.therapyStatus;

            catch
            end



            %Get stim information if STIM is on
            if sum(dbout(d).stim)>0

                stimfile =  findFilesBVQX(dirsdata{d},'StimLog.json');
                [stimpath,~,~]= fileparts(stimfile{1});
%                 Need to extract cycle on / off time from below
                [stimLogSettings] = createStimSettingsTable(stimpath,stimMetaData);

                try
                    dbout(d).stim = stimLogSettings.activeGroup(1);
                    dbout(d).stimparams = stimLogSettings.stimParams_prog1;
                    stimnamegroup={'A','B','C','D'; '1' , '5', '9','13'};
                    [~,j]= find(contains(stimnamegroup,stimLogSettings.activeGroup));
                    stimname =  metaData.stimProgramNames(str2double(stimnamegroup{2,j(1)}));
                    dbout(d).stimName =  stimname{1};
                    dbout(d).cycleOn = stimSettingsOut.cycleOnSec;
                    dbout(d).cycleOff = stimSettingsOut.cycleOffSec;
                catch
                    disp(' . . . STIM is on, but failed to extract all stim settings from this file . . . ')
                end


            end

            % load event file - not in use for now (PS)
            %             eventData = createEventLogTable(tdfile{1});
            %             dbout(d).eventData = eventData;


            % does mat file exist? DEPRECATED
%             matfile = findFilesBVQX(dirsdata{d},'combinedDataTable.mat');
% 
%             if isempty(matfile) % no matlab data loaded
%                 dbout(d).matExist = false;
%                 %                 dbout(d).fnm = [];
%             else
%                 dbout(d).matExist = true;
%                 %                 dbout(d).fnm = matfile{1};
%             end
        end
    end
end

database_out = struct2table(dbout,'AsArray',true);
% delete all rows with empty session names ( WHY DOES THIS OCCUR?)
database_out = database_out(cellfun(@(x) ~isempty(x),database_out.sessname),:);
sorted_database = sortrows(database_out,3); %sorting by session name
sorted_database.rec = (1:size(sorted_database,1))';

%% clear empty session rows and assign to new variable 'badsessions'
if iscell(sorted_database.time)
    loc = cellfun('isempty', sorted_database{:,'time'});
else
    loc= isempty(sorted_database.time);
end

badsessions = sorted_database(loc,:);
sorted_database(loc,:) = [];

%% expanding all fields within each struct  - DEPRECATED
% %  This is used to list out all subsessions within a session in case there are different stimulation
% %  conditions / settings associated with the subsessions 
% 
% 
% expanded_database = [];
% 
% for rowidx = 1:size(sorted_database, 1)
%     tmp_row = sorted_database(rowidx,:);  %tmp_row is the row with multiple entries
%     if size(tmp_row.time{1}, 1) > 1  % duplicating entire row if there are multiple entries per session
%         for new_row = 1:size(tmp_row.time{1}, 1)
%             expanded_database = [expanded_database; tmp_row];
%             for col_name = ["time", "duration", "TDfs"]
%                 expanded_database{end, col_name}{1} = expanded_database{end, col_name}{1}(new_row);
%             end
% 
% 
% 
% 
%             %make the first subsession an integer (like 2), and  all subsessions
%             %decimals like  2.01, 2.02, etc.
%             if new_row ==1
%                 expanded_database.rec(end) = tmp_row.rec;
%             else
%                 expanded_database.rec(end) = tmp_row.rec + ((new_row-1)/100);
%             end
% 
%         end
%     else  % print the single value  if only one entry per session
% 
%         expanded_database = [expanded_database; tmp_row];
%         for col_name = ["time", "duration", "TDfs"]
%             expanded_database{end, col_name}(1) = expanded_database{end, col_name}(1);
%         end
%     end
% end
% 
% % expand all variables for each row and make 'Disabled' values in TDfs to NaN
% idx_disabled=strcmp(expanded_database.TDfs,'Disabled');
% expanded_database.TDfs(idx_disabled)={nan};
% 
% idx_emptyfft = cellfun(@isempty, expanded_database.fft);
% expanded_database.fft(idx_emptyfft)={nan};
% 
% %  convert cells to string or double to remove cell structure
% cellvars = {'time', 'duration', 'TDfs','battery','fft'};
% for n = 1:numel(cellvars)
% 
%     if n >= 4
%         expanded_database.(cellvars{n}) = cell2mat(expanded_database.(cellvars{n}));
%     else
%         expanded_database.(cellvars{n}) =[expanded_database.(cellvars{n}){:}]';
%     end
% 
% end
% 
% expanded_database = movevars(expanded_database, {'TDchan0', 'TDchan1', 'TDchan2', 'TDchan3'}, 'After', 'TDfs');
% RCSdatabase_out = table2timetable(expanded_database); % rename output for clarity
 
%% CLEAN UP THE VARIABLES BY GROUPING THEM showing most important ones visually


%  convert cells to string or double to remove cell structure
cellvars = {'time', 'duration','TDfs','battery'};
% ,'fft_chan','fft_interval'};
for n = 1:numel(cellvars)

    if n >= 4
        sorted_database.(cellvars{n}) = cell2mat(sorted_database.(cellvars{n}));
    else
        sorted_database.(cellvars{n}) =[sorted_database.(cellvars{n}){:}]';
    end

end

sorted_database = movevars(sorted_database, {'chan0', 'chan1', 'chan2', 'chan3'}, 'After', 'TDfs');
RCSdatabase_out = table2timetable(sorted_database); % rename output for clarity
% RCSdatabase_out = mergevars(RCSdatabase_out,
% {'fftFs','fft_chan','fft_interval'},'NewVariableName','fft','MergeAsTable',true 

% Reorder the columns for usability
RCSdatabase_out = RCSdatabase_out(:,[1:3,13:17,4:12,19:26,18]);

%% COMBINE WITH OLD DATABASE
% IF the old database existed, recombine with new database and sort it
% but first fix cell/ mat class issues

if ~isempty(old_database)
    disp('combining with old database...');

    %make cells to mat for some fields
%     if iscell(RCSdatabase_out.matExist)
%         % format some columns so they are not cells
%         RCSdatabase_out.matExist = cell2mat(RCSdatabase_out.matExist);
%         badsessions.matExist = cell2mat(badsessions.matExist);
%     end

%     if iscell(old_database.matExist)
%         old_database.matExist = cell2mat(old_database.matExist);
%         old_badsessions.matExist = cell2mat(old_badsessions.matExist);
%     end


    if iscell(old_database.TDfs)
        idx_disabled=strcmp(old_database.TDfs,'Disabled');
        old_database.TDfs(idx_disabled)={nan};


        old_database.TDfs = cell2mat(old_database.TDfs);

    end


    if isa(RCSdatabase_out.adaptive_onset_dur,'double')
        RCSdatabase_out.adaptive_onset_dur =  num2cell(RCSdatabase_out.adaptive_onset_dur);
        RCSdatabase_out.adaptive_termination_dur =  num2cell(RCSdatabase_out.adaptive_termination_dur);
        RCSdatabase_out.adaptive_updaterate =  num2cell(RCSdatabase_out.adaptive_updaterate);


        badsessions.adaptive_onset_dur =  num2cell(badsessions.adaptive_onset_dur);
        badsessions.adaptive_termination_dur =  num2cell(badsessions.adaptive_termination_dur);
        badsessions.adaptive_updaterate =  num2cell(badsessions.adaptive_updaterate);


    end

        idx_disabled = strcmp(RCSdatabase_out.TDfs,'Disabled');
        RCSdatabase_out.TDfs(idx_disabled) = {nan};
RCSdatabase_out.TDfs = cell2mat(RCSdatabase_out.TDfs);


    %     COMBINE HERE
    RCSdatabase_out.rec = RCSdatabase_out.rec + old_database.rec(end);

    new_database_out = [old_database;RCSdatabase_out];

    if ~isempty(badsessions)
        badsessions = [old_badsessions;badsessions];
    else
        badsessions = old_badsessions;
    end

    clear RCSdatabase_out
    RCSdatabase_out = new_database_out;  %already a timetable

end




% ======================================
% OUTPUTS!


if nargout == 2
    varargout{1} = badsessions;
end
%
eval(sprintf('%s = %s',[PtIDside '_database'],'RCSdatabase_out')); 
% Rename file to include patient ID
writetimetable(RCSdatabase_out,fullfile(dirname,[PtIDside '_database.csv']))
save(fullfile(dirname,[PtIDside '_database.mat']),[PtIDside '_database'],'badsessions')
fprintf('csv and mat of database saved as %s to %s \n',[PtIDside '_database.mat'],dirname);


end