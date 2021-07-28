function [adaptiveLogTable, rechargeSessions, groupChanges,adaptiveDetectionEvents] = read_adaptive_txt_log(fn)
clc; close all;
% initialize table
adaptiveLogTable = table();

%% get time
str = fileread( fn );

newBlocks = regexp(str, {'\n\r'});
newBlockLines = newBlocks{1};  
newBlockLines = [1 newBlockLines];
% loop on text and get each new block in a cell array 
cntBlock = 1;
while cntBlock ~= (length(newBlockLines)-1)
    events{cntBlock} = str(newBlockLines(cntBlock) : newBlockLines(cntBlock+1));
    cntBlock = cntBlock + 1; 
end
eventsRaw = events;
%% get all event types 
for e = 1:length(events)
    str = events{e};

    xpruse1 = '(';
    cac1 = regexp( str, xpruse1 );
    
    xpruse1 = ')';
    cac2 = regexp( str, xpruse1 );
    
    
    strraw = str(cac1(2)+1:cac2(2)-1);
    adaptiveLogEvents.EventID{e} = strraw;
end
idxuse = strcmp(adaptiveLogEvents.EventID,'AdaptiveTherapyStateChange');
allEvents = events; 
%% AdaptiveTherapyStateChange
events = allEvents(idxuse);
for e = 1:length(events)
    str = events{e};
    car = regexp(str, '\r');
    
    xpr = ['Seconds = '];
    cac1 = regexp( str, xpr );
    
    xpr = ['DateTime = '];
    cac2 = regexp( str, xpr );
    
    clear hexstr
    for t = 1:length(cac1)
        hexstr(t,:) = str(cac1(t)+12:cac2(t)-3);
    end
    rawsecs = hex2dec(hexstr);
    startTimeDt = datetime(datevec(rawsecs./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds
    adaptiveLogTable.time(e) = startTimeDt;
    %%
    
    %% get status
    xpr = ['AdaptiveTherapyModificationEntry.Status '];
    cac1 = regexp( str, xpr );
    
    
    xpr = ['(EmbeddedActive)'];
    cac2 = regexp( str, xpr );
    
    clear status
    for t = 1:length(cac1)
        status(t,:) = str(cac1(t)+68:cac2(t)-3);
    end
    statusdec = hex2dec(status);
    adaptiveLogTable.status(e) = statusdec;
    
    %%
    
    %% new state
    xpr = ['AdaptiveTherapyModificationEntry.NewState '];
    cac1 = regexp( str, xpr );
    
    clear newstate
    for t = 1:length(cac1)
        newstate(t,:) = str(cac1(t)+68:cac1(t)+69);
    end
    newstate = hex2dec(newstate);
    adaptiveLogTable.newstate(e) = newstate;
    %%
    
    %% old state
    xpr = ['AdaptiveTherapyModificationEntry.OldState '];
    cac1 = regexp( str, xpr );
    
    clear oldstate
    for t = 1:length(cac1)
        if (cac1(t)+69) > length(str)
            oldstate(t,:) = NaN;
        else
            oldstate(t,:) = str(cac1(t)+68:cac1(t)+69);
        end
    end
    oldstate = hex2dec(oldstate);
    adaptiveLogTable.oldstate(e) = oldstate;
    %%
    
    %% loop on programs
    for p = 0:3
        xpruse = sprintf('AdaptiveTherapyModificationEntry.Prog%dAmpInMillamps ',p);
        cac1 = regexp( str, xpruse );
        
        clear prog progNum
        for t = 1:length(cac1)
            prog(t,:) = str(cac1(t)+66:cac1(t)+71);
        end
        progNum = str2num(prog);
        fnuse = sprintf('prog%d',p);
        adaptiveLogTable.(fnuse)(e) = progNum;
    end
    
    %% rate
    xpruse = 'AdaptiveTherapyModificationEntry.RateAtTimeOfModification ';
    cac1 = regexp( str, xpruse );
    
    clear rate
    for t = 1:length(cac1)
        rate(t,:) = str(cac1(t)+66:cac1(t)+73);
    end
    ratenum = str2num(rate);
    %%
    adaptiveLogTable.rateHz(e) = ratenum;
    
    % events ID 
    xpruse1 = 'CommonLogPayload`1.EventId      = 0x00 (';
    cac1 = regexp( str, xpruse1 );
    xpruse2 = 'CommonLogPayload`1.EntryPayload = ';
    cac2 = regexp( str, xpruse2 );
    strraw = str(cac1:cac2-4);
    strtmp = strrep( strrep(strraw,xpruse1,''), ')','');
    adaptiveLogTable.EventID{e} = strtmp(1:end-3);
    

    
end
%% Recharge sesions 
idxuse = strcmp(adaptiveLogEvents.EventID,'RechargeSesson');
allEvents = eventsRaw; 
events = allEvents(idxuse);
rechargeSessions = table();
for e = 1:length(events)
    str = events{e};
    car = regexp(str, '\r');
    
    xpr = ['Seconds = '];
    cac1 = regexp( str, xpr );
    
    xpr = ['DateTime = '];
    cac2 = regexp( str, xpr );
    
    clear hexstr
    for t = 1:length(cac1)
        hexstr(t,:) = str(cac1(t)+12:cac2(t)-3);
    end
    rawsecs = hex2dec(hexstr);
    startTimeDt = datetime(datevec(rawsecs./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds
    rechargeSessions.time(e) = startTimeDt;
    %%
    
    %% get type
    xpr = ['RechargeSessionEventLogEntry.RechargeSessionStatus = '];
    cac1 = regexp( str, xpr );
    
    
    xpr = ['RechargeSessionEventLogEntry.Unused'];
    cac2 = regexp( str, xpr );
    clear status 
    status = str(cac1+59:cac2-12);   
    
    rechargeSessions.status{e} = status;
    %%
end

%% adaptive therapy status 
idxuse = strcmp(adaptiveLogEvents.EventID,'AdaptiveTherapyStatusChanged');
allEvents = eventsRaw; 
events = allEvents(idxuse);
adaptiveStatus = table();
for e = 1:length(events)
    str = events{e};
    car = regexp(str, '\r');
    
    xpr = ['Seconds = '];
    cac1 = regexp( str, xpr );
    
    xpr = ['DateTime = '];
    cac2 = regexp( str, xpr );
    
    clear hexstr
    for t = 1:length(cac1)
        hexstr(t,:) = str(cac1(t)+12:cac2(t)-3);
    end
    rawsecs = hex2dec(hexstr);
    startTimeDt = datetime(datevec(rawsecs./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds
    adaptiveStatus.time(e) = startTimeDt;
    %%
    
    %% get type
    xpr = ['AdaptiveTherapyStatusChangedEventLogEntry.Status = '];
    cac1 = regexp( str, xpr );
    
    
    xpr = ['AdaptiveTherapyStatusChangedEventLogEntry.Unused = '];
    cac2 = regexp( str, xpr );
    clear status 
    status = str(cac1+57:cac2-12);   
    
    adaptiveStatus.status{e} = status;
    %%
end


%% ActiveDeviceChanged - means group change 
idxuse = strcmp(adaptiveLogEvents.EventID,'ActiveDeviceChanged');
allEvents = eventsRaw; 
events = allEvents(idxuse);
groupChanges = table();
for e = 1:length(events)
    str = events{e};
    car = regexp(str, '\r');
    
    xpr = ['Seconds = '];
    cac1 = regexp( str, xpr );
    
    xpr = ['DateTime = '];
    cac2 = regexp( str, xpr );
    
    clear hexstr
    for t = 1:length(cac1)
        hexstr(t,:) = str(cac1(t)+12:cac2(t)-3);
    end
    rawsecs = hex2dec(hexstr);
    startTimeDt = datetime(datevec(rawsecs./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds
    groupChanges.time(e) = startTimeDt;
    %%
    
    %% get type
    xpr = ['TherapyActiveGroupChangedEventLogEntry.NewGroup = '];
    cac1 = regexp( str, xpr );
    
    
    xpr = ['TherapyActiveGroupChangedEventLogEntry.Unused   = '];
    cac2 = regexp( str, xpr );
    clear status 
    status = str(cac1+56:cac2-12);
    switch status
        case 'Group0'
            groupUse = 'A';
        case 'Group1'
            groupUse = 'B';
        case 'Group2'
            groupUse = 'C';
        case 'Group3'
            groupUse = 'D';
    end
        
    groupChanges.group{e} = groupUse;
    %%
end
%%










%% Ld detection events  
idxuse = strcmp(adaptiveLogEvents.EventID,'LdDetectionEvent');
allEvents = eventsRaw; 
events = allEvents(idxuse);
adaptiveDetectionEvents = table();
for e = 1:length(events)
    str = events{e};
    car = regexp(str, '\r');
    
    xpr = ['Seconds = '];
    cac1 = regexp( str, xpr );
    
    xpr = ['DateTime = '];
    cac2 = regexp( str, xpr );
    
    clear hexstr
    for t = 1:length(cac1)
        hexstr(t,:) = str(cac1(t)+12:cac2(t)-3);
    end
    rawsecs = hex2dec(hexstr);
    startTimeDt = datetime(datevec(rawsecs./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds
    adaptiveDetectionEvents.time(e) = startTimeDt;
    %
    
    % get type
    xpr = ['LdDetectionEntry.CurrentDetectionState  = '];
    cac1 = regexp( str, xpr );
    
    
    xpr = ['LdDetectionEntry.PreviousDetectionState = '];
    cac2 = regexp( str, xpr );
    clear status 
    
    % a few states possible 
    tempstr = str(cac1:cac2);
    
    xpr = ['0x'];
    cac1 = regexp( tempstr, xpr );
    
    
    xpr = ['('];
    cac2 = regexp( tempstr, xpr );
    
    
    detHexStr = tempstr(cac1+2:cac2-2);
    detectionNum = hex2dec(detHexStr);
    
    % get string event 
    xpr = ['LdDetectionEntry.CurrentDetectionState  = '];
    cac1 = regexp( str, xpr );
    
    
    xpr = ['LdDetectionEntry.PreviousDetectionState = '];
    cac2 = regexp( str, xpr );

    tempstr = str(cac1:cac2);
    xpr = ['('];
    cac1 = regexp( tempstr, xpr );
    
    xpr = [')'];
    cac2 = regexp( tempstr, xpr );
    
    newstr = tempstr(cac1:cac2);
    
    
    adaptiveDetectionEvents.detectionStatus(e) = detectionNum;
    adaptiveDetectionEvents.detectionText{e} = newstr;
    
    
    % get the previous detection state 
    
    
    
    
    
    % get type
    xpr = ['LdDetectionEntry.PreviousDetectionState = '];
    cac1 = regexp( str, xpr );
    
    
    xpr = ['LdDetectionEntry.Unused'];
    cac2 = regexp( str, xpr );
    clear status 
    
    % a few states possible 
    tempstr = str(cac1:cac2);
    
    xpr = ['0x'];
    cac1 = regexp( tempstr, xpr );
    
    
    xpr = ['('];
    cac2 = regexp( tempstr, xpr );
    
    
    detHexStr = tempstr(cac1+2:cac2-2);
    detectionNum = hex2dec(detHexStr);
    
    % get string event 
    xpr = ['LdDetectionEntry.PreviousDetectionState = '];
    cac1 = regexp( str, xpr );
    
    
    xpr = ['LdDetectionEntry.Unused'];
    cac2 = regexp( str, xpr );
    clear status 

    tempstr = str(cac1:cac2);
    xpr = ['('];
    cac1 = regexp( tempstr, xpr );
    
    xpr = [')'];
    cac2 = regexp( tempstr, xpr );
    
    newstr = tempstr(cac1:cac2);
    
    
    adaptiveDetectionEvents.previousDetectionStatus(e) = detectionNum;
    adaptiveDetectionEvents.previousDetectionText{e} = newstr;
end
%%











%% Recharge sesions 
idxuse = strcmp(adaptiveLogEvents.EventID,'AdaptiveTherapyStateWritten');
allEvents = eventsRaw; 
events = allEvents(idxuse);
adaptiveStateWritten = table();
for e = 1:length(events)
    str = events{e};
    car = regexp(str, '\r');
    
    xpr = ['Seconds = '];
    cac1 = regexp( str, xpr );
    
    xpr = ['DateTime = '];
    cac2 = regexp( str, xpr );
    
    clear hexstr
    for t = 1:length(cac1)
        hexstr(t,:) = str(cac1(t)+12:cac2(t)-3);
    end
    rawsecs = hex2dec(hexstr);
    startTimeDt = datetime(datevec(rawsecs./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds
    rechargeSessions.time(e) = startTimeDt;
    %%
    
    %% get type
    xpr = ['RechargeSessionEventLogEntry.RechargeSessionStatus = '];
    cac1 = regexp( str, xpr );
    
    
    xpr = ['RechargeSessionEventLogEntry.Unused'];
    cac2 = regexp( str, xpr );
    clear status 
    status = str(cac1+59:cac2-12);   
    
    rechargeSessions.status{e} = status;
    %%
end



















if size(adaptiveLogTable,1) > 30
    at = adaptiveLogTable(1:20,:);
    idxzero = at.newstate==0;
    unique(at.prog0(idxzero))
end
%%
end