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
convertedLd.blankingDurationUponStateChagne = (FFTinterval/1000)*inputLd.blankingDurationUponStateChange;

% Fields which are in units of updateRate
convertedLd.onsetDuration = inputLd.onsetDuration * convertedLd.updateRate;
convertedLd.holdoffTime = inputLd.holdoffTime * convertedLd.updateRate;
convertedLd.terminationDuration =  inputLd.terminationDuration * convertedLd.updateRate;

% Fields which encode information per bit

% Detection inputs
detectionInputs = {};
binaryFlipped = fliplr(dec2bin(inputLd.detectionInputs,8)); % fliplr just to aid in parsing below 
for iBit = 1:length(binaryFlipped)
   if strcmp(binaryFlipped(iBit),'1')
       switch iBit
           case 1
               detectionInputs = [detectionInputs, 'A'];               
           case 2
               detectionInputs = [detectionInputs, 'B'];
           case 3
               detectionInputs = [detectionInputs, 'C'];
           case 4
               detectionInputs = [detectionInputs, 'D'];
           case 5
               detectionInputs = [detectionInputs, 'E'];
           case 6
               detectionInputs = [detectionInputs, 'F'];
           case 7
               detectionInputs = [detectionInputs, 'G'];
           case 8
               detectionInputs = [detectionInputs, 'H'];
       end
   end  
end
% If none of the above conditions exist, write 0 to field
if isempty(detectionInputs)
   detectionInputs = 0; 
end
convertedLd.detectionInputs = detectionInputs;
convertedLd.detectionInputs_BinaryCode = dec2bin(inputLd.detectionInputs,8);

% Detection Enable
detectionEnable = {};
binaryFlipped = fliplr(dec2bin(inputLd.detectionEnable,8)); % fliplr just to aid in parsing below 
for iBit = 1:length(binaryFlipped)
   if strcmp(binaryFlipped(iBit),'1')
       switch iBit
           case 1
               detectionEnable = [detectionEnable, 'A'];               
           case 2
               detectionEnable = [detectionEnable, 'B'];
           case 3
               detectionEnable = [detectionEnable, 'C'];
       end
   end
end
% If none of the above conditions exist, write 0 to field
if isempty(detectionEnable)
   detectionEnable = 0; 
end
convertedLd.detectionEnable = detectionEnable;

end