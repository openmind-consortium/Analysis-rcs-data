function database_out = makeDataBaseRCSdata(dirname,varargin)
% function database_out = makeDataBaseRCSdata(dirname)
%
%
% This function creates a database of rcs data
%
% INPUT:   DIRNAME should be the root folder of the Session Files
%               e.g. DIRNAME = '/Desktop/[PATIENTID]/SummitData/SummitContinuousBilateralStreaming/[PATIENT_Device_ID]'
%               e.g. DIRNAME = '/Volumes/Prasad_X5/RCS02/SummitData/SummitContinuousBilateralStreaming/RCS02R';
%
% OUTPUT:   TBLOUT is a table with fields ordered in importance, which will
%            be saved as a mat file and csv to DIRNAME
%
%
%          Included fields are:
%    [{'rec'}; {'time'}; {'sessname'  };  {'duration'  }; ...
%     {'battery'   };{'TDfs'      };{'TDSettings'};{'fft'};
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
% Prasad Shirvalkar Jan2021
% For OpenMind

if nargin == 2
    
dirsdata1 = findFilesBVQX(dirname,'Sess*',struct('dirs',1,'depth',1));
dirsdata2 =  findFilesBVQX(varargin{1},'Sess*',struct('dirs',1,'depth',1));
dirsdata = [dirsdata1;dirsdata2];
else
dirsdata = findFilesBVQX(dirname,'Sess*',struct('dirs',1,'depth',1));

end

dbout = struct('rec',[],...
    'time',[],...
    'sessname',[],...
    'duration',[],...
    'battery',[],...
    'TDfs',[],...
    'TDSettings',[],...
    'fft',[],...
    'power',[],...
    'stim',[],...
    'stimName',[],...
    'stimparams',[],...
    'matExist',[],...
    'path',[],...
    'powerbands',[],...
    'adaptiveLD_mean', [],...
    'adaptiveLD_std', [],...
'aDBS',[]);


for d = 1:length(dirsdata)
    diruse = findFilesBVQX(dirsdata{d},'Device*',struct('dirs',1,'depth',1));
    
   if nargin==2 &&  d > numel(dirsdata1)
       dbout(d).aDBS = 1;
   else 
       dbout(d).aDBS= 0;
   end
   
    fprintf('Reading folder %d of %d  \n',d,length(dirsdata))
    if isempty(diruse) % no data exists inside
        dbout(d) = d;
        dbout(d).time = [];
        dbout(d).matExist  = 0;
        [~,fn] = fileparts(dirsdata{d});
        dbout(d).sessname = fn;
    else % data may exist, check for time domain ndata
        dbout(d).rec = d;
        
        tdfile = findFilesBVQX(dirsdata{d},'RawDataTD.json');
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
                dbout(d).TDSettings = timeDomainSettings(1,6:9);
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
                try      
                    [stimSettingsOut, stimMetaData] = createStimSettingsFromDeviceSettings(devicepath);
                    dbout(d).stim = stimSettingsOut.therapyStatus;
                catch
                end
                
                
                %             get adaptive settings
                try
                    adaptivefile = findFilesBVQX(dirsdata{d},'AdaptiveLog.json');
                    AdaptiveDataJsonObj = deserializeJSON(adaptivefile{1});
                    if isempty(AdaptiveDataJsonObj)
                        dbout(d).adaptiveLD_mean = NaN;
                        dbout(d).adaptiveLD_std = NaN;
                    else
                        AdaptiveData = createAdaptiveTable(AdaptiveDataJsonObj);
                        dbout(d).adaptiveLD_mean = mean(AdaptiveData.Ld0_output);
                        dbout(d).adaptiveLD_std = std(AdaptiveData.Ld0_output);
                    end
                catch
                end
            catch
            end
            
            
            %Get stim information if STIM is on
            try
                
                if dbout(d).stim == 1
                    
                    stimfile =  findFilesBVQX(dirsdata{d},'StimLog.json');
                    [stimpath,~,~]= fileparts(stimfile{1});
                    [stimLogSettings] = createStimSettingsTable(stimpath);
                    
                    dbout(d).stim = stimLogSettings.activeGroup{1};
                    dbout(d).stimparams = stimLogSettings.(['Group' dbout(d).stim]);
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


% Rename file to include patient ID
slashind = find((dirname=='/'),1,'last');
PTID = dirname(slashind+1:end);
%writetable(database_out,fullfile(dirname,[PTID 'database_summary.csv']))
save(fullfile(dirname,[PTID 'database_summary.mat']),'database_out')
fprintf('csv and mat of database saved as %s to %s \n',[PTID 'database_summary.mat'],dirname);


end