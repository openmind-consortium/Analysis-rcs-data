function str = join(cellstr_input,varargin)
%x Joins elements of a cellstr together into a single string
%
%   str = sl.cellstr.join(cellstr_input,varargin)
%
%   This function joins a cell array of strings together given a delimiter.   
%
%   Inputs:
%   -------
%   cellstr: 
%       A cell array of strings to combine.
%   
%   Optional Inputs:
%   ----------------
%   d: (default ',')
%       Delimiter string to use in combining strings
%   
%       To treat a delimiter as a literal escape the backlash with a
%       backlash. For example, this '\\t' will join strings with '\t'
%       instead of a tab. Percents should be escaped with a percent.
%   
%       The final delimiter is computed as by => final_delimeter = sprintf(d)
%   keep_rows : (default false)
%       If true, rows are escaped via \n instead of with the delimeter
%       
%   remove_empty: (default false)
%       If true empty values are removed.
%   
%   Examples:
%   ---------
%   cellstr_input = {'this' 'is' 'a' 'test'};
%   str = sl.cellstr.join(cellstr_input,'d',' ') %use space as delimiter
%   
%       str => 'this is a test'
%
%   Notes:
%   ------
%   In 2013a Matlab introduced strjoin() which does something similar
%   although the implementation was subpar.

in.d         = ',';
in.keep_rows = false;
in.remove_empty = false;
in = sl.in.processVarargin(in,varargin);

if isempty(cellstr_input)
    str = '';
elseif ~iscell(cellstr_input)
    error('Input to %s must be a cell array',mfilename)
else
    n_columns = size(cellstr_input,2);
    
    if in.keep_rows
       %We need to order by row, not by column, but then we still want the 
       %row vector for below
        P = cellstr_input';
        P = P(:)';
    else
        P = cellstr_input(:)';
    end
        if in.remove_empty
           P(cellfun('isempty',P)) = []; 
           if isempty(P)
              str = '';
              return
           end
        end

    P(2,:) = {sprintf(in.d)} ;  %Added on printing to handle things like \t and \n
    
    if in.keep_rows
       P(2,n_columns:n_columns:end) = {sprintf('\n')};
    end
    
    P{2,end} = [] ;
    str = sprintf('%s',P{:});
end