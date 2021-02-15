function [combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData)
%%
% Using the shifted derivedTimes (newDerivedTimes), determine where rows of
% data fit in combinedDataTable.
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

combinedDataTable = table();
combinedDataTable.DerivedTime = unifiedDerivedTimes;
numRows = length(unifiedDerivedTimes);

for iStream = 1:length(dataStreams)
    if ~isempty(dataStreams{iStream})
        currentData = dataStreams{iStream};
        currentColumnNames = currentData.Properties.VariableNames;
        % Determine stream type
        if ismember('key0',currentColumnNames)
            streamType = 1; % Time Domain
        elseif ismember('XSamples',currentColumnNames)
            streamType = 2; % Accelerometer
        elseif ismember('Band1',currentColumnNames)
            streamType = 3; % Power
        elseif ismember('FftOutput',currentColumnNames)
            streamType = 4; % FFT
        elseif ismember('CurrentAdaptiveState',currentColumnNames)
            streamType = 5; % Adaptive
        end
        
        clear select_Indices
        if streamType == 1 % Time Domain
            [~, select_Indices] = ismember(currentData.DerivedTime,combinedDataTable.DerivedTime);
        else % all others
            [~, select_Indices] = ismember(currentData.newDerivedTime,combinedDataTable.DerivedTime);
        end
        
        switch streamType
            case 1 % Time Domain
                combinedDataTable.TD_key0 = NaN(numRows,1);
                combinedDataTable.TD_key1 = NaN(numRows,1);
                combinedDataTable.TD_key2 = NaN(numRows,1);
                combinedDataTable.TD_key3 = NaN(numRows,1);
                combinedDataTable.TD_samplerate = NaN(numRows,1);
                
                combinedDataTable.TD_key0(select_Indices) = currentData.key0;
                combinedDataTable.TD_key1(select_Indices) = currentData.key1;
                combinedDataTable.TD_key2(select_Indices) = currentData.key2;
                combinedDataTable.TD_key3(select_Indices) = currentData.key3;
                combinedDataTable.TD_samplerate(select_Indices) = currentData.samplerate;
                
            case 2 % Accelerometer
                combinedDataTable.Accel_XSamples = NaN(numRows,1);
                combinedDataTable.Accel_YSamples = NaN(numRows,1);
                combinedDataTable.Accel_ZSamples = NaN(numRows,1);
                combinedDataTable.Accel_samplerate = NaN(numRows,1);
                
                combinedDataTable.Accel_XSamples(select_Indices) = currentData.XSamples;
                combinedDataTable.Accel_YSamples(select_Indices) = currentData.YSamples;
                combinedDataTable.Accel_ZSamples(select_Indices) = currentData.ZSamples;
                combinedDataTable.Accel_samplerate(select_Indices) = currentData.samplerate;
                
            case 3 % Power
                combinedDataTable.Power_ExternalValuesMask(:) = {NaN};
                combinedDataTable.Power_FftSize = NaN(numRows,1);
                combinedDataTable.Power_IsPowerChannelOverrange = NaN(numRows,1);
                combinedDataTable.Power_ValidDataMask(:) = {NaN};
                combinedDataTable.Power_Band1 = NaN(numRows,1);
                combinedDataTable.Power_Band2 = NaN(numRows,1);
                combinedDataTable.Power_Band3 = NaN(numRows,1);
                combinedDataTable.Power_Band4 = NaN(numRows,1);
                combinedDataTable.Power_Band5 = NaN(numRows,1);
                combinedDataTable.Power_Band6 = NaN(numRows,1);
                combinedDataTable.Power_Band7 = NaN(numRows,1);
                combinedDataTable.Power_Band8 = NaN(numRows,1);
                
                combinedDataTable.Power_ExternalValuesMask(select_Indices) = currentData.ExternalValuesMask;
                combinedDataTable.Power_FftSize(select_Indices) = currentData.FftSize;
                combinedDataTable.Power_IsPowerChannelOverrange(select_Indices) = currentData.IsPowerChannelOverrange;
                combinedDataTable.Power_ValidDataMask(select_Indices) = currentData.ValidDataMask;
                combinedDataTable.Power_Band1(select_Indices) = currentData.Band1;
                combinedDataTable.Power_Band2(select_Indices) = currentData.Band2;
                combinedDataTable.Power_Band3(select_Indices) = currentData.Band3;
                combinedDataTable.Power_Band4(select_Indices) = currentData.Band4;
                combinedDataTable.Power_Band5(select_Indices) = currentData.Band5;
                combinedDataTable.Power_Band6(select_Indices) = currentData.Band6;
                combinedDataTable.Power_Band7(select_Indices) = currentData.Band7;
                combinedDataTable.Power_Band8(select_Indices) = currentData.Band8;
                
            case 4 % FFT
                combinedDataTable.FFT_Channel = NaN(numRows,1);
                combinedDataTable.FFT_FftSize = NaN(numRows,1);
                combinedDataTable.FFT_FftOutput(:) = {NaN};
                combinedDataTable.FFT_Units(:) = {NaN};
                
                combinedDataTable.FFT_Channel(select_Indices) = currentData.Channel;
                combinedDataTable.FFT_FftSize(select_Indices) = currentData.FftSize;
                combinedDataTable.FFT_FftOutput(select_Indices) = currentData.FftOutput;
                combinedDataTable.FFT_Units(select_Indices) = currentData.Units;
                
            case 5 % Adaptive
                combinedDataTable.Adaptive_CurrentAdaptiveState(:) = {NaN};
                combinedDataTable.Adaptive_CurrentProgramAmplitudesInMilliamps(:) = {NaN};
                combinedDataTable.Adaptive_IsInHoldOffOnStartup = NaN(numRows,1);
                combinedDataTable.Adaptive_Ld0DetectionStatus(:) = {NaN};
                combinedDataTable.Adaptive_Ld1DetectionStatus(:) = {NaN};
                combinedDataTable.Adaptive_PreviousAdaptiveState(:) = {NaN};
                combinedDataTable.Adaptive_SensingStatus(:) = {NaN};
                combinedDataTable.Adaptive_StateEntryCount = NaN(numRows,1);
                combinedDataTable.Adaptive_StateTime = NaN(numRows,1);
                combinedDataTable.Adaptive_StimFlags(:) = {NaN};
                combinedDataTable.Adaptive_StimRateInHz = NaN(numRows,1);
                combinedDataTable.Adaptive_Ld0_featureInputs(:) = {NaN};
                combinedDataTable.Adaptive_Ld0_fixedDecimalPoint = NaN(numRows,1);
                combinedDataTable.Adaptive_Ld0_highThreshold = NaN(numRows,1);
                combinedDataTable.Adaptive_Ld0_lowThreshold = NaN(numRows,1);
                combinedDataTable.Adaptive_Ld0_output = NaN(numRows,1);
                combinedDataTable.Adaptive_Ld1_featureInputs(:) = {NaN};
                combinedDataTable.Adaptive_Ld1_fixedDecimalPoint = NaN(numRows,1);
                combinedDataTable.Adaptive_Ld1_highThreshold = NaN(numRows,1);
                combinedDataTable.Adaptive_Ld1_lowThreshold = NaN(numRows,1);
                combinedDataTable.Adaptive_Ld1_output = NaN(numRows,1);
                
                combinedDataTable.Adaptive_CurrentAdaptiveState(select_Indices) = currentData.CurrentAdaptiveState;
                combinedDataTable.Adaptive_CurrentProgramAmplitudesInMilliamps(select_Indices) =...
                    mat2cell(currentData.CurrentProgramAmplitudesInMilliamps,ones(length(select_Indices),1));
                combinedDataTable.Adaptive_IsInHoldOffOnStartup(select_Indices) = currentData.IsInHoldOffOnStartup;
                combinedDataTable.Adaptive_Ld0DetectionStatus(select_Indices) = ...
                    mat2cell(currentData.Ld0DetectionStatus,ones(length(select_Indices),1));
                combinedDataTable.Adaptive_Ld1DetectionStatus(select_Indices) =...
                    mat2cell(currentData.Ld1DetectionStatus,ones(length(select_Indices),1));
                combinedDataTable.Adaptive_PreviousAdaptiveState(select_Indices) = currentData.PreviousAdaptiveState;
                combinedDataTable.Adaptive_SensingStatus(select_Indices) =...
                    mat2cell(currentData.SensingStatus,ones(length(select_Indices),1));
                combinedDataTable.Adaptive_StateEntryCount(select_Indices) = currentData.StateEntryCount;
                combinedDataTable.Adaptive_StateTime(select_Indices) = currentData.StateTime;
                combinedDataTable.Adaptive_StimFlags(select_Indices) =...
                    mat2cell(currentData.StimFlags,ones(length(select_Indices),1));
                combinedDataTable.Adaptive_StimRateInHz(select_Indices) = currentData.StimRateInHz;
                combinedDataTable.Adaptive_Ld0_featureInputs(select_Indices) =...
                    mat2cell(currentData.Ld0_featureInputs,ones(length(select_Indices),1));
                combinedDataTable.Adaptive_Ld0_fixedDecimalPoint(select_Indices) = currentData.Ld0_fixedDecimalPoint;
                combinedDataTable.Adaptive_Ld0_highThreshold(select_Indices) = currentData.Ld0_highThreshold;
                combinedDataTable.Adaptive_Ld0_lowThreshold(select_Indices) = currentData.Ld0_lowThreshold;
                combinedDataTable.Adaptive_Ld0_output(select_Indices) = currentData.Ld0_output;
                combinedDataTable.Adaptive_Ld1_featureInputs(select_Indices)  =...
                    mat2cell(currentData.Ld1_featureInputs,ones(length(select_Indices),1));
                combinedDataTable.Adaptive_Ld1_fixedDecimalPoint(select_Indices) = currentData.Ld1_fixedDecimalPoint;
                combinedDataTable.Adaptive_Ld1_highThreshold(select_Indices) = currentData.Ld1_highThreshold;
                combinedDataTable.Adaptive_Ld1_lowThreshold(select_Indices) = currentData.Ld1_lowThreshold;
                combinedDataTable.Adaptive_Ld1_output(select_Indices) = currentData.Ld1_output;
        end
    end
end

% Add column with human readable time to combinedDataTable
timeFormat = sprintf('%+03.0f:00',metaData.UTCoffset);
localTime = datetime(combinedDataTable.DerivedTime/1000,...
    'ConvertFrom','posixTime','TimeZone',timeFormat,'Format','dd-MMM-yyyy HH:mm:ss.SSS');
combinedDataTable = addvars(combinedDataTable,localTime,'Before',1);

end