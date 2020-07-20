function all_tests()
%
%   json_tests.all_tests();

%{
    json_tests.all_tests()
%}

json_tests.json_checker();

json_tests.toTokens.all_token_tests();

json_tests.toData.all_data_tests();

end