function [ jsonStringOut ] = fixMalformedJson( jsonString, type )

jsonString = strrep(jsonString,'INF','Inf'); % change inproper infinite labels

numOpenSqua = size(find(jsonString=='['),2);
numOpenCurl = size(find(jsonString=='{'),2);
numCloseCurl = size(find(jsonString=='}'),2);
numCloseSqua = size(find(jsonString==']'),2);

%Perform JSON formating fix depending on the file type.
if numOpenSqua~=numCloseSqua && (contains(type,'Log') || contains(type,'Settings'))
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