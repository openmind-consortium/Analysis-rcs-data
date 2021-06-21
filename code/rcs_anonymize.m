function rcs_anonymize(fn, varargin)
%% Function to scrub all raw .json files from PHI for easy sharing of raw data 
% This function scrubs  HI from RC+S raw data files. 
%
%% input: 
% 1. string to folder path that contains RC+S data with .json strings
% 2. optional - structure with following fields: 
%       params.replace = 0/1 (0 =  (default) create another folder, 1 = in place)
%         Example: 
%         rcs_anonymize('/path_to_folder/DeviceNPC700398H',struct('replace',0))
%         will create a folder: 
%         /path_to_folder/DeviceNPC_Anonymized/ 
%         all .jsons will have same name as origianl in that folder but PHI
%         will be replaced by "0" charachters. 
%
%
%% output: 
% a folder in the same directory with '_Anonymized' (default) or replace
% files with ann. version 
% 

if nargin == 2 
    params = varargin{1}; 
else
    params.replace = 0; 
end
%% load device settings to one large text file:
deviceSettingFn = fullfile(fn,'DeviceSettings.json');
outText = fileread(deviceSettingFn);


%TO DO XXX  need to put some options in here for each file type 
stringToAnnanoymze = 'DeviceId';
outText = annon_string(outText,stringToAnnanoymze);

stringToAnnanoymze = 'deviceSerialNumber';
outText = annon_string(outText,stringToAnnanoymze);

stringToAnnanoymze = 'hybridSerialNumber';
outText = annon_string(outText,stringToAnnanoymze);

stringToAnnanoymze = 'implantDate';
outText = annon_string(outText,stringToAnnanoymze);

stringToAnnanoymze = 'telMDeviceId';
outText = annon_string(outText,stringToAnnanoymze);

stringToAnnanoymze = 'BirthDateUnixTime';
outText = annon_string(outText,stringToAnnanoymze);

stringToAnnanoymze = 'PtmSerialNumber';
outText = annon_string(outText,stringToAnnanoymze);

stringToAnnanoymze = 'RtmSerialNumber';
outText = annon_string(outText,stringToAnnanoymze);

stringToAnnanoymze = '"SerialNumber"';
outText = annon_string(outText,stringToAnnanoymze);

stringToAnnanoymze = '"ID"';
outText = annon_string(outText,stringToAnnanoymze);



% write text
if ~params.replace 
    [pn,filename,ext] = fileparts(deviceSettingFn);
    [rootdir, parentFolder] = fileparts(pn); 
    parentFolder = 'DeviceNPC';
    newFolder = fullfile(rootdir,[parentFolder '_Anonymized']);
    if ~exist(newFolder,'dir')
        mkdir(newFolder);
    end
    deviceSettingFn = fullfile(newFolder,[filename ext]);
else
    newFolder = fn; 
end
fid = fopen(deviceSettingFn,'w+');
fwrite(fid,outText);
fclose(fid);

% loop on the rest of the files and look for DeviceId
filenames = {'AdaptiveLog','DiagnosticsLog','ErrorLog','EventLog','RawDataAccel',...
    'RawDataFFT','RawDataPower','RawDataTD','StimLog','TimeSync'};
for f = 1:length(filenames)
    fnuse = fullfile(fn,[ filenames{f} '.json']);
    outText = fileread(fnuse);
    if ~strcmp(outText,'[]')
        %XXX  need to put some options in here
        stringToAnnanoymze = 'DeviceId';
        outText = annon_string(outText,stringToAnnanoymze);
        % write text
        fnout = fullfile(newFolder,[ filenames{f} '.json']);
        fid = fopen(fnout,'w+');
        fwrite(fid,outText);
        fclose(fid);
    end
end


end




function outText = annon_string(text,stringToAnnanoymze)
outText = text;
switch stringToAnnanoymze
    case {'DeviceId','PtmSerialNumber','RtmSerialNumber'}
        % find the offending string
        offendingString = findDeviceID_string(text, stringToAnnanoymze);
    case {'deviceSerialNumber' , 'hybridSerialNumber', 'telMDeviceId'}
        offendingString = findDevice_serial_number(text, stringToAnnanoymze);
    case 'implantDate'
        offendingString = findImplantDate(text, stringToAnnanoymze);
    case 'BirthDateUnixTime'
        offendingString = findBirthDate(text, stringToAnnanoymze);
    case {'"SerialNumber"','"ID"'}
        offendingString = fineSerialNumber(text, stringToAnnanoymze);
        
end
% replace with dummy text same len
outText = strrep(text,offendingString,repmat('0',length(offendingString),1)');
end

function offendingString = findDeviceID_string(text, stringToAnnanoymze)
rawStrIdx = regexp(text,stringToAnnanoymze);
if ~isempty(rawStrIdx)
    % get text in first set of quotes
    rawText = text(rawStrIdx(1) : rawStrIdx(1) + 50);
    rawQuoteIdx = regexp(rawText,'"');
    rawText(rawQuoteIdx(2) : rawQuoteIdx(3));
    offendingString  = rawText(rawQuoteIdx(2)+1 : rawQuoteIdx(3)-1);
end
end

function offendingString = findDevice_serial_number(text, stringToAnnanoymze)
rawStrIdx = regexp(text,stringToAnnanoymze);
% get text in first set of quotes
rawText = text(rawStrIdx(1) : rawStrIdx(1) + 100);
rawQuoteIdx1 = regexp(rawText,'[');
rawQuoteIdx2 = regexp(rawText,']');
offendingString = rawText(rawQuoteIdx1 + 1: rawQuoteIdx2 -1 );
end

function offendingString = findImplantDate(text, stringToAnnanoymze)
rawStrIdx = regexp(text,stringToAnnanoymze);
% get text in first set of quotes
rawText = text(rawStrIdx(1) : rawStrIdx(1) + 50);
rawQuoteIdx1 = regexp(rawText,'{');
rawQuoteIdx2 = regexp(rawText,'}');
offendingString = rawText(rawQuoteIdx1 + 11: rawQuoteIdx2 -1 );
end

function offendingString = findBirthDate(text, stringToAnnanoymze)
rawStrIdx = regexp(text,stringToAnnanoymze);
% get text in first set of quotes
rawText = text(rawStrIdx(1) : rawStrIdx(1) + 50);
rawQuoteIdx1 = regexp(rawText,'":');
rawQuoteIdx2 = regexp(rawText,',"');
offendingString = rawText(rawQuoteIdx1(1) + 2: rawQuoteIdx2 -1 );
end

function offendingString = fineSerialNumber(text, stringToAnnanoymze)
rawStrIdx = regexp(text,stringToAnnanoymze);
% get text in first set of quotes
rawText = text(rawStrIdx(1) : rawStrIdx(1) + 50);
rawQuoteIdx1 = regexp(rawText,'":"');
rawQuoteIdx2 = regexp(rawText,'",');
offendingString = rawText(rawQuoteIdx1(1) + 3: rawQuoteIdx2 -1 );
end