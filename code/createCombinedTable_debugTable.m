function [debugTable] = createCombinedTable_debugTable(dataStreams,unifiedDerivedTimes, metaData)
%%
% Using the shifted derivedTimes (newDerivedTimes), determine where rows of
% data fit in combinedDataTable -- this function creates the debugTable,
% which contains original timing information, for verification.
%
%%
% Find first and last unifiedDerivedTime given choice of dataStreams
firstTime = [];
lastTime = [];
for iStream = 1:length(dataStreams)
    if ~isempty(dataStreams{iStream})
        if ismember('DerivedTime',dataStreams{iStream}.Properties.VariableNames)
            firstTime = [firstTime dataStreams{iStream}.DerivedTime(1)];
            lastTime = [lastTime dataStreams{iStream}.DerivedTime(end)];
        elseif ismember('newDerivedTime',dataStreams{iStream}.Properties.VariableNames)
            firstTime = [firstTime dataStreams{iStream}.newDerivedTime(1)];
            lastTime = [lastTime dataStreams{iStream}.newDerivedTime(end)];
        end
    end
end

% Reduce unifiedDerivedTimes to whatever subset needed for selected
% % dataStreams
unifiedDerivedTimes = unifiedDerivedTimes(unifiedDerivedTimes >= min(firstTime));
unifiedDerivedTimes = unifiedDerivedTimes(unifiedDerivedTimes <= max(lastTime));

numRows = length(unifiedDerivedTimes);
debugTable = table();
debugTable.DerivedTime = unifiedDerivedTimes;

for iStream = 1:length(dataStreams)
    if ~isempty(dataStreams{iStream})
        currentData = dataStreams{iStream};
        currentColumnNames = currentData.Properties.VariableNames;
        % Determine stream type
        if ismember('TimeDomainStream',currentColumnNames)
            streamType = 1; % Time Domain
        elseif ismember('AccelStream',currentColumnNames)
            streamType = 2; % Accelerometer
        elseif ismember('PowerStream',currentColumnNames)
            streamType = 3; % Power
        elseif ismember('FFTStream',currentColumnNames)
            streamType = 4; % FFT
        elseif ismember('AdaptiveStream',currentColumnNames)
            streamType = 5; % Adaptive
        end
        
        clear select_Indices
        if streamType == 1 % Time Domain
            [~, select_Indices] = ismember(currentData.DerivedTime,debugTable.DerivedTime);
        else % all others
            [~, select_Indices] = ismember(currentData.newDerivedTime,debugTable.DerivedTime);
        end
        
        switch streamType
            case 1 % Time Domain
                debugTable.TD_systemTick = NaN(numRows,1);
                debugTable.TD_timestamp = NaN(numRows,1);
                debugTable.TD_PacketGenTime = NaN(numRows,1);
                
                debugTable.TD_systemTick(select_Indices) = currentData.systemTick;
                debugTable.TD_timestamp(select_Indices) = currentData.timestamp;
                debugTable.TD_PacketGenTime(select_Indices) = currentData.PacketGenTime;
                
            case 2 % Accelerometer
                debugTable.Accel_systemTick = NaN(numRows,1);
                debugTable.Accel_timestamp = NaN(numRows,1);
                debugTable.Accel_PacketGenTime = NaN(numRows,1);
                
                debugTable.Accel_systemTick(select_Indices) = currentData.systemTick;
                debugTable.Accel_timestamp(select_Indices) = currentData.timestamp;
                debugTable.Accel_PacketGenTime(select_Indices) = currentData.PacketGenTime;
                
            case 3 % Power
                debugTable.Power_systemTick = NaN(numRows,1);
                debugTable.Power_timestamp = NaN(numRows,1);
                debugTable.Power_PacketGenTime = NaN(numRows,1);
                
                debugTable.Power_systemTick(select_Indices) = currentData.systemTick;
                debugTable.Power_timestamp(select_Indices) = currentData.timestamp;
                debugTable.Power_PacketGenTime(select_Indices) = currentData.PacketGenTime;
                
            case 4 % FFT
                debugTable.FFT_systemTick = NaN(numRows,1);
                debugTable.FFT_timestamp = NaN(numRows,1);
                debugTable.FFT_PacketGenTime = NaN(numRows,1);
                
                debugTable.FFT_systemTick(select_Indices) = currentData.systemTick;
                debugTable.FFT_timestamp(select_Indices) = currentData.timestamp;
                debugTable.FFT_PacketGenTime(select_Indices) = currentData.PacketGenTime;
                
            case 5 % Adaptive
                debugTable.Adaptive_systemTick = NaN(numRows,1);
                debugTable.Adaptive_timestamp = NaN(numRows,1);
                debugTable.Adaptive_PacketGenTime = NaN(numRows,1);
                
                debugTable.Adaptive_systemTick(select_Indices) = currentData.systemTick;
                debugTable.Adaptive_timestamp(select_Indices) = currentData.timestamp;
                debugTable.Adaptive_PacketGenTime(select_Indices) = currentData.PacketGenTime;
        end
    end
end

% Add column with human readable time to debugTable
timeFormat = sprintf('%+03.0f:00',metaData.UTCoffset);
localTime = datetime(debugTable.DerivedTime/1000,...
    'ConvertFrom','posixTime','TimeZone',timeFormat,'Format','dd-MMM-yyyy HH:mm:ss.SSS');
debugTable = addvars(debugTable,localTime,'Before',1);
end