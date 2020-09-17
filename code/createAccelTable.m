function [outtable, srates] = createAccelTable(TDdat)
%% Function to unravel TimeDomainData
% input: a structure time domain data that is read from TimeDomainRaw.json 
% file that is spit out by RC+S Summit interface. 
% To transform *.json file into structure use deserializeJSON.m 
% in this folder 
%% unravel data 



%% check for bad packets 

unixtimes = [TDdat.AccelData.PacketRxUnixTime];
uxtimes = datetime(unixtimes'/1000,...
    'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');

temp  = [TDdat.AccelData.Header];
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
badpackets5 = [TDdat.AccelData.PacketGenTime]<=0;
badpackets5 = badpackets5';
% check to see if data type sequence always increases monotonically 
% note that it roles over after 255 packets (e.g. goes from 255 to 0). 
% I am getting rid of the first packet on purpose 
headertemp = TDdat.AccelData;
headers2 = [headertemp.Header];
dataTypeSequence = [headers2.dataTypeSequence];
dataTypeSequenceTemp = [headers2(1).dataTypeSequence dataTypeSequence];
badpackets6 = diff(dataTypeSequenceTemp')==0;


idxBadPackets = badPackets | badPackets2 | badPackets3 | badPackets4 | badpackets5 | badpackets6 ;
TDdat.AccelData = TDdat.AccelData(~idxBadPackets);



% find ambigous roleovers and remove them to make them not ambigous
% any more 
headertemp = TDdat.AccelData;
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
                 fprintf('\t ts1   - %s\t ts2   - %s\n',ts1,ts2);

    end
end
idx_bad_timetamps = [];
for b = 1:length(bad_timestamps)
    idx_bad_timetamps = [idx_bad_timetamps; find(timestamps_sec == bad_timestamps(b) )];
end
idxkeep = setxor(1:size(TDdat.AccelData,2),idx_bad_timetamps);

% repot on the gaps before and after the changes 
systemTicks = [headers2.systemTick];
for i = 1:length(idxGapsLargerThan6sec)
    fprintf('[%0.2d]\t previous = %s\t \t%d  current = %s\t %d\t \n',...
        i,timestamps_sec(idxGapsLargerThan6sec(i) - 1),systemTicks(idxGapsLargerThan6sec(i)-1)',...
        timestamps_sec(idxGapsLargerThan6sec(i)),systemTicks(idxGapsLargerThan6sec(i))')
end
TDdat.AccelData = TDdat.AccelData(idxkeep);


headertemp = TDdat.AccelData;
headers2 = [headertemp.Header];
temp = [headers2.timestamp];
systemTicks = [headers2.systemTick];
timestamps = [temp.seconds]; 
timestamps_sec = datetime(datevec(timestamps./86400 + datenum(2000,3,1,0,0,0)),...% medtronic time - LSB is seconds
    'TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS'); 
idxGapsLargerThan6sec = find(seconds(diff([timestamps_sec(1); timestamps_sec])) > 6);
for i = 1:length(idxGapsLargerThan6sec)
    fprintf('[%0.2d]\t previous = %s\t \t%d  current = %s\t %d\t \n',...
        i,timestamps_sec(idxGapsLargerThan6sec(i) - 1),systemTicks(idxGapsLargerThan6sec(i)-1)',...
        timestamps_sec(idxGapsLargerThan6sec(i)),systemTicks(idxGapsLargerThan6sec(i))')
end



% remove system ticks that are the same - this is essentially a duplicate
% packet, remove the second one 
% there is a small chance we are removing a roleover event (e.g. large
% packet loss, but even in these cases it would make it much easier to
% compute if we didn't have this packet). 
headertemp = TDdat.AccelData;
headers2 = [headertemp.Header];
systemTicks = [headers2.systemTick];
idxsametick =  diff(  [(systemTicks(1)-1) systemTicks] ) == 0;
TDdat.AccelData = TDdat.AccelData(~idxsametick);






%% deduce sampling rate 
srates = getSampleRateAcc([TDdat.AccelData.SampleRate]');

%% pre allocate memory 
% find out how many channels of data you have 
nchan = 3; % you always get 3 channels 
% find out how many rows you need to allocate 
tmp = [TDdat.AccelData.Header];
datasizes = [tmp.dataSize]';
% xxxxxxxxx
packetsizes = (datasizes/8); % divide by 8 for now, this may need to be fixed 
% xxxxxxxxx
nrows = sum(packetsizes);
outdat = zeros(nrows, nchan+2); % pre allocate memory 

%% loop on pacets to create out data with INS time and system tick 
% loop on packets and populate packets fields 
start = tic; 
curidx = 0; 
for p = 1:size(datasizes,1)
    rowidx = curidx+1:1:(packetsizes(p)+curidx);
    curidx = curidx + packetsizes(p); 
    packetidx = curidx;  % the time is always associated with the last sample in the packet 
    outdat(rowidx,1) = TDdat.AccelData(p).XSamples;
    varnames{1} = 'XSamples';
    outdat(rowidx,2) = TDdat.AccelData(p).YSamples;
    varnames{2} = 'YSamples';
    outdat(rowidx,3) = TDdat.AccelData(p).ZSamples;
    varnames{3} = 'ZSamples';
    outdat(packetidx,nchan+1) = TDdat.AccelData(p).Header.systemTick; 
    varnames{nchan+1} = 'systemTick'; 
    outdat(packetidx,nchan+2) = TDdat.AccelData(p).Header.timestamp.seconds; 
    varnames{nchan+2} = 'timestamp'; 
    outdat(packetidx,nchan+3) = TDdat.AccelData(p).PacketGenTime;
    varnames{nchan+3} = 'PacketGenTime'; 
    outdat(packetidx,nchan+4) = TDdat.AccelData(p).PacketRxUnixTime;
    varnames{nchan+4} = 'PacketRxUnixTime'; 
    outdat(packetidx,nchan+5) = packetsizes(p);
    varnames{nchan+5} = 'packetsizes'; 
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

end
