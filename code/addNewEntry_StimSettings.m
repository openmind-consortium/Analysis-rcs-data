function [newEntry] = addNewEntry_StimSettings(currentSettings, activeGroup,...
    therapyStatus, Group0, Group1, Group2, Group3, updatedParameters)
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
newEntry.Group0 = struct2table(Group0);
newEntry.Group1 = struct2table(Group1);
newEntry.Group2 = struct2table(Group2);
newEntry.Group3 = struct2table(Group3);
newEntry.updatedParameters = updatedParameters;

end