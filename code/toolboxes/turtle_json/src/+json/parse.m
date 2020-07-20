function data = parse(json_string,varargin)
%x Return a fully parsed data structure from a string
%
%   data = json.parse(json_string,*data_options,*token_options);
%
%   data = json.parse(json_string,varargin);
%
%   data = json.parse(json_bytes,...);
%
%   This function is identical to json.load() except that it tells the
%   parser that the input string is a JSON string and not a file path.
%
%
%   Examples
%   --------
%   JSON_STR = '[[1,2,3],[4,5,6]]';
%   data = json.parse(JSON_STR,'column_major',false);
%
%
%   See Also:
%   ---------
%   json.load
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

%'raw_string',true
root = json.tokens.parse(json_string,token_options{:});

data = root.getParsedData(data_options{:});

end