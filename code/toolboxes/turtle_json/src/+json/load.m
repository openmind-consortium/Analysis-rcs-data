function data = load(file_path,varargin)
%x Load json data from disk ...
%
%   Calling Forms
%   -----------------------------------------------------------------------
%   1) data and token options as separate inputs
%   s = json.load(file_path,*data_options,*token_options);
%
%   2) prop/value pairs as data options (see example) - no token options
%   s = json.load(file_path,varargin)
%
%
%   Token Options
%   -----------------------------------------------------------------------
%   For the most part these are only necessary to try and speed up parsing
%   or to limit memory usage.
%
%   n_tokens : double (default )
%       # of tokens expected in the file. Default is ...
%   n_keys : double (default )
%       # of keys expected in the file. 
%   n_strings : double
%       # of strings expected in the file.
%   n_numbers : double
%       # of numbers expected in the file.
%   chars_per_token - NYI
%       # of tokens to initially allocate based on the
%       length of the json string.
%
%   Data Options
%   -----------------------------------------------------------------------
%   These options affect how the JSON representation is converted to a
%   Matlab representation.
%
%   max_numeric_collapse_depth: default -1
%       A value of -1 means that arrays should be collapsed where possible.
%       Otherwise arrays are only made into a nd-array if this option value
%       meets or exceeds the dimensionality of the resulting array. For
%       example value of max_numeric_collapse_depth = 1 means that 1D
%       arrays will be returned but that 2D or higher arrays will be
%       returned as cell arrays.
%
%       JSON_STR = '[[1,2,3],[4,5,6]]';
%       1 => {[1,2,3],[4,5,6]}
%       2 =>   [1, 4;
%               2, 5;
%               3, 6]
%
%   max_string_collape_depth : default -1
%       Same as 'max_numeric_collapse_depth' but for strings. 
%
%   max_bool_collapse_depth : default -1
%       Same as 'max_numeric_collapse_depth' but for logicals. 
%
%   column_major : default true
%       If true, nd-arrays are read in column-major order,
%       otherwise as row major order. Note that Matlab uses column-major
%       ordering which means that parsing of the data is slightly more
%       efficient when column-major is used.
%
%       For example, consider the following
%       JSON_STR = '[[1,2,3],[4,5,6]]';
%
%       column-major: [1, 4;
%                      2, 5;
%                      3, 6]
%       row-major: [1,2,3;
%                   4,5,6]
%
%   collapse_objects : default true
%       If true, objects with the same properties (in the
%       same order) will be collapsed into a structure
%       array, otherwise all object arrays will be returned
%       as cell arrays of structures
%
%       For example, consider the following
%       JSON_STR = '[{"a":1,"b":2},{"a":3,"b":5}]';
%
%       collapse_objects =>  1×2 struct array with fields
%       no collapse => 1×2 cell array
%
%
%   Examples
%   --------
%   1) Mix of data processing and token options
%   s = json.load(file_path,{'column_major',false},{'n_tokens',1000});
%
%   2) All data processing options - no token options
%   data = json.load(file_path,'column_major',false,'collapse_objects',false);
%
%   See Also
%   --------
%   json.parse

data_options = {};
token_options = {};
if nargin > 1
    if ischar(varargin{1})
        data_options = varargin;
    else
       data_options = varargin{1};
       if isempty(data_options)
           data_options = {};
       end
       if nargin > 2
           token_options = varargin{2};
           if isempty(token_options)
              token_options = {};
           end
       end
    end 
end

mex_result = turtle_json_mex(file_path,token_options{:});

%Parse the resulting data
%Taken from json.objs.token.getParsedData - TODO: Need to implement
%options parsing in mex ...

if isempty(varargin)
    data = json_info_to_data(0,mex_result,1);
else
    %TODO: Move this into the c code just like we did 
    %for the parser ...
    in.max_numeric_collapse_depth = [];
    in.max_string_collapse_depth = [];
    in.max_bool_collapse_depth = [];
    in.column_major = [];
    in.collapse_objects = [];
    in = json.sl.in.processVarargin(in,data_options);
    data = json_info_to_data(7,mex_result,1,in);
end


%Old call for comparison - objects slow so we try and make calls directly
%... (new code above)
%root = json.tokens.load(file_path,token_options{:});
%data = root.getParsedData(data_options{:});



end