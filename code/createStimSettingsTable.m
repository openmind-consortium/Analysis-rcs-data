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
Group0 = struct;
Group1 = struct;
Group2 = struct;
Group3 = struct;

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
        activeGroup = currentSettings.therapyStatusData.activeGroup;
        % If first record, create previousActiveGroup but still add this
        % entry; otherwise compare to see if activeGroup has changed
        if recordCounter == 1 || ~isequal(activeGroup, updatedActiveGroup)
            updatedActiveGroup = activeGroup;
            addEntry = 1;
            updatedParameters = [updatedParameters;'activeGroup'];
        end
    end
    
    % If TherapyConfigGroup0 present in current record, collect values
    if isfield(currentSettings, 'TherapyConfigGroup0')
        currentGroupData = currentSettings.TherapyConfigGroup0;
        Group0 = getStimParameters(currentGroupData, Group0);
        % Only mark to trigger adding new entry if first record or Group0 parameters have changed
        if recordCounter == 1 || ~isequal(Group0, updatedGroup0)
            updatedGroup0 = Group0;
            addEntry = 1;
            updatedParameters = [updatedParameters;'Group0'];
        end
    end
    
    % If TherapyConfigGroup1 present in current record, collect values
    if isfield(currentSettings, 'TherapyConfigGroup1')
        currentGroupData = currentSettings.TherapyConfigGroup1;
        Group1 = getStimParameters(currentGroupData, Group1);
        % Only mark to trigger adding new entry if first record or Group1 parameters have changed
        if recordCounter == 1 || ~isequal(Group1, updatedGroup1)
            updatedGroup1 = Group1;
            addEntry = 1;
            updatedParameters = [updatedParameters;'Group1'];
        end
    end
    
    % If TherapyConfigGroup2 present in current record, collect values
    if isfield(currentSettings, 'TherapyConfigGroup2')
        currentGroupData = currentSettings.TherapyConfigGroup2;
        Group2 = getStimParameters(currentGroupData, Group2);
        % Only mark to trigger adding new entry if first record or Group2 parameters have changed
        if recordCounter == 1 || ~isequal(Group2, updatedGroup2)
            updatedGroup2 = Group2;
            addEntry = 1;
            updatedParameters = [updatedParameters;'Group2'];
        end
    end
    
    % If TherapyConfigGroup3 present in current packet, collect values
    if isfield(currentSettings, 'TherapyConfigGroup3')
        currentGroupData = currentSettings.TherapyConfigGroup3;
        Group3 = getStimParameters(currentGroupData, Group3);
        % Only mark to trigger adding new entry if first record or Group3 parameters have changed
        if recordCounter == 1 || ~isequal(Group3, updatedGroup3)
            updatedGroup3 = Group3;
            addEntry = 1;
            updatedParameters = [updatedParameters;'Group3'];
        end
    end
    
    % If any parameter was updated, add all current parameters to table as
    % a new entry
    if addEntry == 1
        [newEntry] = addNewEntry_StimSettings(currentSettings,updatedActiveGroup,...
            updatedTherapyStatus, updatedGroup0, updatedGroup1, updatedGroup2, updatedGroup3, updatedParameters);
        stimLogSettings = addRowToTable(newEntry,stimLogSettings);
    end
    addEntry = 0;
    recordCounter = recordCounter + 1;
end

end