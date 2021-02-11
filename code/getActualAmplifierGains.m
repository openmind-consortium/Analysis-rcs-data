function AmpGains = getActualAmplifierGains(folderPath)
% gets the gain of the amplifier (Amp channel: 1,2,3,4)

% Load in DeviceSettings.json file
DeviceSettings = jsondecode(fixMalformedJson(fileread([folderPath filesep 'DeviceSettings.json']),'DeviceSettings'));

%%
% Fix format - Sometimes device settings is a struct or cell array
if isstruct(DeviceSettings)
    DeviceSettings = {DeviceSettings};
end
%%
recordCounter = 1; % Initalize counter for records in DeviceSetting
while recordCounter <= length(DeviceSettings)
    currentSettings = DeviceSettings{recordCounter};
    % Check until Factory Settings are found
    if isfield(currentSettings,'FactorySettings')
         if isfield(currentSettings.FactorySettings,'name')
            for ii=1:size(currentSettings.FactorySettings,1)
                nextName = currentSettings.FactorySettings(ii).name; 
                if strcmp(nextName,'cfg_config_data.dev.HT_sns_amp1_gain250_trim')
                    AmpGains.Amp1 = currentSettings.FactorySettings(ii).actualValue;
                elseif strcmp(nextName,'cfg_config_data.dev.HT_sns_amp2_gain250_trim')
                    AmpGains.Amp2 = currentSettings.FactorySettings(ii).actualValue;
                elseif strcmp(nextName,'cfg_config_data.dev.HT_sns_amp3_gain250_trim')
                    AmpGains.Amp3 = currentSettings.FactorySettings(ii).actualValue;
                elseif strcmp(nextName,'cfg_config_data.dev.HT_sns_amp4_gain250_trim')
                    AmpGains.Amp4 = currentSettings.FactorySettings(ii).actualValue;
                end
            end    
         end
    end
    recordCounter = recordCounter+1;
end
