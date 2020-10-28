function [newEntry, TDsettings] = addNewEntry_TimeDomainSettings(actionType,recNum,currentSettings,TDsettings)
%%
% Extract timeDomain settings data in order to add a new row to the
% TD_SettingsTable; ensures that all table fields are filled for each
% entry (otherwise warning will print)
%
%%
HostUnixTime = currentSettings.RecordInfo.HostUnixTime;

newEntry.action = actionType;
newEntry.recNum = recNum;
newEntry.time = HostUnixTime;

% Update TDsettings if present
if isfield(currentSettings,'SensingConfig') && isfield(currentSettings.SensingConfig,'timeDomainChannels')
    TDsettings = convertTDcodes(currentSettings.SensingConfig.timeDomainChannels);
end
for iChan = 1:4
    fieldName = sprintf('chan%d',iChan);
    newEntry.(fieldName) = TDsettings(iChan).chanFullStr;
end
newEntry.tdDataStruc = TDsettings;

end