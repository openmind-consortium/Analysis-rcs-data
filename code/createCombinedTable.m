function [combinedDataTable, debugTable] = createCombinedTable(dataStreams,unifiedDerivedTimes)
%%
% Using the shifted derivedTimes (newDerivedTimes), determine where rows of
% data fit in combinedDataTable.
%
%%
combinedDataTable = table();
combinedDataTable.DerivedTime = unifiedDerivedTimes;
numRows = length(unifiedDerivedTimes);
debugTable = table();
debugTable.DerivedTime = unifiedDerivedTimes;

for iStream = 1:length(dataStreams)
    if ~isempty(dataStreams{iStream})
        currentData = dataStreams{iStream};
        
        clear select_Indices
        if iStream == 1 % Time Domain
            [~, select_Indices] = ismember(currentData.DerivedTime,combinedDataTable.DerivedTime);
        else % all others
            [~, select_Indices] = ismember(currentData.newDerivedTime,combinedDataTable.DerivedTime);
        end
        
        switch iStream
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
                
                % Temp for debugging
                debugTable.TD_systemTick = NaN(numRows,1);
                debugTable.TD_timestamp = NaN(numRows,1);
                debugTable.TD_PacketGenTime = NaN(numRows,1);
                
                debugTable.TD_systemTick(select_Indices) = currentData.systemTick;
                debugTable.TD_timestamp(select_Indices) = currentData.timestamp;
                debugTable.TD_PacketGenTime(select_Indices) = currentData.PacketGenTime;
                
            case 2 % Accelerometer
                combinedDataTable.Accel_XSamples = NaN(numRows,1);
                combinedDataTable.Accel_YSamples = NaN(numRows,1);
                combinedDataTable.Accel_ZSamples = NaN(numRows,1);
                combinedDataTable.Accel_samplerate = NaN(numRows,1);
                
                combinedDataTable.Accel_XSamples(select_Indices) = currentData.XSamples;
                combinedDataTable.Accel_YSamples(select_Indices) = currentData.YSamples;
                combinedDataTable.Accel_ZSamples(select_Indices) = currentData.ZSamples;
                combinedDataTable.Accel_samplerate(select_Indices) = currentData.samplerate;
                
                % temp for debugging
                debugTable.Accel_systemTick = NaN(numRows,1);
                debugTable.Accel_timestamp = NaN(numRows,1);
                debugTable.Accel_PacketGenTime = NaN(numRows,1);
                
                debugTable.Accel_systemTick(select_Indices) = currentData.systemTick;
                debugTable.Accel_timestamp(select_Indices) = currentData.timestamp;
                debugTable.Accel_PacketGenTime(select_Indices) = currentData.PacketGenTime;
                
            case 3 % Power
                combinedDataTable.Power_ExternalValuesMask = NaN(numRows,1);
                combinedDataTable.Power_FftSize = NaN(numRows,1);
                combinedDataTable.Power_IsPowerChannelOverrange = NaN(numRows,1);
                combinedDataTable.Power_ValidDataMask = NaN(numRows,1);
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
                
                % temp for debugging
                debugTable.Power_systemTick = NaN(numRows,1);
                debugTable.Power_timestamp = NaN(numRows,1);
                debugTable.Power_PacketGenTime = NaN(numRows,1);
                
                debugTable.Power_systemTick(select_Indices) = currentData.systemTick;
                debugTable.Power_timestamp(select_Indices) = currentData.timestamp;
                debugTable.Power_PacketGenTime(select_Indices) = currentData.PacketGenTime;
                
            case 4 % FFT
                combinedDataTable.FFT_Channel = NaN(numRows,1);
                combinedDataTable.FFT_FftSize = NaN(numRows,1);
                combinedDataTable.FFT_FftOutput(:) = {NaN};
                combinedDataTable.FFT_Units(:) = {NaN};
                combinedDataTable.FFT_user1 = NaN(numRows,1);
                combinedDataTable.FFT_user2 = NaN(numRows,1);
                
                combinedDataTable.FFT_Channel(select_Indices) = currentData.Channel;
                combinedDataTable.FFT_FftSize(select_Indices) = currentData.FftSize;
                combinedDataTable.FFT_FftOutput(select_Indices) = currentData.FftOutput;
                combinedDataTable.FFT_Units(select_Indices) = currentData.Units;
                combinedDataTable.FFT_user1(select_Indices) = currentData.user1;
                combinedDataTable.FFT_user2(select_Indices) = currentData.user2;
                
                % temp for debugging
                debugTable.FFT_systemTick = NaN(numRows,1);
                debugTable.FFT_timestamp = NaN(numRows,1);
                debugTable.FFT_PacketGenTime = NaN(numRows,1);
                
                debugTable.FFT_systemTick(select_Indices) = currentData.systemTick;
                debugTable.FFT_timestamp(select_Indices) = currentData.timestamp;
                debugTable.FFT_PacketGenTime(select_Indices) = currentData.PacketGenTime;
                
            case 5 % Adaptive
                combinedDataTable.Adaptive_CurrentAdaptiveState = NaN(numRows,1);
                combinedDataTable.Adaptive_CurrentProgramAmplitudesInMilliamps(:) = {NaN};
                combinedDataTable.Adaptive_IsInHoldOffOnStartup = NaN(numRows,1);
                combinedDataTable.Adaptive_Ld0DetectionStatus = NaN(numRows,1);
                combinedDataTable.Adaptive_Ld1DetectionStatus = NaN(numRows,1);
                combinedDataTable.Adaptive_PreviousAdaptiveState = NaN(numRows,1);
                combinedDataTable.Adaptive_SensingStatus = NaN(numRows,1);
                combinedDataTable.Adaptive_StateEntryCount = NaN(numRows,1);
                combinedDataTable.Adaptive_StateTime = NaN(numRows,1);
                combinedDataTable.Adaptive_StimFlags = NaN(numRows,1);
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
                combinedDataTable.Adaptive_CurrentProgramAmplitudesInMilliamps(select_Indices) = currentData.CurrentProgramAmplitudesInMilliamps;
                combinedDataTable.Adaptive_IsInHoldOffOnStartup(select_Indices) = currentData.IsInHoldOffOnStartup;
                combinedDataTable.Adaptive_Ld0DetectionStatus(select_Indices) = currentData.Ld0DetectionStatus;
                combinedDataTable.Adaptive_Ld1DetectionStatus(select_Indices) = currentData.Ld1DetectionStatus;
                combinedDataTable.Adaptive_PreviousAdaptiveState(select_Indices) = currentData.PreviousAdaptiveState;
                combinedDataTable.Adaptive_SensingStatus(select_Indices) = currentData.SensingStatus;
                combinedDataTable.Adaptive_StateEntryCount(select_Indices) = currentData.StateEntryCount;
                combinedDataTable.Adaptive_StateTime(select_Indices) = currentData.StateTime;
                combinedDataTable.Adaptive_StimFlags(select_Indices) = currentData.StimFlags;
                combinedDataTable.Adaptive_StimRateInHz(select_Indices) = currentData.StimRateInHz;
                combinedDataTable.Adaptive_Ld0_featureInputs(select_Indices) = currentData.Ld0_featureInputs;
                combinedDataTable.Adaptive_Ld0_fixedDecimalPoint(select_Indices) = currentData.Ld0_fixedDecimalPoint;
                combinedDataTable.Adaptive_Ld0_highThreshold(select_Indices) = currentData.Ld0_highThreshold;
                combinedDataTable.Adaptive_Ld0_lowThreshold(select_Indices) = currentData.Ld0_lowThreshold;
                combinedDataTable.Adaptive_Ld0_output(select_Indices) = currentData.Ld0_output;
                combinedDataTable.Adaptive_Ld1_featureInputs(select_Indices)  = currentData.Ld1_featureInputs;
                combinedDataTable.Adaptive_Ld1_fixedDecimalPoint(select_Indices) = currentData.Ld1_fixedDecimalPoint;
                combinedDataTable.Adaptive_Ld1_highThreshold(select_Indices) = currentData.Ld1_highThreshold;
                combinedDataTable.Adaptive_Ld1_lowThreshold(select_Indices) = currentData.Ld1_lowThreshold;
                combinedDataTable.Adaptive_Ld1_output(select_Indices) = currentData.Ld1_output;
                
                % temp for debugging
                debugTable.Adaptive_systemTick = NaN(numRows,1);
                debugTable.Adaptive_timestamp = NaN(numRows,1);
                debugTable.Adaptive_PacketGenTime = NaN(numRows,1);
                
                debugTable.Adaptive_systemTick(select_Indices) = currentData.systemTick;
                debugTable.Adaptive_timestamp(select_Indices) = currentData.timestamp;
                debugTable.Adaptive_PacketGenTime(select_Indices) = currentData.PacketGenTime;    
        end
    end
end

end