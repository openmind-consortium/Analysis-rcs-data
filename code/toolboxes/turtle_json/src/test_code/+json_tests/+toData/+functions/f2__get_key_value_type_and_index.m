function f2__get_key_value_type_and_index()

%{
json_tests.toData.functions.f2__get_key_value_type_and_index
%}

fh = @json.tokens.parse;
sdk = json.utils.to_data_mex;
passed_test = @(x) fprintf('Test %d passed as expected\n',x);

fprintf('Running "toData.functions.f2__get_key_value_type_and_index" tests\n');

%---------------------------------------------------
test_number = 1;
s = '{"data":1, "test":"cheese"}';
root = fh(s);
key_index = 1;
[key_value_type,md_index_1b] = sdk.f2__get_key_value_type_and_index(root.mex,1,key_index);
if key_value_type(1) ~= 5
    error('Expected numeric type for first key')
elseif md_index_1b ~= 3
    error('md_index for the value of the first key should be 3')
else
    passed_test(test_number)
end

%---------------------------------------------------
test_number = test_number + 1;
key_index = 2;
[key_value_type,md_index_1b] = sdk.f2__get_key_value_type_and_index(root.mex,1,key_index);
if key_value_type(1) ~= 4
    error('Expected string type for second key')
elseif md_index_1b ~= 5
    error('md_index for the value of the second key should be 5')
else
    passed_test(test_number)
end




end