function [outtable, srates] = unravelData(TDdat)
%% Function to unravel TimeDomainData
% input: a structure time domain data that is read from TimeDomainRaw.json 
% file that is spit out by RC+S Summit interface. 
% To transform *.json file into structure use deserializeJSON.m 
% in this folder 
%% unravel data 

%% check for bad packets 

unixtimes = [TDdat.TimeDomainData.PacketRxUnixTime];
uxtimes = datetime(unixtimes'/1000,...
    'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');

temp  = [TDdat.TimeDomainData.Header];
temp2 = [temp.timestamp];
uxseconds = [temp2.seconds];
startTimeDt = datetime(datevec(uxseconds./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds


yearMode = mode(year(startTimeDt)); 
% check for packets with funky year 
badPackets = year(startTimeDt)~=yearMode;  % sometimes the seconds is a bad msseaurment 
% evidnetly year is not hte only problem, make sure most packets within a
% week of median (to take care of cases in which reconnecitons happen
% throughout days) 
medianTime = median(startTimeDt);
badPackets3 = startTimeDt > (medianTime + hours(24)*7);
badPackets4= startTimeDt < (medianTime - hours(24)*7);
% check for packets in the future 
badPackets2 = uxtimes(1:end-1) >= uxtimes(2:end) ;
badPackets2 = [badPackets2; 0];
% check to see if packet time can be negative 
badpackets5 = [TDdat.TimeDomainData.PacketGenTime]<=0;
badpackets5 = badpackets5';
% check to see if data type sequence always increases monotonically 
% note that it roles over after 255 packets (e.g. goes from 255 to 0). 
% I am getting rid of the first packet on purpose 
headertemp = TDdat.TimeDomainData;
headers2 = [headertemp.Header];
dataTypeSequence = [headers2.dataTypeSequence];
dataTypeSequenceTemp = [headers2(1).dataTypeSequence dataTypeSequence];
badpackets6 = diff(dataTypeSequenceTemp')==0;


idxBadPackets = badPackets | badPackets2 | badPackets3 | badPackets4 | badpackets5 | badpackets6;
TDdat.TimeDomainData = TDdat.TimeDomainData(~idxBadPackets);

% find ambigous roleovers and remove them to make them not ambigous
% any more 
headertemp = TDdat.TimeDomainData;
headers2 = [headertemp.Header];
temp = [headers2.timestamp];
timestamps = [temp.seconds]; 
timestamps_sec = datetime(datevec(timestamps./86400 + datenum(2000,3,1,0,0,0)),...% medtronic time - LSB is seconds
    'TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS'); 
idxGapsLargerThan6sec = find(seconds(diff([timestamps_sec(1); timestamps_sec])) > 6);
max_st = (2^16)/1e4; 
cnt = 1;
bad_timestamps = NaT;
bad_timestamps.TimeZone = timestamps_sec.TimeZone;
for i = 1:length( idxGapsLargerThan6sec ) 
    ts1 = timestamps_sec(idxGapsLargerThan6sec(i)-1); 
    ts2 = timestamps_sec(idxGapsLargerThan6sec(i)); 
    curgap = ts2-ts1; 
    % is the gap potentially ambgious
    minN = seconds(ts2 - (ts1 + seconds(1))) / max_st;
    maxN = seconds((ts2+ seconds(1)) - ts1) / max_st;
    % if the gap can be ambigous remove packets until it is not
    if floor(minN) ~= floor(maxN) 
        minN_new = minN; 
        maxN_new = maxN; 
        
        ts2_new = ts2;
        ts1_new = ts1;

         while minN_new ~= maxN_new
             minN_new = floor( seconds(ts2_new - (ts1_new + seconds(1))) / max_st );
             maxN_new = floor( seconds((ts2_new+ seconds(1)) - ts1_new) / max_st  );
             bad_timestamps(cnt) = ts2_new;
             ts2_new = ts2_new + seconds(1);
             cnt = cnt +1 ;
         end
         fprintf('[%0.3d] current gap is %s secs\n',i,ts2_new-ts1_new);
         fprintf('\t ts1   - %s\t ts2   - %s\n',ts1,ts2);
         fprintf('\t ts1_n - %s\t ts2_n - %s\n',ts1_new,ts2_new);
    else
        fprintf('[%0.3d] current gap is not ambigous - %s secs\n',i,ts2-ts1);
    end  
end
idx_bad_timetamps = logical(zeros(size(timestamps_sec,1),1));
for b = 1:length(bad_timestamps)
    idx_bad_timetamps = [idx_bad_timetamps | ...
        timestamps_sec == bad_timestamps(b)];
end
TDdat.TimeDomainData = TDdat.TimeDomainData(~idx_bad_timetamps);

% remove system ticks that are the same - this is essentially a duplicate
% packet, remove the second one 
% there is a small chance we are removing a roleover event (e.g. large
% packet loss, but even in these cases it would make it much easier to
% compute if we didn't have this packet). 
headertemp = TDdat.TimeDomainData;
headers2 = [headertemp.Header];
systemTicks = [headers2.systemTick];
idxsametick =  diff(  [(systemTicks(1)-1) systemTicks] ) == 0;
TDdat.TimeDomainData = TDdat.TimeDomainData(~idxsametick);


%% deduce sampling rate 
srates = getSampleRate([TDdat.TimeDomainData.SampleRate]');

%% pre allocate memory 
% find out how many channels of data you have 
nchan = size(TDdat.TimeDomainData(1).ChannelSamples,2);
% find out how many rows you need to allocate , you may not 
% have consistent nubmer of channels through the recording 
% get the number of channels for each packet 
tdtmp = TDdat.TimeDomainData;
for p = 1:size(tdtmp,2)
    nchans(p,1) = size(tdtmp(p).ChannelSamples,2);
end
maxnchans = max(nchans);
tmp = [TDdat.TimeDomainData.Header];
datasizes = [tmp.dataSize]';
packetsizes = (datasizes./nchans)./2; % divide by 2 bcs data Size is number of bits in packet. 
nrows = sum(packetsizes);
outdat = zeros(nrows, max(nchans)+3); % pre allocate memory 

%% loop on pacets to create out data with INS time and system tick 
% loop on packets and populate packets fields 
start = tic; 
curidx = 0; 
%% to simplify things, always have 4 channels, even if only 2 active 
maxnchans = 4;
varnames = {'key0','key1','key2','key3'}; 
for p = 1:size(datasizes,1)
    rowidx = curidx+1:1:(packetsizes(p)+curidx);
    curidx = curidx + packetsizes(p); 
    packetidx = curidx;  % the time is always associated with the last sample in the packet 
    samples = TDdat.TimeDomainData(p).ChannelSamples;
    nchan =  nchans(p,1);
    for c = 1:size(samples,2)
        idxuse = samples(c).Key+1;% bcs keys (channels) are zero indexed 
        outdat(rowidx,idxuse) = samples(c).Value;
    end
    outdat(packetidx,maxnchans+1) = TDdat.TimeDomainData(p).Header.systemTick; 
    varnames{maxnchans+1} = 'systemTick'; 
    outdat(packetidx,maxnchans+2) = TDdat.TimeDomainData(p).Header.timestamp.seconds; 
    varnames{maxnchans+2} = 'timestamp'; 
    outdat(packetidx,maxnchans+3) = srates(p); 
    varnames{maxnchans+3} = 'samplerate'; 
    
    
    outdat(packetidx,maxnchans+4) = TDdat.TimeDomainData(p).PacketGenTime;
    varnames{maxnchans+4} = 'PacketGenTime'; 
    
    outdat(packetidx,maxnchans+5) =  TDdat.TimeDomainData(p).PacketRxUnixTime; 
    varnames{maxnchans+5} = 'PacketRxUnixTime'; 
    
    outdat(packetidx,maxnchans+6) =  packetsizes(p); 
    varnames{maxnchans+6} = 'packetsizes'; 
    
    outdat(packetidx,maxnchans+7) = TDdat.TimeDomainData(p).Header.dataTypeSequence;
    varnames{maxnchans+7} = 'dataTypeSequence';

end


%%
fprintf('finished unpacking into matrix in %.2f seconds\n',toc(start));
outtable = array2table(outdat);
clear outdat; 
outtable.Properties.VariableNames = varnames; 
outtable.Properties.VariableDescriptions{nchan+1} = ...
    'systemTick ? INS clock-driven tick counter, 16bits, LSB is 100microseconds, (highly accurate, high resolution, rolls over)';
outtable.Properties.VariableDescriptions{nchan+2} = ...
    'timestamp ? INS clock-driven time, LSB is seconds (highly accurate, low resolution, does not roll over)';

outtable.Properties.VariableDescriptions{nchan+3} = ...
    'sample rate for each packet, used in cases in which the sample rate is not conssistent through out session';

outtable.Properties.VariableDescriptions{nchan+4} = ...
    'API estimate of when the data packet was created on the INS within the PC clock domain. Estimate created by using results of latest latency check (one is done at system initialization, but can re-perform whenever you want) and time sync streaming. Potentially useful for syncing with other sensors or devices by bringing things into the PC clock domain, but is only accurate within 50ms give or take.';

outtable.Properties.VariableDescriptions{nchan+5} = ...
    'PC clock-driven time when the packet was received via Bluetooth, as accurate as a C# DateTime.now (10-20ms)';


end
