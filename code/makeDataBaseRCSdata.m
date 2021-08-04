function [RCSdatabase_out,varargout] = makeDataBaseRCSdata(dirname,PATIENTIDside)
% function database_out = makeDataBaseRCSdata(dirname)
%
%
% This function creates a database of rcs data
%
% INPUT:   DIRNAME should be the root folder of the Session Files (e.g. SCBS folder)
%               e.g. DIRNAME = '/Desktop/[PATIENTID]/'
%               e.g. DIRNAME = '/Volumes/Prasad_X5/RCS02/;
%          
%          (OPTIONAL)
%           DIRNAME2 can be input if there is another folder location to use (e.g. 'aDBS folder')
% 
% 
% OUTPUT:   sorted_database is a table with fields ordered in importance, which will
%            be saved as a mat file and csv to DIRNAME
%   
%           (OPTIONAL)
%           SECOND OUTPUT could be provided to collect list of bad sessions
%           (e.g. those with no data in Jsons)
%
%          Included fields are:
%    [{'rec'}; {'time'}; {'sessname'  };  {'duration'  }; ...
%     {'battery'   };{'TDfs'      };{'TDchan0'};{'TDchan1'};{'TDchan2'};{'TDchan3'};{'fft'};
%     {'power'     };{'stim'    };   {'stimName'  }; ...
%     {'stimparams'};   {'matExist'  };  {'path'};  {'powerbands'}];
%
%
% 
%  USING CELL DATA IN THE TABLE:
%       to concatenate all cell variables in the table (such as duration)
%       use:
%           alldurations =cat(1,database_out.duration{:})
%
% 
% 
% 
% 
% Depedencies:
% https://github.com/JimHokanson/turtle_json
% in the a folder called "toolboxes" in the same directory as the processing scripts
%
%
% Prasad Shirvalkar July 29 2021
% For OpenMind
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
'aDBS',[]);
    

%%
% insert section here to load old database, and just add rows to it if
% needed, so as not to replicate whole thing.  
% Can be turned off with third input 'ignoreold' 



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
    else % data may exist, check for time domain data
%         dbout(d).rec = d;
        
        tdfile = findFilesBVQX(dirsdata{d},'EventLog.json');
        tdir = dir(tdfile{1});
        
        [pn,fn] = fileparts(dirsdata{d});
        dbout(d).sessname = fn;
        [path,~,~] = fileparts(tdfile{1});
        dbout(d).path = path;
        
        if isempty(tdfile) || tdir.bytes < 300 % time data file doesn't exist or no data
        else
            
            
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
                
                %                 Get time domain info
                dbout(d).TDfs = timeDomainSettings.samplingRate;
                dbout(d).TDchan0= timeDomainSettings.chan1{1};
                dbout(d).TDchan1= timeDomainSettings.chan2{1};
                dbout(d).TDchan2= timeDomainSettings.chan3{1};
                dbout(d).TDchan3= timeDomainSettings.chan4{1};
                dbout(d).battery = metaData.batteryLevelPercent;
                
                %                  Get FFT info
                try
                    if ~isnan(fftSettings.recNum)
                        dbout(d).fft = fftSettings.fftConfig.size;
                    end
                catch
                end
                
                
                %               Get power info
                try
                    if ~isnan(powerSettings.recNum)
                        dbout(d).power = 1 ;
                        dbout(d).powerbands = powerSettings.powerBands.powerBandsInHz;
                    end
                catch
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
                    stimname =  metaData.stimProgramNames(str2num(stimnamegroup{2,j}));
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
sorted_database = sortrows(database_out,3); %sorting by session name
sorted_database.rec = (1:size(sorted_database,1))';
  
%% clear empty session rows and assign to new variable 'badsessions'
loc = cellfun('isempty', sorted_database{:,'time'});
badsessions = sorted_database(loc,:);
sorted_database(loc,:) = [];

%% expanding all fields within each struct

expanded_database = [];

for rowidx = 1:size(sorted_database, 1)
    tmp_row = sorted_database(rowidx,:);
    if size(tmp_row.time{1}, 1) > 1  % duplicating entire row if there are multiple entries per session
        
        for new_row = 1:size(tmp_row.time{1}, 1)
            expanded_database = [expanded_database; tmp_row];
            for col_name = ["time", "duration", "TDfs"]
                expanded_database{end, col_name}{1} = expanded_database{end, col_name}{1}(new_row);
            end
            
            expanded_database.rec(end) = tmp_row.rec + (new_row/10); %(this will make the entry numbered for subsessions like 2.1,2.2 etc.)
     
        end
    else  % print the single value  if only one entry per session\
        
        expanded_database = [expanded_database; tmp_row];
        for col_name = ["time", "duration", "TDfs"]
            expanded_database{end, col_name}{1} = expanded_database{end, col_name}{1}(1);
        end
        


    end
end

% expand all variables for each row
expanded_database.time = transpose([expanded_database.time{:, 1}]);
expanded_database.duration = transpose([expanded_database.duration{:, 1}]);
expanded_database.TDfs = transpose([expanded_database.TDfs{:, 1}]);

expanded_database = movevars(expanded_database, {'TDchan0', 'TDchan1', 'TDchan2', 'TDchan3'}, 'After', 'TDfs');

RCSdatabase_out = table2timetable(expanded_database); % rename output for clarity


if nargout == 2
    varargout{1} = badsessions;
end
% 

% Rename file to include patient ID
[~,PtIDside]=fileparts(scbsdir);
writetable(expanded_database,fullfile(dirname,[PtIDside '_database.csv']))
save(fullfile(dirname,[PtIDside '_database.mat']),'RCSdatabase_out','badsessions')
fprintf('csv and mat of database saved as %s to %s \n',[PtIDside '_database.mat'],dirname);


end