function [Stim_SettingsOut] = createStimSettingsTable(folderPath)
%%
% Extract information from StimLog.json related to stimulation programs and
% settings
%
% Input: Folder path to Device* folder containing json files
% Output: Stim_SettingsOut
%%
% Load in StimLog.json file
stimLog = jsondecode(fixMalformedJson(fileread([folderPath filesep 'StimLog.json']),'StimLog'));

%%
stimTable = table();

numRecords = size(stimLog,1);
recordCounter = 1;
addEntry = 0;
entryNumber = 1;

% Loop through all records and update table with changes
while recordCounter <= numRecords
    currentRecord = stimLog{recordCounter};
    
    % All fields are present in first record, so fields get initialized
    HostUnixTime = currentRecord.RecordInfo.HostUnixTime;
    
    if isfield(currentRecord, 'therapyStatusData.therapyStatus')
        therapyStatus = currentRecord.therapyStatusData.therapyStatus;
    end
    if isfield(currentRecord, 'therapyStatusData.activeGroup')
        activeGroup = currentRecord.therapyStatusData.activeGroup;
    end
    
    %KS: Option 1 -- not flat structure --> CAN NOT USE isfield in this way
    if isfield(currentRecord, 'TherapyConfigGroup0')
        if isfield(currentRecord, 'TherapyConfigGroup0.ratePeriod')
            Group0.rateInHz = currentRecord.TherapyConfigGroup0.ratePeriod;
        end
        if isfield(currentRecord,'TherapyConfigGroup0.program0.AmplitudeInMilliamps')
            Group0.Program0.amplitudeInMilliamps = currentRecord.TherapyConfigGroup0.program0.AmplitudeInMilliamps;
        end
        if isfield(currentRecord,'TherapyConfigGroup0.program0.PulseWidthInMicroseconds')
            Group0.Program0.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup0.program0.PulseWidthInMicroseconds;
        end
        if isfield(currentRecord,'TherapyConfigGroup0.program1.AmplitudeInMilliamps')
            Group0.Program1.amplitudeInMilliamps = currentRecord.TherapyConfigGroup0.program1.AmplitudeInMilliamps;
        end
        if isfield(currentRecord,'TherapyConfigGroup0.program1.PulseWidthInMicroseconds')
            Group0.Program1.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup0.program1.PulseWidthInMicroseconds;
        end
        if isfield(currentRecord,'TherapyConfigGroup0.program2.AmplitudeInMilliamps')
            Group0.Program2.amplitudeInMilliamps = currentRecord.TherapyConfigGroup0.program2.AmplitudeInMilliamps;
        end
        if isfield(currentRecord,'TherapyConfigGroup0.program2.PulseWidthInMicroseconds')
            Group0.Program2.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup0.program2.PulseWidthInMicroseconds;
        end
        if isfield(currentRecord,'TherapyConfigGroup0.program3.AmplitudeInMilliamps')
            Group0.Program3.amplitudeInMilliamps = currentRecord.TherapyConfigGroup0.program3.AmplitudeInMilliamps;
        end
        if isfield(currentRecord,'TherapyConfigGroup0.program3.PulseWidthInMicroseconds')
            Group0.Program3.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup0.program3.PulseWidthInMicroseconds;
        end
        
        addEntry = 1;
    end
    
    % KS: Option 2 -- flatter structure
    if isfield(currentRecord, 'TherapyConfigGroup1')
        if isfield(currentRecord, 'TherapyConfigGroup1.ratePeriod')
            Group1.rateInHz = currentRecord.TherapyConfigGroup1.ratePeriod;
        end
        
        temp = table;
        temp.Group1_Program0_amplInMilliamps = currentRecord.TherapyConfigGroup1.program0.AmplitudeInMilliamps;
        temp.Group1_Program0_pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup1.program0.PulseWidthInMicroseconds;
        temp.Group1_Program1_amplitudeInMilliamps = currentRecord.TherapyConfigGroup1.program1.AmplitudeInMilliamps;
        temp.Group1_Program1_pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup1.program1.PulseWidthInMicroseconds;
        temp.Group1_Program2_amplitudeInMilliamps = currentRecord.TherapyConfigGroup1.program2.AmplitudeInMilliamps;
        temp.Group1_Program2_pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup1.program2.PulseWidthInMicroseconds;
        temp.Group1_Program3_amplitudeInMilliamps = currentRecord.TherapyConfigGroup1.program3.AmplitudeInMilliamps;
        temp.Group1_Program3_pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup1.program3.PulseWidthInMicroseconds;
        
        addEntry = 1;
    end
%     
%     if isfield(currentRecord, 'TherapyConfigGroup2')
%         if isfield(currentRecord, 'TherapyConfigGroup2.ratePeriod')
%             Group2.rateInHz = currentRecord.TherapyConfigGroup2.ratePeriod;
%         end
%         Group2.Program0.amplitudeInMilliamps = currentRecord.TherapyConfigGroup2.program0.AmplitudeInMilliamps;
%         Group2.Program0.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup2.program0.PulseWidthInMicroseconds;
%         Group2.Program1.amplitudeInMilliamps = currentRecord.TherapyConfigGroup2.program1.AmplitudeInMilliamps;
%         Group2.Program1.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup2.program1.PulseWidthInMicroseconds;
%         Group2.Program2.amplitudeInMilliamps = currentRecord.TherapyConfigGroup2.program2.AmplitudeInMilliamps;
%         Group2.Program2.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup2.program2.PulseWidthInMicroseconds;
%         Group2.Program3.amplitudeInMilliamps = currentRecord.TherapyConfigGroup2.program3.AmplitudeInMilliamps;
%         Group2.Program3.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup2.program3.PulseWidthInMicroseconds;
%         
%         addEntry = 1;
%     end
%     
%     if isfield(currentRecord, 'TherapyConfigGroup3')
%         if isfield(currentRecord, 'TherapyConfigGroup3.ratePeriod')
%             Group3.rateInHz = currentRecord.TherapyConfigGroup3.ratePeriod;
%         end
%         Group3.Program0.amplitudeInMilliamps = currentRecord.TherapyConfigGroup3.program0.AmplitudeInMilliamps;
%         Group3.Program0.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup3.program0.PulseWidthInMicroseconds;
%         Group3.Program1.amplitudeInMilliamps = currentRecord.TherapyConfigGroup3.program1.AmplitudeInMilliamps;
%         Group3.Program1.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup3.program1.PulseWidthInMicroseconds;
%         Group3.Program2.amplitudeInMilliamps = currentRecord.TherapyConfigGroup3.program2.AmplitudeInMilliamps;
%         Group3.Program2.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup3.program2.PulseWidthInMicroseconds;
%         Group3.Program3.amplitudeInMilliamps = currentRecord.TherapyConfigGroup3.program3.AmplitudeInMilliamps;
%         Group3.Program3.pulseWidthInMicroseconds = currentRecord.TherapyConfigGroup3.program3.PulseWidthInMicroseconds;
%         
%         addEntry = 1;
%     end
%     
    % Indicates that at least one of the TherapyConfigGroups was present in
    % currentRecord, implying record change. Thus add all current parameters to table
    if addEntry == 1
        
        stimTable.HostUnixTime(entryNumber) = HostUnixTime;
        stimTable.therapyStatus(entryNumber) = therapyStatus;
        stimTable.activeGroup(entryNumber) = activeGroup;
        stimTable.Group0{entryNumber} = Group0;
%         stimTable.Group1(entryNumber) = Group1;
%         stimTable.Group2(entryNumber) = Group2;
%         stimTable.Group3(entryNumber) = Group3;
        
        entryNumber = entryNumber + 1;
    end
    
    recordCounter = recordCounter + 1;
    addEntry = 0;
end


%% load stimulation config
% this code (re stim sweep part) assumes no change in stimulation from initial states
% this code will fail for stim sweeps or if any changes were made to
% stimilation
% need to fix this to include stim changes and when the occured to color
% data properly according to stim changes and when the took place for in
% clinic testing

therapyStatus = DeviceSettings{1}.GeneralData.therapyStatusData;
groups = [0 1 2 3]; % max of 4 groups
groupNames = {'A','B','C','D'};
stimState = table();
counter = 1;

for iGroup = 1:length(groups)
    fn = sprintf('TherapyConfigGroup%d',groups(iGroup));
    for iProgram = 1:4 % max of 4 programs per group
        if DeviceSettings{1}.TherapyConfigGroup0.programs(iProgram).isEnabled == 0
            stimState.group(counter) = groupNames{iGroup};
            if (iGroup-1) == therapyStatus.activeGroup
                stimState.activeGroup(counter) = 1;
                if therapyStatus.therapyStatus
                    stimState.stimulation_on(counter) = 1;
                else
                    stimState.stimulation_on(counter) = 0;
                end
            else
                stimState.activeGroup(counter) = 0;
                stimState.stimulation_on(counter) = 0;
            end
            
            stimState.program(counter) = iProgram;
            stimState.pulseWidth_mcrSec(counter) = DeviceSettings{1}.(fn).programs(iProgram).pulseWidthInMicroseconds;
            stimState.amplitude_mA(counter) = DeviceSettings{1}.(fn).programs(iProgram).amplitudeInMilliamps;
            stimState.rate_Hz(counter) = DeviceSettings{1}.(fn).rateInHz;
            electrodes = DeviceSettings{1}.(fn).programs(iProgram).electrodes.electrodes;
            elecString = '';
            for iElectrode = 1:length(electrodes)
                if electrodes(iElectrode).isOff == 0 % Electrode is active
                    % Determine if electrode is used
                    if iElectrode == 17 % This refers to the can
                        elecUsed = 'c';
                    else
                        elecUsed = num2str(iElectrode-1); % Electrodes are zero indexed
                    end
                    
                    % Determine if electrode is anode or cathode
                    if electrodes(iElectrode).electrodeType == 1
                        elecSign = '-'; % Anode
                    else
                        elecSign = '+'; % Cathode
                    end
                    elecSnippet = [elecSign elecUsed ' '];
                    elecString = [elecString elecSnippet];
                end
            end
            
            stimState.electrodes{counter} = elecString;
            counter = counter + 1;
        end
    end
end
if ~isempty(stimState)
    stimStatus = stimState(logical(stimState.activeGroup),:);
else
    stimStatus = [];
end
end