function [outtable, srates] = createTimeDomainTable(TDdat)
%% Function to unravel TimeDomainData
% Input: a structure time domain data that is read from RawDataTD.json
% To transform *.json file into structure use deserializeJSON.m

% Extract sampling rates
srates = getSampleRate([TDdat.TimeDomainData.SampleRate]');

% Determine number of channels per packet
tdtmp = TDdat.TimeDomainData;
nChans=zeros(length(tdtmp),1);
for p = 1:length(tdtmp)
    nChans(p,1) = length(tdtmp(p).ChannelSamples);
end

% Determine number of samples per packet
tmp = [TDdat.TimeDomainData.Header];
dataSizes = [tmp.dataSize]';
packetSizes = (dataSizes./nChans)./2; % divide by 2 bcs data Size is number of bits in packet.

% Pre allocate matrix
maxNumChans = 4; % For simplicity, always initialize for 4 chans
nrows = sum(packetSizes);
allVarNames = {'key0','key1','key2','key3','systemTick','timestamp',...
    'samplerate','PacketGenTime','PacketRxUnixTime','packetsizes',...
    'dataTypeSequence'};
outdat = NaN(nrows, length(allVarNames)); % pre allocate memory

% Loop through packets to populate  fields
start = tic;
currentIndex = 0;

for p = 1:size(dataSizes,1)
    rowidx = currentIndex + 1:(packetSizes(p) + currentIndex);
    currentIndex = currentIndex + packetSizes(p);
    packetidx = currentIndex;  % the time is always associated with the last sample in the packet
    samples = TDdat.TimeDomainData(p).ChannelSamples;
    nchan =  nChans(p,1);
    for c = 1:size(samples,2)
        idxuse = samples(c).Key+1;% bcs keys (channels) are zero indexed
        outdat(rowidx,idxuse) = samples(c).Value;
    end
    outdat(packetidx,5) = TDdat.TimeDomainData(p).Header.systemTick;
    outdat(packetidx,6) = TDdat.TimeDomainData(p).Header.timestamp.seconds;
    outdat(packetidx,7) = srates(p);
    outdat(packetidx,8) = TDdat.TimeDomainData(p).PacketGenTime;
    outdat(packetidx,9) = TDdat.TimeDomainData(p).PacketRxUnixTime;
    outdat(packetidx,10) = packetSizes(p);
    outdat(packetidx,11) = TDdat.TimeDomainData(p).Header.dataTypeSequence;
end

%%
fprintf('finished unpacking into matrix in %.2f seconds\n',toc(start));
outtable = array2table(outdat);
clear outdat;
outtable.Properties.VariableNames = allVarNames;
outtable.Properties.VariableDescriptions{5} = ...
    'systemTick ? INS clock-driven tick counter, 16bits, LSB is 100microseconds, (highly accurate, high resolution, rolls over)';
outtable.Properties.VariableDescriptions{6} = ...
    'timestamp ? INS clock-driven time, LSB is seconds (highly accurate, low resolution, does not roll over)';
outtable.Properties.VariableDescriptions{7} = ...
    'sample rate for each packet, used in cases in which the sample rate is not conssistent through out session';
outtable.Properties.VariableDescriptions{8} = ...
    'API estimate of when the data packet was created on the INS within the PC clock domain. Estimate created by using results of latest latency check (one is done at system initialization, but can re-perform whenever you want) and time sync streaming. Potentially useful for syncing with other sensors or devices by bringing things into the PC clock domain, but is only accurate within 50ms give or take.';
outtable.Properties.VariableDescriptions{9} = ...
    'PC clock-driven time when the packet was received via Bluetooth, as accurate as a C# DateTime.now (10-20ms)';
end
