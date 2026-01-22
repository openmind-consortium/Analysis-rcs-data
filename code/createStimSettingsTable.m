function [stimLogSettings] = createStimSettingsTable(folderPath,stimMetaData)
%%
% Extract information from StimLog.json related to stimulation programs and
% settings
%
% Input: Folder path to Device* folder containing json files
% Output: stimLogSettings
%%
% Load in StimLog.json file
stimLog = deserializeJSON(fullfile(folderPath, 'StimLog.json'));
if isstruct(stimLog)
    stimLog = {stimLog};
end

%%
stimLogSettings = table;

numRecords = size(stimLog,2);
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
    
    % Update string for stimParams for all programs, given currently active
    % group
    if addEntry == 1
        switch updatedActiveGroup
            case 'A'
                currentGroup = updatedGroupA;
                anodes = stimMetaData.anodes(1,:);
                cathodes = stimMetaData.cathodes(1,:);
            case 'B'
                currentGroup = updatedGroupB;
                anodes = stimMetaData.anodes(2,:);
                cathodes = stimMetaData.cathodes(2,:);
            case 'C'
                currentGroup = updatedGroupC;
                anodes = stimMetaData.anodes(3,:);
                cathodes = stimMetaData.cathodes(3,:);
            case 'D'
                currentGroup = updatedGroupD;
                anodes = stimMetaData.anodes(4,:);
                cathodes = stimMetaData.cathodes(4,:);
        end
        
        for iProgram = 1:4
            anodeString = [];
            cathodeString = [];
            if currentGroup.ampInMilliamps(iProgram) == 8.5
                stimParamsString{iProgram} = 'Disabled';
            else
                for iAnode = 1:length(anodes{iProgram})
                   if ~isequal(anodes{iProgram}(iAnode),16)
                       anodeString = [anodeString sprintf('%.0f+',anodes{iProgram}(iAnode))];
                   elseif isequal(anodes{iProgram}(iAnode),16)
                       anodeString = [anodeString 'c+']; 
                   end
                end   
                for iCathode = 1:length(cathodes{iProgram})
                   if ~isequal(cathodes{iProgram}(iCathode),16)
                       cathodeString = [cathodeString sprintf('%.0f-',cathodes{iProgram}(iCathode))];
                   else isequal(cathodes{iProgram}(iCathode),16)
                       cathodeString = [cathodeString 'c-']; 
                   end
                end  
                
                stimParamsString{iProgram} = sprintf('%s%s, %.1fmA, %0.fus, %.1fHz',anodeString,...
                    cathodeString, currentGroup.ampInMilliamps(iProgram),...
                    currentGroup.pulseWidthInMicroseconds(iProgram),currentGroup.RateInHz );
            end
        end
    end
    
        % If any parameter was updated, add all current parameters to table as
    % a new entry
    if addEntry == 1
        [newEntry] = addNewEntry_StimSettings(currentSettings,updatedActiveGroup,...
            updatedTherapyStatus, updatedGroupA, updatedGroupB, updatedGroupC, updatedGroupD, stimParamsString, updatedParameters);
        stimLogSettings = addRowToTable(newEntry,stimLogSettings);
    end
    addEntry = 0;
    recordCounter = recordCounter + 1;
end

end
