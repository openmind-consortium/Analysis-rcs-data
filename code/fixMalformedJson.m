function [ jsonStringOut ] = fixMalformedJson( jsonString, type, simple)

if nargin < 3
    simple=true;
end

jsonString = strrep(jsonString,'INF','Inf'); % change inproper infinite labels

numOpenSqua = size(find(jsonString=='['),2);
numOpenCurl = size(find(jsonString=='{'),2);
numCloseCurl = size(find(jsonString=='}'),2);
numCloseSqua = size(find(jsonString==']'),2);

%Perform JSON formating fix depending on the file type.
if simple
    if numOpenSqua~=numCloseSqua && numOpenCurl==numCloseCurl
        jsonStringOut = strcat(jsonString,']'); % add missing bracket to the end
        disp('Your .json file appears to be malformed, a fix was attempted in order to proceed with processing')
    elseif numOpenSqua~=numCloseSqua || numOpenCurl~=numCloseCurl
        %Put Fix here for adding in missing brackets at the end of the file.  Assume I want all curls, then all squares, and always end with }]
        jsonStringfix = strcat(repmat('}',1,(numOpenCurl-numCloseCurl-1)),repmat(']',1,(numOpenSqua-numCloseSqua-1)),'}]');
        jsonStringOut = strcat(jsonString,jsonStringfix);
        disp('Your .json file appears to be malformed, a fix was attempted in order to proceed with processing') 
    else
        jsonStringOut = jsonString;
    end
else
    disp('Simple fix failed, attempting to remove the last record')
    if contains(type,'Accel') || contains(type,'Power') || contains(type,'FFT') || contains(type,'TD')
        objs=split(jsonString,'{"Header"');
        info=objs{1};
        objs=objs(2:end-1);
        objs=strcat('{"Header"',objs);
        jsonStringOut=strjoin(objs);
        jsonStringOut=[info,jsonStringOut(1:end-1),']}]'];
    elseif contains(type,'Settings')
        objs=split(jsonString,'{"RecordInfo"');
        objs=objs(2:end-1);
        objs=strcat('{"RecordInfo"',objs);
        jsonStringOut=strjoin(objs);
        jsonStringOut=['[',jsonStringOut(1:end-1),']'];
    end
end