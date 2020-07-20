function string_array_tests()
%
%   json_tests.toData.string_array_tests

%{
json_tests.toData.string_array_tests
%}

fprintf('Running toData.string_array_tests()\n')


fh2 = @json_tests.utils.runTest;
encode = @json_tests.utils.encodeJSON;

data = {'hi' 'all'};
fh2(1,encode(data),'','simple cellstr',data');

%TODO: Encoder is not working properly ...
%data = {'hi' 'all'; 'this' 'test'};
%fh2(1,encode(data),'','1d logical array testing',data');
%Fail: ["hi","this","all","test"]

data = {{'hi' 'all'},{'this' 'test'}};
fh2(0,encode(data),'','nested strings V2',vertcat(data{:})');
%Good: [["hi","all"],["this","test"]]


data = {{{'test'}}};
fh2(0,encode(data),'','deep strings V1',{'test'});
%The output can't be reprsented accurately because Matlab collapses higher
%singleton dimensions

data = {{{{'test','cheese'}}}};
fh2(0,encode(data),'','deep strings V2',{'test';'cheese'}, {'column_major',true});

data = {{{{'test','cheese'}}}};
temp = cell(1,1,1,2);
temp{1} = 'test';
temp{2} = 'cheese';
fh2(0,encode(data),'','deep strings V2',temp, {'column_major',false});

wtf = json.parse(encode(data));


wtf = json.tokens.parse(encode(data));
wtf = json.parse(encode(data),'column_major',false);
wtf = json.parse(encode(data),'column_major',true);


end