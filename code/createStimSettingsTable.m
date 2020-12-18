function [stimLogSettings] = createStimSettingsTable(folderPath)
%%
% Extract information from StimLog.json related to stimulation programs and
% settings
%
% Input: Folder path to Device* folder containing json files
% Output: stimLogSettings
%%
% Load in StimLog.json file
stimLog = jsondecode(fixMalformedJson(fileread([folderPath filesep 'StimLog.json']),'StimLog'));

%%
stimLogSettings = table;

numRecords = size(stimLog,1);
recordCounter = 1;
addEntry = 0;
GroupA = struct;
GroupB = struct;
GroupC = struct;
GroupD = struct;

% Loop through all records and update table with changes
while recordCounter <= numRecords
    updatedParameters = {};
    currentSettings = stimLog{recordCounter};
    
    % All fields are present in first record, so fields get initialized
    if isfield(currentSettings, 'therapyStatusData') && isfield(currentSettings.therapyStatusData, 'therapyStatus')
        therapyStatus = currentSettings.therapyStatusData.therapyStatus;
        % If first record, create previousTherapyStatus but still add this
        % entry; otherwise compare to see if therapyStatus has changed
        if recordCounter == 1 || ~isequal(therapyStatus, updatedTherapyStatus)
            updatedTherapyStatus = therapyStatus;
            addEntry = 1;
            updatedParameters = [updatedParameters;'therapyStatus'];
        end
        
    end
    if isfield(currentSettings, 'therapyStatusData') && isfield(currentSettings.therapyStatusData, 'activeGroup')
        switch currentSettings.therapyStatusData.activeGroup
            case 0
                activeGroup = 'A';
            case 1
                activeGroup = 'B';
            case 2
                activeGroup = 'C';
            case 3
                activeGroup = 'D';
        end
        
        % If first record, create previousActiveGroup but still add this
        % entry; otherwise compare to see if activeGroup has changed
        if recordCounter == 1 || ~strcmp(activeGroup, updatedActiveGroup)
            updatedActiveGroup = activeGroup;
            addEntry = 1;
            updatedParameters = [updatedParameters;'activeGroup'];
        end
    end
    
    % If TherapyConfigGroup0 present in current record, collect values
    if isfield(currentSettings, 'TherapyConfigGroup0')
        currentGroupData = currentSettings.TherapyConfigGroup0;
        GroupA = getStimParameters(currentGroupData, GroupA);
        % Only mark to trigger adding new entry if first record or Group0 parameters have changed
        if recordCounter == 1 || ~isequal(GroupA, updatedGroupA)
            updatedGroupA = GroupA;
            addEntry = 1;
            updatedParameters = [updatedParameters;'GroupA'];
        end
    end
    
    % If TherapyConfigGroup1 present in current record, collect values
    if isfield(currentSettings, 'TherapyConfigGroup1')
        currentGroupData = currentSettings.TherapyConfigGroup1;
        GroupB = getStimParameters(currentGroupData, GroupB);
        % Only mark to trigger adding new entry if first record or Group1 parameters have changed
        if recordCounter == 1 || ~isequal(GroupB, updatedGroupB)
            updatedGroupB = GroupB;
            addEntry = 1;
            updatedParameters = [updatedParameters;'GroupB'];
        end
    end
    
    % If TherapyConfigGroup2 present in current record, collect values
    if isfield(currentSettings, 'TherapyConfigGroup2')
        currentGroupData = currentSettings.TherapyConfigGroup2;
        GroupC = getStimParameters(currentGroupData, GroupC);
        % Only mark to trigger adding new entry if first record or Group2 parameters have changed
        if recordCounter == 1 || ~isequal(GroupC, updatedGroupC)
            updatedGroupC = GroupC;
            addEntry = 1;
            updatedParameters = [updatedParameters;'GroupC'];
        end
    end
    
    % If TherapyConfigGroup3 present in current packet, collect values
    if isfield(currentSettings, 'TherapyConfigGroup3')
        currentGroupData = currentSettings.TherapyConfigGroup3;
        GroupD = getStimParameters(currentGroupData, GroupD);
        % Only mark to trigger adding new entry if first record or Group3 parameters have changed
        if recordCounter == 1 || ~isequal(GroupD, updatedGroupD)
            updatedGroupD = GroupD;
            addEntry = 1;
            updatedParameters = [updatedParameters;'GroupD'];
        end
    end
    
    % If any parameter was updated, add all current parameters to table as
    % a new entry
    if addEntry == 1
        [newEntry] = addNewEntry_StimSettings(currentSettings,updatedActiveGroup,...
            updatedTherapyStatus, updatedGroupA, updatedGroupB, updatedGroupC, updatedGroupD, updatedParameters);
        stimLogSettings = addRowToTable(newEntry,stimLogSettings);
    end
    addEntry = 0;
    recordCounter = recordCounter + 1;
end

end