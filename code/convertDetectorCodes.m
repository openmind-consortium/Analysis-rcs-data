function [convertedLd] = convertDetectorCodes(inputLd,FFTinterval)
%%
% Takes information from Ld0 and Ld1 fields of DeviceSettings.DetectionConfig
% and converts codes into human readable information
%%
% Fields which are unchanged
convertedLd.biasTerm = inputLd.biasTerm;
convertedLd.features = inputLd.features;
convertedLd.fractionalFixedPointValue = inputLd.fractionalFixedPointValue;

% Fields which are in units of FFTinterval
convertedLd.updateRate = (FFTinterval/1000)*inputLd.updateRate;
convertedLd.blankingDurationUponStateChange = (FFTinterval/1000)*inputLd.blankingDurationUponStateChange;

% Fields which are in units of updateRate
convertedLd.onsetDuration = inputLd.onsetDuration * convertedLd.updateRate;
convertedLd.holdoffTime = inputLd.holdoffTime * convertedLd.updateRate;
convertedLd.terminationDuration =  inputLd.terminationDuration * convertedLd.updateRate;

% Fields which encode information per bit
% Detection inputs
convertedLd.detectionInputs_BinaryCode = dec2bin(inputLd.detectionInputs,8);

% Detection Enable
convertedLd.detectionEnable_BinaryCode = dec2bin(inputLd.detectionEnable,8);

end