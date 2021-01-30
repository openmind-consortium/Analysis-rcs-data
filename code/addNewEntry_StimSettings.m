function [newEntry] = addNewEntry_StimSettings(currentSettings, activeGroup,...
    therapyStatus, GroupA, GroupB, GroupC, GroupD, updatedParameters)
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
newEntry.updatedParameters = updatedParameters;

end