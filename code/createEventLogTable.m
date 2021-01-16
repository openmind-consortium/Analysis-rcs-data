function [eventLogTable] = createEventLogTable(folderPath)
%%
% Extract information from EventLog.json
%
% Input: Folder path to Device* folder containing json files
%%
% Load in EventLog.json
try
    eventLog = jsondecode(fixMalformedJson(fileread([folderPath filesep 'EventLog.json']),'EventLog'));
catch
    eventLog = deserializeJSON([folderPath filesep 'EventLog.json']);
end

eventLogTable = table();
if ~isempty(eventLog)
    
    eventLogTable = table();
    numRecords = size(eventLog,1);
    for iRecord = 1:numRecords
        clear newEntry
        
        newEntry.SessionId = eventLog(iRecord).RecordInfo.SessionId;
        newEntry.HostUnixTime = eventLog(iRecord).RecordInfo.HostUnixTime;
        newEntry.EventName = eventLog(iRecord).Event.EventName;
        newEntry.EventType = eventLog(iRecord).Event.EventType;
        newEntry.EventSubType = eventLog(iRecord).Event.EventSubType;
        newEntry.UnixOnsetTime = eventLog(iRecord).Event.UnixOnsetTime;
        newEntry.UnixOffsetTime = eventLog(iRecord).Event.UnixOffsetTime;
        
        eventLogTable = addRowToTable(newEntry,eventLogTable);   
    end
end
end
