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
%           start fresh
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
%          Included fields are:
%     'rec',[],...
%     'time',[],...
%     'sessname',[],...
%     'duration',[],...
%     'battery',[],...
%     'TDfs',[],...
%     'fft',[],...
%     'power',[],...
%     'stim',[],...
%     'stimName',[],...
%     'stimparams',[],...
%     'matExist',[],...
%     'path',[],...
%     'powerbands',[],...
%     'aDBS',[],...
%     'adaptive_threshold',[],...
%     'adaptive_onset_dur',[],...
%     'adaptive_termination_dur',[],...
%     'adaptive_states',[],...
%     'adaptive_weights',[],...
%     'adaptive_updaterate',[],...
%     'adaptive_pwrinputchan',[]);
% %
% ***** NOTE THAT ONLY LD0 data is populated in the adaptive fields ******
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



tic

%  Define the directories to search in (SCBS and aDBS)
scbsdir = fullfile(dirname,'/SummitData/SummitContinuousBilateralStreaming/', PATIENTIDside);
adbsdir = fullfile(dirname, '/SummitData/StarrLab/', PATIENTIDside);

dirsdata1 = findFilesBVQX(scbsdir,'Sess*',struct('dirs',1,'depth',1));
dirsdata2 =  findFilesBVQX(adbsdir,'Sess*',struct('dirs',1,'depth',1));
dirsdata = [dirsdata1;dirsdata2];


dbout = struct('rec',[],...
    'time',[],...
    'sessname',[],...
    'duration',[],...
    'battery',[],...
    'TDfs',[],...
    'fft',[],...
    'power',[],...
    'stim',[],...
    'stimName',[],...
    'stimparams',[],...
    'matExist',[],...
    'path',[],...
    'powerbands',[],...
    'aDBS',[],...
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
    disp('Loading previously saved database');
    D = load(outputFileName,'RCSdatabase_out','badsessions');
    old_database = D.RCSdatabase_out;
    oldsess = D.RCSdatabase_out.sessname;
    oldbadsess = D.badsessions.sessname;
    olddirs = contains(dirsdata,oldsess) | contains(dirsdata,oldbadsess) ;
    dirsdata(olddirs)= [];

    if isempty(dirsdata)
        fprintf("No new data to add!  Existing database returned \n")
        RCSdatabase_out = old_database;
        varargout{1}= oldbadsess;
        return
    end

else
    old_database= [];
end





%%
for d = 1:length(dirsdata)
    diruse = findFilesBVQX(dirsdata{d},'Device*',struct('dirs',1,'depth',1));
    
    if nargin==2 &&  d > numel(dirsdata1)
        dbout(d).aDBS = 1;
    else
        dbout(d).aDBS= 0;
    end
    
    fprintf('Reading folder %d of %d  \n',d,length(dirsdata))
    if isempty(diruse) % no data exists inside
        %         dbout(d).rec = d;
        dbout(d).time = [];
        dbout(d).matExist  = 0;
        [~,fn] = fileparts(dirsdata{d});
        dbout(d).sessname = fn;
        disp('no data.. moving on');
        
    else % data may exist, check for time domain data
        %         dbout(d).rec = d;
        
        tdfile = findFilesBVQX(dirsdata{d},'EventLog.json');
        
        
        %         tdir = dir(tdfile{1});
        
        
        if ~isempty(tdfile)  % time data file doesn't exists and real data
            
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
                
                
                
                
                %                 Get recording start time/ duration
                startTime = timeDomainSettings.timeStart;
                timeFormat = sprintf('%+03.0f:00',metaData.UTCoffset);
                startTimeDt = datetime(startTime/1000,'ConvertFrom','posixTime','TimeZone',timeFormat,'Format','dd-MMM-yyyy HH:mm:ss.SSS');
                dbout(d).time = startTimeDt;
                dbout(d).duration = duration(seconds(timeDomainSettings.duration/1000),'Format','hh:mm:ss.SSS');
                
                
                
                
                %                 Get time domain sensing info
                dbout(d).TDfs = timeDomainSettings.samplingRate;
                dbout(d).TDchan0= timeDomainSettings.chan1{1};
                dbout(d).TDchan1= timeDomainSettings.chan2{1};
                dbout(d).TDchan2= timeDomainSettings.chan3{1};
                dbout(d).TDchan3= timeDomainSettings.chan4{1};
                dbout(d).battery = metaData.batteryLevelPercent;
                
                
                
                
                %                  Get FFT length info
                try
                    if ~isnan(fftSettings.recNum)
                        dbout(d).fft = fftSettings.fftConfig.size;
                    end
                catch
                end
                
                
                
                %               Get powerbands and whether recorded info
                try
                    if ~isnan(powerSettings.recNum)
                        dbout(d).power = 1 ;
                        dbout(d).powerbands = powerSettings.powerBands.powerBandsInHz;
                    end
                catch
                end
                
                
                
                %             get Adaptive settings info
                [DetectorSettings,~,AdaptiveEmbeddedRuns_StimSettings] = createAdaptiveSettingsfromDeviceSettings(devicepath);
                
                % Look for sessions where the embedded was turned on in the
                % last subsession
                any_embed = strcmp('Embedded',AdaptiveEmbeddedRuns_StimSettings.adaptiveMode(end));
                
                if any_embed
                    dbout(d).adaptive_states=AdaptiveEmbeddedRuns_StimSettings.states(end);
                    dbout(d).adaptive_onset_dur = DetectorSettings.Ld0.onsetDuration;
                    dbout(d).adaptive_termination_dur = DetectorSettings.Ld0.terminationDuration;
                    dbout(d).adaptive_weights(1:4) = cat(1,DetectorSettings.Ld0.features.weightVector);
                    dbout(d).adaptive_pwrinputchan = DetectorSettings.Ld0.detectionInputs_BinaryCode  ;
                    dbout(d).adaptive_threshold = DetectorSettings.Ld0.biasTerm;
                    dbout(d).adaptive_updaterate = DetectorSettings.Ld0.updateRate;
                end
                
                
                
                %             get stim settings
                [stimSettingsOut, stimMetaData] = createStimSettingsFromDeviceSettings(devicepath);
                dbout(d).stim = stimSettingsOut.therapyStatus;
                
                
                
                
            catch
            end
            
            
            %Get stim information if STIM is on
            try
                
                if sum(dbout(d).stim)>0
                    
                    stimfile =  findFilesBVQX(dirsdata{d},'StimLog.json');
                    [stimpath,~,~]= fileparts(stimfile{1});
                    [stimLogSettings] = createStimSettingsTable(stimpath,stimMetaData);
                    
                    dbout(d).stim = stimLogSettings.activeGroup{1};
                    dbout(d).stimparams = stimLogSettings.stimParams_prog1;
                    stimnamegroup={'A','B','C','D'; '1' , '5', '9','13'};
                    [~,j]= find(contains(stimnamegroup,stimLogSettings.activeGroup));
                    stimname =  metaData.stimProgramNames(str2double(stimnamegroup{2,j}));
                    dbout(d).stimName =  stimname{1};
                end
                
            catch
            end
            
            
            
            % load event file
            try
                evFile = findFilesBVQX(dirsdata{d},'EventLog.json');
                eventData = loadEventLog(dbout(d).eventFile{1});
                dbout(d).eventData = eventData;
            catch
            end
            
            
            
            % does mat file exist?
            matfile = findFilesBVQX(dirsdata{d},'combinedDataTable.mat');
            if isempty(matfile) % no matlab data loaded
                dbout(d).matExist = false;
                %                 dbout(d).fnm = [];
            else
                dbout(d).matExist = true;
                %                 dbout(d).fnm = matfile{1};
            end
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

%% expanding all fields within each struct

expanded_database = [];

for rowidx = 1:size(sorted_database, 1)
    tmp_row = sorted_database(rowidx,:);  %tmp_row is the row with multiple entries
    if size(tmp_row.time{1}, 1) > 1  % duplicating entire row if there are multiple entries per session
        
        for new_row = 1:size(tmp_row.time{1}, 1)
            expanded_database = [expanded_database; tmp_row];
            for col_name = ["time", "duration", "TDfs"]
                expanded_database{end, col_name}{1} = expanded_database{end, col_name}{1}(new_row);
            end
            
            
                %make the first subsession an integer (like 2), and  all subsessions
                %decimals like  2.01, 2.02, etc.
            if new_row ==1
                expanded_database.rec(end) = tmp_row.rec;
            else
                expanded_database.rec(end) = tmp_row.rec + ((new_row-1)/100); 
            end
            
        end
    else  % print the single value  if only one entry per session
        
        expanded_database = [expanded_database; tmp_row];
        for col_name = ["time", "duration", "TDfs"]
            expanded_database{end, col_name}(1) = expanded_database{end, col_name}(1);
        end
        
        
        
    end
end

% expand all variables for each row and make 'Disabled' values in TDfs to NaN
idx_disabled=strcmp(expanded_database.TDfs,'Disabled');
expanded_database.TDfs(idx_disabled)={nan};

idx_emptyfft = cellfun(@isempty, expanded_database.fft);
expanded_database.fft(idx_emptyfft)={nan};

%  convert cells to string or double to remove cell structure
cellvars = {'time', 'duration', 'TDfs','battery','fft'};
for n = 1:numel(cellvars)
    
    if n >= 4
        expanded_database.(cellvars{n}) = cell2mat(expanded_database.(cellvars{n}));
    else
        expanded_database.(cellvars{n}) =[expanded_database.(cellvars{n}){:}]';
    end
    
end

expanded_database = movevars(expanded_database, {'TDchan0', 'TDchan1', 'TDchan2', 'TDchan3'}, 'After', 'TDfs');

RCSdatabase_out = table2timetable(expanded_database); % rename output for clarity



%% COMBINE WITH OLD DATABASE
% IF the old database existed, recombine with new database and sort it
if ~isempty(old_database)
    disp('combining with old database...');
    if iscell(RCSdatabase_out.matExist)
        % format some columns so they are not cells
        RCSdatabase_out.matExist = cell2mat(RCSdatabase_out.matExist);
        badsessions.matExist = cell2mat(badsessions.matExist);
    end
    
    
    RCSdatabase_out.rec = RCSdatabase_out.rec + old_database.rec(end);
    new_database_out = [old_database;RCSdatabase_out];
    
    if ~isempty(badsessions)
        badsessions = [D.badsessions;badsessions];
    else
        badsessions = D.badsessions;
    end
    
    clear RCSdatabase_out
    RCSdatabase_out = new_database_out;  %already a timetable
    
end


if nargout == 2
    varargout{1} = badsessions;
end
%

% Rename file to include patient ID
writetimetable(RCSdatabase_out,fullfile(dirname,[PtIDside '_database.csv']))
save(fullfile(dirname,[PtIDside '_database.mat']),'RCSdatabase_out','badsessions')
fprintf('csv and mat of database saved as %s to %s \n',[PtIDside '_database.mat'],dirname);


end