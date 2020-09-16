function numeric_array_tests()
%
%   json_tests.toData.numeric_array_tests
%
%   Some of these tests currently fail ...

%Order?????
%http://stackoverflow.com/questions/40833647/proper-translation-of-multi-dimensional-array-to-json-and-back/

fh2 = @json_tests.utils.runTest;
encode = @json_tests.utils.encodeJSON;

%When our writer changes, this will essentially do nothing.
p = @json_tests.utils.permuter;

fprintf('json_tests.toData.numeric_array_tests\n');

data = [];
fh2(1,encode(data),'','1d numeric array testing',p(data));
%-----------------
data = 1:30;
fh2(0,encode(data),'','1d numeric array testing',p(data));
%-----------------
data = reshape(1:20,[5 4]);
fh2(0,encode(data),'','2d numeric array testing',p(data));
%-----------------
data = reshape(1:24,[4,3,2]);
fh2(0,encode(data),'','3d numeric array testing',p(data));
%-----------------
data = reshape(1:20,[5 1 4]);
fh2(0,encode(data),'','3d numeric array with scalar middle',p(data));
%-----------------
data = {1:5 2:6 1:5 2:3};
data2 = cellfun(p,data,'un',0);
fh2(0,encode(data),'','cell of numbers',data2);
%--------------------------------------------------------------
for i = 0:9
    for j = 1:2
        if j == 1
            sign = 1;
        else
            sign = -1;
        end
        x = sign*i;
        %Not sure why jsonencode isn't creating an array only
        %converting the # to string, so adding an array
        fh2(0,encode([x 1]),'','Testing all leading numbers',[x; 1]);
    end
end
%-----------------

%JSON writers
%------------

%1)
%https://github.com/christianpanton/matlab-json
%- only supports 2d
%- writes array by memory order ...
%- s = tojson(data)

%2) 
%Matlab's JSON implementation
%- js = mexEncodeJSON(data)
%- writes so that innermost is highest dimension

end