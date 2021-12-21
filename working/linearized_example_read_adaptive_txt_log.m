% Below I have linearized the code from read_adaptive_txt_log.m lines 
% 148- 184 and it is 3-4 times faster! 
% Prasad July 28 2021



%% 
% NOT LINEARIZED EXAMPLE 


tic
% Recharge sessions
idxuse = strcmp(adaptiveLogEvents.EventID,'RechargeSesson');
allEvents = eventsRaw;
events = allEvents(idxuse);
rechargeSessions = table('Size', [length(events) 2], 'VariableTypes', {'datetime','cell'}, 'VariableNames', {'time','status'});
for r = 1:length(events)
    str = events{r};
    
    
    xpr = ['Seconds = '];
    cac1 = regexp( str, xpr );
    
    xpr = ['DateTime = '];
    cac2 = regexp( str, xpr );
    
    hexstr = zeros(length(cac1),8);
    for t = 1:length(cac1)
        hexstr(t,:) = str(cac1(t)+12:cac2(t)-3);
    end
    rawsecs = hex2dec(hexstr);
    startTimeDt = datetime(datevec(rawsecs./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds
    rechargeSessions.time(r) = startTimeDt;
    %
    
    %get type
    xpr = 'RechargeSessionEventLogEntry.RechargeSessionStatus = ';
    cac1 = regexp( str, xpr );
    xpr = 'RechargeSessionEventLogEntry.Unused';
    cac2 = regexp( str, xpr );
    clear status
    status = str(cac1+59:cac2-12);
    
    rechargeSessions.status{r} = status;

end
toc

%%

 xpr = 'Seconds = ';
    cac1 = cellfun(@(x) regexp(x, xpr),events,'UniformOutput',false);
    xpr = 'DateTime = ';
    cac2 = cellfun(@(x) regexp(x, xpr),events,'UniformOutput',false);
    
    hexstr = cellfun(@(x,a,b) x(a+12:b-3),events,cac1,cac2,'UniformOutput',false);
    rawsecs = hex2dec(hexstr);
    startTimeDt = datetime(datevec(rawsecs./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds
    adaptiveLogTable.time = startTimeDt;
    
    %%
    
    %% get status
    xpr = 'AdaptiveTherapyModificationEntry.Status ';
    cac1 = cellfun(@(x) regexp(x, xpr),events,'UniformOutput',false);
    xpr = '(EmbeddedActive)';
    cac2 = cellfun(@(x) regexp(x, xpr),events,'UniformOutput',false);
    
    status = cellfun(@(x,a,b) x(a+68:b-3),events,cac1,cac2,'UniformOutput',false);
  
    statusdec = hex2dec(status);
    adaptiveLogTable.status = statusdec;

