function [in,extras] = processVarargin(in,v,varargin)
%processVarargin  Processes varargin and overrides defaults
%
%   Function to override default options.
%
%   [in,extras] = sl.in.processVarargin(in,v,varargin) 
%
%   Inputs:
%   -------
%   in : structure containing default values that may be overridden
%              by user inputs
%   v : cell or struct
%       The varargin value from the calling function.
%
%   varargin : see optional inputs, prop/value or structure with fields
%
%   Optional Inputs (specify via prop/value pairs OR struct)
%   --------------------------------------------------------
%   case_sensitive    : (default false)
%       If true values must have the same casing in order to match
%   allow_non_matches: (default false)
%       If true, then an option can be passed in and not match. Generally
%       this is indicative of a spelling error but occasionally it might 
%       indicate that the same options are being passed into multiple
%       functions and only some options match in some functions.
%   allow_spaces :
%   remove_null : (default false)
%       If files that are assigned as sl.in.NULL are removed.
%
%
%
%   allow_duplicates  : (default false) NOT YET IMPLEMENTED
%   partial_match     : (default false) NOT YET IMPLEMENTED
%
%   Outputs:
%   --------
%   extras: sl.in.process_varargin_result
%
%   Examples:
%   ---------
%   1)
%   function test(varargin)
%   in.a = 1
%   in.b = 2
%   in = processVarargin(in,varargin,'allow_duplicates',true)
%
%   Similar functions:
%   ------------------
%   http://www.mathworks.com/matlabcentral/fileexchange/22671
%   http://www.mathworks.com/matlabcentral/fileexchange/10670
%
%   Improvements:
%   -------------
%   1) For non-matched inputs, provide link to offending caller
%
%
%   See Also:
%   sl.in.tests.processVarargin



%Check to exit code quickly when it is not used ...
if isempty(v) && nargout == 1 && isempty(varargin)
    %Possible improvement
    %- provide code that allows this to return quicker if nargout == 2
    return
end

c.case_sensitive    = false;
% % % c.allow_duplicates  = false;
% % % c.partial_match     = false;
c.allow_non_matches = false;
c.allow_spaces      = true;
c.remove_null       = false;


%Update instructions on how to parse the optional inputs
%--------------------------------------------------------------------------
%This type of code would allow a bit more flexibility on how to process 
%the processing options if we ever decided they needed to be different
%
%
% c2 = c;
% c2.case_sensitive = false;
%
%NOTE: If we don't pass in any instructions on how to parse the data
%differently we can skip this step ...
if ~isempty(varargin)
    %Updates c based on varargin from user 
    %c = processVararginHelper(c,varargin,c2,1);
    c = processVararginHelper(c,varargin,c,true,1);
end

%Update optional inputs of calling function with this function's options now set
[in,extras] = processVararginHelper(in,v,c,false,nargout);

NULL = json.sl.in.NULL;

if c.remove_null
   fn = fieldnames(in);
   for iField = 1:length(fn)
      cur_field = fn{iField};
      if isequal(in.(cur_field),NULL)
         in = rmfield(in,cur_field); 
      end
   end
   
end

end



function [in,extras] = processVararginHelper(in,v,c,is_parsing_options,n_outputs)
%processVararginHelper
%
%   [in,extras] = processVararginHelper(in,v,c,is_parsing_options)
%
%   This function does the actual work. It is a separate function because 
%   we use this function to handle the options on how this function should
%   work for the user's inputs. We use the same approach for the processing
%   options as we do the user's inputs.
%
%   INPUTS
%   =======================================================================
%   in - (structure input)
%   v  - varargin input, might be structure or prop/value pairs
%   c  - options for processing 
%   is_parsing_options - specifies we are parsing the parsing options

populate_extras_flag = n_outputs > 1;

if populate_extras_flag
    extras = json.sl.in.process_varargin_result(in,v);
else
   extras = []; 
end

%Checking the optional inputs, either a structure or a prop/value cell
%array is allowed, or various forms of empty ...
if isempty(v)
    %do nothing
    parse_input = false;
elseif isstruct(v)
    %This case should generally not happen
    %It will if varargin is not used in the calling function
    parse_input = true;
elseif isstruct(v{1}) && length(v) == 1
    %Single structure was passed in as sole argument for varargin
    v = v{1};
    parse_input = true;
elseif iscell(v) && length(v) == 1 && isempty(v{1})
    %User passed in empty cell option to varargin instead of just ommitting input
    parse_input = false;
else
    parse_input = true;
    v = json.sl.in.propValuePairsToStruct(v,'allow_spaces',c.allow_spaces);
end

if ~parse_input
   return 
end

if populate_extras_flag
    extras.struct_mod_input = v;
end

%At this point we should have a structure ...
fn__new_values   = fieldnames(v);
fn__input_struct = fieldnames(in);

if populate_extras_flag
    extras.fn__new_values   = fn__new_values;
    extras.fn__input_struct = fn__input_struct;
end

%Matching location
%--------------------------------------------------------------------------
if c.case_sensitive
	[is_present,loc] = ismember(fn__new_values,fn__input_struct);
else
    [is_present,loc] = ismember(upper(fn__new_values),upper(fn__input_struct));
    %NOTE: I don't currently do a check here for uniqueness of matches ...
    %Could have many fields which case-insensitive are the same ...
end

if populate_extras_flag
    extras.is_present = is_present;
    extras.loc        = loc;
end

if ~all(is_present)
    if c.allow_non_matches
        %Lazy evaluation in result class
    else
        %NOTE: This would be improved by adding on the restrictions we used in mapping
        badVariables = fn__new_values(~is_present);
        error(['Bad variable names given in input structure: ' ...
            '\n--------------------------------- \n %s' ...
            ' \n--------------------------------------'],...
            json.sl.cellstr.join(badVariables,'d',','))
    end
end

%Actual assignment
%---------------------------------------------------------------
for i = 1:length(fn__new_values)
    if is_present(i)
    %NOTE: By using fn_i we ensure case matching
    in.(fn__input_struct{loc(i)}) = v.(fn__new_values{i});
    end
end

end
