function string = encodeJSON(data)

%This points to the current save function. I haven't yet written a saver
%so we'll use something else.


%jsonlab
%doesn't support > 2d arrays , writes to strange format
%   string = savejson('',data,'ArrayToStruct',0,'ParseLogical',true);

%leastrobino - doesn't support nd-arrays

%For newer Matlab
%json_encode(data)

%https://www.mathworks.com/matlabcentral/fileexchange/52244-thingspeak-support-toolbox/

string = jsonencode(data);


end