function [newEntry] = addNewEntry_StimSettings(currentSettings, activeGroup,...
    therapyStatus, GroupA, GroupB, GroupC, GroupD, stimParamsString, updatedParameters)
%%
% Collect data to add a new row to the
% Stim_SettingsTable; ensures that all table fields are filled for each
% entry (otherwise warning will print)
%
%%
HostUnixTime = currentSettings.RecordInfo.HostUnixTime;

newEntry.HostUnixTime = HostUnixTime;
newEntry.activeGroup = activeGroup;
newEntry.therapyStatus = therapyStatus;
newEntry.therapyStatusDescription = convertTherapyStatus(therapyStatus);
newEntry.GroupA = GroupA;
newEntry.GroupB = GroupB;
newEntry.GroupC = GroupC;
newEntry.GroupD = GroupD;
newEntry.stimParams_prog1 = stimParamsString{1};
newEntry.stimParams_prog2 = stimParamsString{2};
newEntry.stimParams_prog3 = stimParamsString{3};
newEntry.stimParams_prog4 = stimParamsString{4};
newEntry.updatedParameters = updatedParameters;

end