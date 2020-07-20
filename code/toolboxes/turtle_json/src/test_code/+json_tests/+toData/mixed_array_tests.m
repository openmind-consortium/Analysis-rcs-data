function mixed_array_tests()
%
%   json_tests.toData.mixed_array_tests

%{
    json_tests.toData.mixed_array_tests
%}

fh2 = @json_tests.utils.runTest;
encode = @json_tests.utils.encodeJSON;

%runTest(reset_test_number,cur_test_string,error_id, memo, expected_value, post_test, post_test_error_msg)

%Tests to nd-array
%-------------------------------------------------------
%fh2(1,'[1,2,3,[],4,5]','','array in an array','',@h__keyboard,'asdfasdfsdf');
fh2(1,'[1,2,3,[],4,5]','','array in an array',{1,2,3,[],4,5});
fh2(0,'[1,2,3,[4],5,6]','','array in an array',{1,2,3,4,5,6});



%Old code, needs to be incorporated
%--------------------------------------------------------------------------
%{
%Tried nan, but this gets written as NaN by mexEncodeJSON
data = {'superstar' true false 15.3 ...
    1:10 {'asdf' 'anna' 'cbs'} [true false true false], ... %1d
    rand(5,2),{{'8 years','exactly'},{'Debbie','politics'}},false(10,2) ... %2d
    rand(3,4,2),{{{'young','cheese'},{'shape','need'}},{{'40','3'},{'20','mom'}}},false(4,5,2) ... %d
    }; 

expected_types = [-1 -1 -1 -1 ...
    0 1 2 ... %1d
    0 1 2 ... %2d
    0 1 2];

for iData = 1:length(data)
    %disp(iData);
    data2 = data(1:iData);
    js = tjSave(data2);
    %s = json.stringToTokens(js);
    temp = json.parse(js);
end
%}


end

function passed = h__keyboard(s)

keyboard

end