function result = testExample(file_name_or_index,varargin)
%
%   result = json_tests.utils.testExample(file_name,varargin)
%
%   result = json_tests.utils.testExample(index,varargin)
%
%   Inputs
%   ------
%   file_name
%
%   Optional Inputs
%   ---------------
%   n_runs : default 10
%   method : default 1
%       1 - turtle json
%       2 - matlab
%   load_options = {};
%
%   Examples
%   --------
%   result = json_tests.utils.testExample('1.json','n_runs',3)
%
%
%   See Also
%   --------
%   json_tests.utils.time_example_file
%   json.utils.examples.FILE_LIST

result = json_tests.utils.time_example_file(file_name_or_index,varargin{:});

end