function s = loadExample(id)
%
%   s = json.loadExample(partial_file_name)
%
%   s = json.loadExample(file_name)
%
%   s = json.loadExample(index)
%
%   Inputs
%   ------
%   file_name
%   partial_file_name
%   index : 
%
%   Examples
%   --------
%   s = json.loadExample('XJ30');
%   
%   s = json.loadExample('big.json');
%
%   s = json.loadExample(10);
%   
%   See Also
%   --------
%   json.utils.examples

%{
    
%}

file_path = json.utils.examples.getFilePath(id);

s = json.load(file_path);

end