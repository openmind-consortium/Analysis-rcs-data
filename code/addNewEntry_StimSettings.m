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
newEntry.GroupA = struct2table(GroupA);
newEntry.GroupB = struct2table(GroupB);
newEntry.GroupC = struct2table(GroupC);
newEntry.GroupD = struct2table(GroupD);
newEntry.updatedParameters = updatedParameters;

end