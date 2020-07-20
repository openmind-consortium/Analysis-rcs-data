function all_data_tests()
%
%   json_tests.toData.all_data_tests
%
%   Tries to parse all example files

fprintf('Running json_tests.toData.all_data_tests\n');

json_tests.toData.functions.all_tests();

json_tests.toData.logical_array_tests();

json_tests.toData.mixed_array_tests();

json_tests.toData.numeric_array_tests();

json_tests.toData.object_tests();

json_tests.toData.parse_options_tests();

json_tests.toData.string_array_tests();

end