function tblout = getDataBaseRCSdata(dirname)
% this function created a database of rcs data 

% NEED TO EDIT THIS SO IT JUST CREATES A DATABASE as part of the
% DEMO_Process_RCS.m function 
% 
% rows 
% rec time 
% path to filename 
% rawTDdata .mat exist 
% plot (boolean) 

% depends on: 
% turtle json 

% add path
ptadd = genpath(fullfile(pwd,'toolboxes','turtle_json'));
addpath(ptadd); 

dirsdata = findFilesBVQX(dirname,'Sess*',struct('dirs',1,'depth',1));

% find out if a database file was already created in this folder 
% if so, just an update is needed no need to recrate the whole 
% database

% extract times and .mat status 
dbout = []; 
for d = 1:length(dirsdata)
    diruse = findFilesBVQX(dirsdata{d},'Device*',struct('dirs',1,'depth',1));
    
    if isempty(diruse) % no data exists inside  
        
        dbout(d).rectime = []; 
        dbout(d).matExist  = 0; 
        dbout(d).plot    = false; 
        dbout(d).fnm     = []; 
        dbout(d).tdfile  = []; 
        [pn,fn] = fileparts(dirsdata{d}); 
        dbout(d).sessname = fn;
    else % data may exist, check for time domai ndata  
        tdfile = findFilesBVQX(dirsdata{d},'RawDataTD.json');
        if isempty(tdfile) % time data file doesn't exist
        else
            
            
            
            
%             COMBINE ThIS WITH RCS_PAIN_PREPROCESS



            [pn,fn] = fileparts(dirsdata{d});
            dbout(d).rectime = getTime(fn);
            dbout(d).sessname = fn;
            
            dbout(d).tdfile = tdfile{1};
            %         timeReport = reportime(tdfile{1}); % XXX
            timeReport = report_start_end_time_td_file_rcs(tdfile{1});
            dbout(d).startTime = timeReport.startTime;
            dbout(d).endTime = timeReport.endTime;
            dbout(d).duration = timeReport.duration;
            
            % load event file
            try
                evFile = findFilesBVQX(dirsdata{d},'EventLog.json');
                dbout(d).eventFile = evFile{1};
                eventData = loadEventLog(dbout(d).eventFile);
                dbout(d).eventData = eventData;
            catch
            end
            
            
            % does mat file exist?
            matfile = findFilesBVQX(dirsdata{d},'*TD*.mat');
            if isempty(matfile) % no matlab data loaded
                dbout(d).matExist = false;
                dbout(d).fnm = [];
            else
                dbout(d).matExist = true;
                dbout(d).fnm = matfile{1};
            end
            dbout(d).plot = false;
        end
    end
end
tblout = struct2table(dbout,'AsArray',true); 
% clean up 
rmpath(ptadd); 
end

function t = getTime(fn)
%% 
tmpcl = regexp(fn,'[0-9]+','match');
timenum = str2num(tmpcl{1});
t = datetime(timenum/1000,'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
%%
end



