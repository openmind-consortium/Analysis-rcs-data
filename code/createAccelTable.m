function [outtable, srates] = createAccelTable(jsonobj_Accel)
%% Function to unravel Accelerometer data
% Input: a structure of accelerometer data that is read from RawDataAccel.json
% To transform *.json file into structure use deserializeJSON.m
%%
% Extract sampling rate
srates = getSampleRateAcc([jsonobj_Accel.AccelData.SampleRate]');

%%
% Calculate number of samples
tmp = [jsonobj_Accel.AccelData.Header];
dataSizes = [tmp.dataSize]';
packetSizes = (dataSizes/8); % divide by 8 for now, this may need to be fixed
nrows = sum(packetSizes);

allVarNames = {'XSamples','YSamples','ZSamples','systemTick','timestamp','samplerate','PacketGenTime',...
    'PacketRxUnixTime','packetsizes','dataTypeSequence'};
% Pre allocate memory
outdat = zeros(nrows, length(allVarNames));

%%
% Loop through packets to populate fields
start = tic;
currentIndex = 0;
for p = 1:size(dataSizes,1)
    rowidx = currentIndex + 1:(packetSizes(p)+currentIndex);
    currentIndex = currentIndex + packetSizes(p);
    packetidx = currentIndex;  % the time is always associated with the last sample in the packet
    outdat(rowidx, 1) = jsonobj_Accel.AccelData(p).XSamples;
    outdat(rowidx, 2) = jsonobj_Accel.AccelData(p).YSamples;
    outdat(rowidx, 3) = jsonobj_Accel.AccelData(p).ZSamples;
    outdat(packetidx, 4) = jsonobj_Accel.AccelData(p).Header.systemTick;
    outdat(packetidx, 5) = jsonobj_Accel.AccelData(p).Header.timestamp.seconds;
    outdat(packetidx, 6) = srates(p);
    outdat(packetidx, 7) = jsonobj_Accel.AccelData(p).PacketGenTime;
    outdat(packetidx, 8) = jsonobj_Accel.AccelData(p).PacketRxUnixTime;
    outdat(packetidx, 9) = packetSizes(p);
    outdat(packetidx, 10) = jsonobj_Accel.AccelData(p).Header.dataTypeSequence;
end

%%
fprintf('finished unpacking into matrix in %.2f seconds\n',toc(start));
outtable = array2table(outdat);
clear outdat;
outtable.Properties.VariableNames = allVarNames;
outtable.Properties.VariableDescriptions{4} = ...
    'systemTick ? INS clock-driven tick counter, 16bits, LSB is 100microseconds, (highly accurate, high resolution, rolls over)';
outtable.Properties.VariableDescriptions{5} = ...
    'timestamp ? INS clock-driven time, LSB is seconds (highly accurate, low resolution, does not roll over)';

end
