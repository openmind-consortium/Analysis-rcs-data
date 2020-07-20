function outdat = populateTimeStamp(outdat,srates,filename)
%% function to populate time stamps according to INS with Unix style time 
%% 
start = tic;
[pn,fn] = fileparts(filename);
fid = fopen(fullfile(pn,[fn '-Packet-Loss-Report.txt']),'w+'); 
idxpackets = find(outdat.timestamp~=0); 
timestamps = datetime(datevec(outdat.timestamp(idxpackets)./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds 
% find abnormal packet gaps and report some states 
idxlarge = find(seconds(diff(timestamps)) > 2^16/1e4);
fprintf(fid,'approximate recording length %s\n',timestamps(end)-timestamps(1));
fprintf(fid,'%d gaps larger than %.3f seconds found\n',sum(seconds(diff(timestamps)) > 2^16/1e4),2^16/1e4)

gapmode =  mode(timestamps( idxlarge+1) - timestamps( idxlarge));
gapmedian = median(timestamps( idxlarge+1) - timestamps( idxlarge));
maxgap = max(timestamps( idxlarge+1) - timestamps( idxlarge));
fprintf(fid,'gap mode %s, gap median %s, max gap %s\n',gapmode,gapmedian,maxgap);

pctlost = 1; 
medTimeExpanded = zeros(size(outdat,1),1);
packTimes = zeros(size(timestamps,1),1);
endTimes  = NaT(size(timestamps,1),1);
endTimes.Format = 'dd-MMM-yyyy HH:mm:ss.SSS';

usevector = 1; 
if usevector
%% attempt at vectorization 
%  set up a duration array 
endTimes  = NaT(size(timestamps,1), 1) - NaT(1);
endTimes.Format = 'hh:mm:ss.SSS'; % add microseconds 
% 1 figure out different isis 
isis = 1./srates;

% 1.5 start with gaps that are smaller than 6.553 seconds (actually smaller
% than 6 seconds since 6.553 can't be resolved, gaps between 6-7 are an
% edge case that were resolved in unravel data function 

% if gap is smaller than 6.55 seconds verify packet time with systemTick clock
% and increment from last end time
idxsmaller = [0 ; diff(timestamps) <= seconds(2^16/1e4)]; % add zero at start since using diff
% find out what value to give based on
% packet count
idxInNums = find(idxsmaller==1);
preIdxInNums = idxInNums-1;
difftime = outdat.systemTick(idxpackets(idxInNums)) - outdat.systemTick(idxpackets(preIdxInNums));
packtime = mod(difftime,2^16) / 1e4 ;% packet time in seconds
secondsToAdd = seconds(packtime ) ;
endTimes(idxInNums) = secondsToAdd;   
 
% 2. find gaps larger than 6.553 seconds and populate- this has to come
% after all the easy stuff 
idxlarger = [0 ; diff(timestamps) > seconds(2^16/1e4)];
% find out what value to give based on
% packet count
idxInNums = find(idxlarger==1); 
preIdxInNums = idxInNums-1; 
gapLenInSeconds = timestamps(idxInNums)-timestamps(preIdxInNums);
numberOfSixSecChunks = seconds(gapLenInSeconds)/(2^16/1e4);
systemTickPreviousPacket = outdat.systemTick(idxpackets(preIdxInNums));
% XXX 
% old version: 
% systemTickCurrentPacket = outdat.systemTick(idxpackets(idxInNums));
% exactGapTime = seconds(floor(numberOfSixSecChunks)* (2^16/1e4) - ...
%     systemTickPreviousPacket/1e4 + ...
%     systemTickCurrentPacket/1e4);
% endTimes(idxInNums) = exactGapTime;
% 
% new version 
systemTickCurrentPacket = outdat.systemTick(idxpackets(idxInNums));
difftimes = (systemTickCurrentPacket - systemTickPreviousPacket); 
exactGapTime = seconds(floor(numberOfSixSecChunks)* (2^16/1e4) + ...
                       (mod(difftimes,2^16) / 1e4) );
endTimes(idxInNums) = exactGapTime;
% XXX 
% get rid of the first packet;  
idxStartWithOutFirstPacket = find(outdat.packetsizes~=0,1)+1; 
outdat = outdat(idxStartWithOutFirstPacket:end,:); 
endTimes = endTimes(2:end); 
isis     = isis(2:end); 
srates   = srates(2:end); 
% set starting point based on computer time 
firstTimeIdx = find(outdat.PacketGenTime~=0,1);
timeOfLastSampleInFirstPacket = datetime(outdat.PacketRxUnixTime(firstTimeIdx)/1000,...
    'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
startTime = timeOfLastSampleInFirstPacket - endTimes(1); 
endTimesDate = startTime + cumsum(endTimes); 
%% my vectorization fails here - but almost all the way there

% populate each sample with a time stamp
derivedTimes = NaT(size(outdat,1),1); 
idxpackets   = find(outdat.packetsizes~=0);
numtpoints   = outdat.packetsizes(idxpackets); 
increments   = -seconds(1./srates); 
packstarts   = endTimesDate- seconds( (numtpoints-1)./srates );
derivedTimes.TimeZone = endTimesDate.TimeZone; 
derivedTimes.Format = endTimesDate.Format; 


% tic; 
% for p = 1:size(endTimesDate,1)
%     idxuse = idxpackets(p) : -1 : idxpackets(p) - (numtpoints(p)-1);
%     derivedTimes(idxuse) = endTimesDate(p) : increments(p) : packstarts(p);
% end
% toc; 
% try posix times 
posTimesOut = posixtime(derivedTimes);
endTimesPosTomes = posixtime(endTimesDate); 
packstartsPosTime = posixtime(packstarts); 
secsDouble  = seconds(increments); 
sratesout = zeros(size(posTimesOut,1),1);

tic; 
for p = 1:size(endTimesDate,1)
    idxuse = idxpackets(p) : -1 : idxpackets(p) - (numtpoints(p)-1);
    posTimesOut(idxuse) = endTimesPosTomes(p) : secsDouble(p) : packstartsPosTime(p);
    sratesout(idxuse) = repmat(srates(p),size(idxuse,2),1);
end
derivedTimes = datetime(posTimesOut,...
    'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
% fix smaple rate thing 
outdat.samplerate = sratesout;




ncol = size(outdat,2);
outdat.derivedTimes = derivedTimes;
outdat.Properties.VariableDescriptions{ncol+1} = 'derived time stamps from systemTick and timestamp variables'; 
fprintf('finished deriving time in %.2f\n',toc(start));
return ;
end


%%

for p = 1:length(idxpackets)
    srate = srates(p); 
    isi = 1/srate; 
    
    if p == 1 
        % for first packet, just assume medtronic time is correct 
        idxpopulate = idxpackets(p):-1:1;
        numpoints = length(idxpopulate);
        timeuse = outdat.timestamp(idxpackets(p));
        tmptime = datetime(datevec(timeuse./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds
        % cast to microseconds
        datstr = [datestr(tmptime) '.000'];
        endTime = datetime(datstr,'InputFormat','dd-MMM-yyyy HH:mm:ss.SSS'); % include microseconds
        endTime.Format = 'dd-MMM-yyyy HH:mm:ss.SSS';
        packTimes(p) = (numpoints-1)/srate;
        endTimes(p) = endTime; 
    else
        % for all other packets, implement folowing algorithem 
        idxpopulate = idxpackets(p):-1:idxpackets(p-1)+1;
        numpoints = length(idxpopulate);
        if timestamps(p)-timestamps(p-1) > seconds(2^16/1e4) % if gap is larger than 6.55 seconds don't incerment from last packet 
            % find out what value to give based on 
            % packet count 
            gapLenInSeconds = timestamps(p)-timestamps(p-1);
            numberOfSixSecChunks = seconds(gapLenInSeconds)/(2^16/1e4);
            systemTickPreviousPacket = outdat.systemTick(idxpackets(p-1));
            systemTickCurrentPacket = outdat.systemTick(idxpackets(p));
            exactGapTime = seconds(floor(numberOfSixSecChunks)*floor(2^16/1e4) - ...
                                    systemTickPreviousPacket/1e4 + ...
                                    systemTickCurrentPacket/1e4);
            
            timeuse = outdat.timestamp(idxpackets(p));
            tmptime = datetime(datevec(timeuse./86400 + datenum(2000,3,1,0,0,0))); % medtronic time - LSB is seconds
            % cast to microseconds
            datstr = [datestr(tmptime) '.000'];
            endTime = datetime(datstr,'InputFormat','dd-MMM-yyyy HH:mm:ss.SSS'); % include microseconds
            endTime.Format = 'dd-MMM-yyyy HH:mm:ss.SSS';
            
            endTimes(p) = endTime;
            %% tese new algorith XXXXXXX
            endTime = endTimes(p-1) + exactGapTime;
            endTimes(p) = endTime;
        else 
            % if gap is smaller than 6.55 seconds verify packet time with systemTick clock 
            % and increment from last end time 
            difftime = outdat.systemTick(idxpackets(p))-outdat.systemTick(idxpackets(p-1));
            if p == 2 
                packtime = mod(difftime,2^16) / 1e4 + 1/srate;% packet time in seconds 
            else
                packtime = mod(difftime,2^16) / 1e4 ;% packet time in seconds
            end
            packTimes(p) = packtime;
            
            if (packtime - numpoints/srate) <= isi 
                secondsToAdd = seconds(packtime ) ;
                % cast to microseconds
                endTime = endTimes(p-1) + secondsToAdd;
                endTimes(p) = endTime; 
            else 
                % we lost some some time, use systemTick to find out how much data was lost. 
                pctlen(pctlost)  = abs(packtime - numpoints/srate);
                % increment time use by difference between packtime and
                % numpoints / srate 
                pctlost = pctlost + 1; 
                secondsToAdd =  seconds(packtime );
                % cast to microseconds
                endTime = endTimes(p-1) + secondsToAdd;
                endTimes(p) = endTime;             
            end
        end
    end
   
    % populate each sample with a time stamp 
    outdat.samplerate(idxpopulate,1) = repmat(srates(p),1,size(idxpopulate,2));
    timevec = endTime: - seconds(1/srate): (endTime- seconds((numpoints-1)/srate)); 
    medTimeExpanded(idxpopulate) = datenum(timevec); % use Matlab datenum, at end cast back to str 
end
%% add data to packet loss report
if exist('pctlen','var') % in short recording you may not have any packet loss
    fprintf(fid,'\n\n');
    fprintf(fid,'%d packet loss events under 6.55 seoncds occured \n', length(pctlen));
    fprintf(fid,'%.4f seconds average packet loss  \n', mean(pctlen));
    fprintf(fid,'%.4f seconds mode packet loss \n', mode(pctlen));
    fprintf(fid,'%.4f seconds median packet loss  \n', median(pctlen));
    fprintf(fid,'%.4f seconds max packet loss \n', max(pctlen));
    fprintf(fid,'%.4f seconds min packet loss \n', min(pctlen));
end
%% convert derived data to string and add to table 
% medTimeStr = datetime(datevec(medTimeExpanded),'TimeZone','America/Chicago');
medTimeStr = datetime(datevec(medTimeExpanded),'TimeZone','America/Los_Angeles');
medTimeStr.Format = 'dd-MMM-yyyy HH:mm:ss.SSS';
ncol = size(outdat,2);
outdat.derivedTimes = medTimeStr;
outdat.Properties.VariableDescriptions{ncol+1} = 'derived time stamps from systemTick and timestamp variables'; 
fprintf('finished deriving time in %.2f\n',toc(start));
%% left over 
%XXXXXXXXX
% XXX What is time zone????? 
% XXXXXXXX 

% uxtime = [TDdat.TimeDomainData.PacketRxUnixTime];
% each increment of of systemTime by +1 is extra 0.1 mili seconds 

% dtnums = datenum(uxtime./86400./1000 + datenum(1970,1,1))';
% datetime(datevec( dtnums(end)),'TimeZone','America/Chicago'); 

% time - PacketGenTime is time in miliseconds backstamped to where it in UTC since Jan 1 1970. 
% this is when it hit the bluetooth on computer 
% systemTick ? INS clock-driven tick counter, 16bits, LSB is 100microseconds, (highly accurate, high resolution, rolls over)
% timestamp ? INS clock-driven time, LSB is seconds (highly accurate, low resolution, does not roll over)
% PacketGenTime ? API estimate of when the data packet was created on the INS within the PC clock domain. Estimate created by using results of latest latency check (one is done at system initialization, but can re-perform whenever you want) and time sync streaming. Potentially useful for syncing with other sensors or devices by bringing things into the PC clock domain, but is only accurate within 50ms give or take.
% PacketRxUnixTime ? PC clock-driven time when the packet was received via Bluetooth, as accurate as a C# DateTime.now (10-20ms)
% SampleRate ? defined in HTML doc as enum TdSampleRates: 0x00 is 250Hz, 0x01 is 500Hz, 0x02 is 1000Hz, 0xF0 is disabled



%% medtrnic time timestamp
% tsmps = outdat.timestamp(outdat.timestamp~=0);
% mdtnums= datenum(tsmps./86400 + datenum(2000,3,1,0,0,0));
% datetime(datevec( mdtnums(end)),'TimeZone','America/Chicago');
end