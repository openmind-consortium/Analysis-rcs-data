function parse_options_tests()
%
%   json_tests.toData.parse_options_tests

%{
json_tests.toData.parse_options_tests
%}

fprintf('Running toData.parse_options_tests()\n')


% typedef struct {
%     int max_numeric_collapse_depth;
%     int max_string_collape_depth;
%     int max_bool_collapse_depth;
%     bool column_major;
%     bool collapse_objects;
% } FullParseOptions;


fh2 = @json_tests.utils.runTest;
encode = @json_tests.utils.encodeJSON;

%When our writer changes, this will essentially do nothing.
p = @json_tests.utils.permuter;

%Numeric Testing
%-----------------------------------------------------

data = [];
fh2(1,encode(data),'','1d numeric array testing',p(data));
%-----------------
data = 1:30;
fh2(0,encode(data),'','1d numeric array testing',p(data));

end