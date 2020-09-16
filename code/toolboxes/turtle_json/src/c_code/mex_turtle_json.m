function mex_turtle_json(file_id,varargin)
%x Code to compile turtle_json
%
%   mex_turtle_json(*file_id)
%
%   This code has been designed with OpenMP and pointers to labels. I've
%   used GCC for both mac and windows.
%
%   Inputs
%   ------
%   file_id : default compile all
%       1 - turtle_json_mex.c
%       2 - json_info_to_data.c
%   
%   Examples
%   --------
%   mex_turtle_json(1,'no_timing',true)
%   mex_turtle_json(1,'no_timing',false)
%
%   TODO: Document file_id
%   TODO: Add verbose option
%
%   TODO: move clearing code to mex maker


%TODO: These are not really needed anymore ...
p = inputParser;
addOptional(p,'log_timing',true);
addOptional(p,'log_alloc',true);
parse(p,varargin{:});

in = p.Results;

%Compile Flags
%---------------
%in.no_timing = false;
%in = sl.in.processVarargin

if nargin == 0
   file_id = [];
end

%This file is using mex_maker:
%https://github.com/JimHokanson/mex_maker

%TODO: Ideally I would include the final code so that someone
%   could recompile by modifying the long form of the code
%   rather than using my experimental compile code

%Compiling of turtle_json_mex.c and associated files
%-------------------------------------------------------
if isempty(file_id) || file_id == 1
fprintf('Compiling turtle_json_mex.c\n');

%TODO: mex maker should do this ...
clear turtle_json_mex
%c = mex.compilers.gcc('./turtle_json_mex.c');
% c = mex.compilers.gcc('./turtle_json_mex.c',...
%     'files',{...
%     './turtle_json_main.c', ...
%     './turtle_json_mex_helpers.c'});
% 
c = mex.compilers.gcc('./turtle_json_mex.c',...
    'files',{...
    './turtle_json_main.c', ...
    './turtle_json_post_process.c', ...
    './turtle_json_mex_helpers.c', ...
    './turtle_json_pp_objects.c', ...
    './turtle_json_number_parsing.c'});
c.addLib('openmp');
c.addCompileFlags('-mavx');
if in.log_timing
    c.addCompileDefines({'LOG_TIME'});
end
if in.log_alloc
    c.addCompileDefines({'LOG_ALLOC'});
end
c.build();
end

%Compiling of json_info_to_data.c and associated files
%--------------------------------------------------------
if isempty(file_id) || file_id == 2
fprintf('Compiling json_info_to_data.c\n');
clear json_info_to_data
c = mex.compilers.gcc('./json_info_to_data.c',...
    'files',{...
    './json_info_to_data__arrays.c', ...
    './json_info_to_data__objects.c', ...
    './json_info_to_data__utils.c', ...
    './json_info_to_data__option_handling.c'});
c.build();
end

end
