function [newEntry,fftConfig] = addNewEntry_FFTSettings(actionType,recNum,currentSettings,TDsettings,fftConfig)
%%
% Extract FFT settings data in order to add a new row to the
% FFT_SettingsTable; ensures that all table fields are filled for each
% entry (otherwise warning will print)
%

%%
HostUnixTime = currentSettings.RecordInfo.HostUnixTime;

newEntry.action = actionType;
newEntry.recNum = recNum;
newEntry.time = HostUnixTime;

% Get fftConfig info if updated
if isfield(currentSettings,'SensingConfig') && isfield(currentSettings.SensingConfig,'fftConfig')
    fftConfig = convertFFTCodes(currentSettings.SensingConfig.fftConfig);
end 

newEntry.fftConfig = fftConfig;

% Get sample rate for each TD channel; all TD channels have
% same Fs (or is listed as NaN)
TDsampleRates = NaN(1,4);
for iChan = 1:4
    if isnumeric(TDsettings(iChan).sampleRate)
        TDsampleRates(iChan) = TDsettings(iChan).sampleRate;
    end
end
TDsampleRates = unique(TDsampleRates);
currentTDsampleRate = TDsampleRates(~isnan(TDsampleRates));
newEntry.TDsampleRates = currentTDsampleRate;

end