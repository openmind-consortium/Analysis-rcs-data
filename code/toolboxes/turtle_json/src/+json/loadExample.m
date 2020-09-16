function s = loadExample(id)
%
%   Inputs
%   ------
%   file_name
%   partial_file_name
%   index

%{
    s = json.loadExample('XJ30');
%}

file_path = json.utils.examples.getFilePath(id);

s = json.load(file_path);

end