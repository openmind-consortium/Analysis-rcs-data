function struct_output = propValuePairsToStruct(cell_input,varargin)
%
%   struct_output = sl.in.propValuePairsToStruct(cell_input,varargin)
%
%
%   s = struct;
%   s.allow_spaces = true;
%   struct_output = sl.in.propValuePairsToStruct({'test',1,'test2',2},s)
%
%   TODO: Finish documentation

%TODO: Fix this to allow options ...

in.allow_spaces = false;
in.force_lower  = false;
in.force_upper  = false;

%The checking on this could improve ...
if isempty(varargin)
    %pass
elseif isstruct(varargin{1})
    fn = fieldnames(varargin);
    for iName = 1:length(fn)
       cur_name = fn{iName};
       in.(cur_name) = varargin.(cur_name);
    end
elseif iscell(varargin)
    for iName = 1:2:length(varargin)
       cur_name = varargin{iName};
       cur_value = varargin{iName+1};
       in.(cur_name) = cur_value;
    end
end

%in = sl.in.processVarargin(in,varargin);

is_str_mask = cellfun('isclass',cell_input,'char');

%Improvement:
%-------------------------------------------------
%Analyze calling information ...
%Provide stack trace for editing ...
%
%   Functions needed:
%   1) prototype of caller
%   2) calling format of parent
%   3) links to offending lines ...
%
%   NOTE: is_parsing_options would allow us to have different 
%   error messages ...
if ~all(is_str_mask(1:2:end))
    %TODO: See improvement above, provide a clickable link that does
    %dbup 3x (up to main, up to caller, up to caller's caller)
    error('Unexpected format for varargin, not all properties are strings')
end
if mod(length(cell_input),2) ~= 0
    error('Property/value pairs are not balanced, length of input: %d',length(cell_input))
end

if in.allow_spaces
   %strrep would be faster if we could guarantee
   %only single spaces :/
   cell_input(1:2:end) = regexprep(cell_input(1:2:end),'\s+','_');
end


cell_input = cell_input(:)'; %Ensure row vector
if in.force_lower
    struct_output = cell2struct(cell_input(2:2:end),lower(cell_input(1:2:end)),2);
elseif in.force_upper
    struct_output = cell2struct(cell_input(2:2:end),upper(cell_input(1:2:end)),2);
else
    struct_output = cell2struct(cell_input(2:2:end),cell_input(1:2:end),2);
end



end