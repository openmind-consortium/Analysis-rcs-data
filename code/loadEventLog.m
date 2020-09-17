function eventTable  = loadEventLog(fn)
eventLog = jsondecode(fixMalformedJson(fileread(fn),'EventLog'));
[pn,fnm,ext ] = fileparts(fn);
if isempty(eventLog)
    fprintf('event table is empty\n'); 
    fprintf('creating dummy event table\n'); 
    eventTable  = [];
else
    for e = 1:length(eventLog)
        timenum = str2num(eventLog(e).RecordInfo.SessionId);
        t = datetime(timenum/1000,'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
        outTab(e).sessionTime = t;
        outTab(e).sessionid = eventLog(e).RecordInfo.SessionId;
        outTab(e).EventSubType = eventLog(e).Event.EventSubType;
        outTab(e).EventType = eventLog(e).Event.EventType;
        t = datetime(eventLog(e).Event.UnixOnsetTime/1000,...
            'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
        outTab(e).UnixOnsetTime = t;
        t = datetime(eventLog(e).Event.UnixOffsetTime/1000,...
            'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
        outTab(e).UnixOffsetTime = t;
        
        t = datetime(eventLog(e).RecordInfo.HostUnixTime/1000,...
            'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
        outTab(e).HostUnixTime = t;
        
    end
    eventTable = struct2table(outTab,'AsArray',true);
end


