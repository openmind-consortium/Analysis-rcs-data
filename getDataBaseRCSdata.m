function tblout = getDataBaseRCSdata(dirname)
% function tblout = getDataBaseRCSdata(dirname)
%
%
% This function creates a database of rcs data
%
% INPUT:   DIRNAME should be the root folder of the Session Files
%               e.g. DIRNAME = '/Desktop/[PATIENTID]/SummitData/SummitContinuousBilateralStreaming/[PATIENT_Device_ID]'
%               e.g. DIRNAME = '/Volumes/Prasad_X5/RCS02/SummitData/SummitContinuousBilateralStreaming/RCS02R';
%
% OUTPUT:   TBLOUT is a table with fields ordered in importance, which can
%           be saved as a mat file or as .txt, .csv, etc using 'writetable'
%
%
%          Included fields are:
%    [{'time'}; {'sessname'  };  {'duration'  }; ...
%     {'battery'   };{'TDfs'      };{'TDSettings'};{'fft'};
%     {'power'     };{'stim'    };   {'stimName'  }; ...
%     {'stimparams'};   {'matExist'  };  {'path'};  {'powerbands'}];
%
%
%
%  Depedencies:
% https://github.com/JimHokanson/turtle_json
% in the a folder called "toolboxes" in the same directory as the processing scripts
%
%
% Prasad Shirvalkar Jan2021



dirsdata = findFilesBVQX(dirname,'Sess*',struct('dirs',1,'depth',1));


dbout = [];
for d = 1:length(dirsdata)
    diruse = findFilesBVQX(dirsdata{d},'Device*',struct('dirs',1,'depth',1));
    
    fprintf('Reading folder %d of %d  \n',d,length(dirsdata))
    if isempty(diruse) % no data exists inside
        
        dbout(d).rectime = [];
        dbout(d).matExist  = 0;
        dbout(d).fnm     = [];
        [pn,fn] = fileparts(dirsdata{d});
        dbout(d).sessname = fn;
    else % data may exist, check for time domain ndata
        tdfile = findFilesBVQX(dirsdata{d},'RawDataTD.json');
        tdir = dir(tdfile{1});
        
        if isempty(tdfile) || tdir.bytes < 300 % time data file doesn't exist or no data
        else
            
            
            [pn,fn] = fileparts(dirsdata{d});
            %            DELETE THIS?  dbout(d).rectime = getTime(fn);
            %            %generates date based on filename
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
                [stimSettingsOut, stimMetaData] = createStimSettingsFromDeviceSettings(devicepath);
                dbout(d).stim = stimSettingsOut.therapyStatus;
                
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

% Reorder field names;
fieldorder = [{'time'}; {'sessname'  };  {'duration'  }; ...
    {'battery'   };{'TDfs'      };{'TDSettings'};{'fft'}; {'power'     };...
    {'stim'    };   {'stimName'  }; ...
    {'stimparams'};   {'matExist'  };  {'path'};  {'powerbands'}];
dborder = orderfields(dbout,fieldorder);
tblout = struct2table(dborder,'AsArray',true);

end