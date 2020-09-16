function all_token_tests()
%
%   
%   json_tests.toTokens.all_token_tests()

%{
    json_tests.toTokens.all_token_tests()
%}

fprintf('Running json_tests.toTokens.all_tests\n');

json_tests.toTokens.input_options_testing();

json_tests.toTokens.array_tests();

json_tests.toTokens.number_tests();

json_tests.toTokens.object_tests();

json_tests.toTokens.string_tests();

end