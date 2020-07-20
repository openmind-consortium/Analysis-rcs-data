function f7__full_options_parse()
%
%   json_tests.toData.functions.f7__full_options_parse


%Options
%-------------------
%   max_numeric_collapse_depth: default -1
%   max_string_collape_depth : default -1
%   max_bool_collapse_depth : default -1
%   column_major : default true
%   collapse_objects : default true

missed_error = @ ()error('turtle_json:f7__full_options_parse','error not thrown as expected');

fprintf('Running "toData.functions.f7__full_options_parse" tests\n');

%Invalid option testing
%-----------------------------------------------------------------------
%value should be Numeric not boolean ...
JSON_STR = '[[1,2,3],[4,5,6]]';
try
    data = json.parse(JSON_STR,'max_numeric_collapse_depth',true);
    missed_error();
catch ME
    %TODO: check if error is correct
end

%TODO: This should throw an error
JSON_STR = '[[1,2,3],[4,5,6]]';
try
    data = json.parse(JSON_STR,'bad_option',1);
    missed_error();
catch ME
    %TODO: check if error is correct    
end


%Column Majors for numbers
%-----------------------------------------------------------------------
JSON_STR = '[1,2,3]';
data = json.parse(JSON_STR,'column_major',false);
if ~isequal(data,1:3)
    error('Failed to properly parse 1d-array using row-major order');
end

JSON_STR = '[1,2,3]';
data = json.parse(JSON_STR,'column_major',true);
if ~isequal(data,(1:3)')
    error('Failed to properly parse 1d-array using column-major order');
end

JSON_STR = '[[1,2,3],[4,5,6]]';
data = json.parse(JSON_STR,'column_major',false);
if ~isequal(data,[1,2,3;4,5,6])
    error('Failed to properly parse nd-array using row-major order');
end

JSON_STR = '[[1,2,3],[4,5,6]]';
data = json.parse(JSON_STR,'column_major',true);
if ~isequal(data,[1,4;2,5;3,6])
    error('Failed to properly parse nd-array using column-major order');
end

%Max numeric collapse depth
%------------------------------------------------------------------------
JSON_STR = '[[1,2,3],[4,5,6]]';
data = json.parse(JSON_STR,'max_numeric_collapse_depth',0);
d2 = {{1 2 3},{4 5 6}};
if ~isequal(data,d2)
    error('Failed to properly parse nd-array using max_numeric_collapse_depth = 0');
end

JSON_STR = '[1,2,"test",[[1,2,3],[4,5,6]],9]';
data = json.parse(JSON_STR,'max_numeric_collapse_depth',0);
d2 = {1,2,'test',{{1 2 3},{4 5 6}},9};
if ~isequal(data,d2)
    error('Failed to properly array with nd-array using max_numeric_collapse_depth = 0');
end

JSON_STR = '[[1,2,3],[4,5,6]]';
data = json.parse(JSON_STR,'max_numeric_collapse_depth',1);
d2 = {[1;2;3],[4;5;6]};
if ~isequal(data,d2)
    error('Failed to properly parse nd-array using max_numeric_collapse_depth = 1');
end

JSON_STR = '[[1,2,3],[4,5,6]]';
data = json.parse(JSON_STR,'max_numeric_collapse_depth',2);
d2 = [1,4;2,5;3,6];
if ~isequal(data,d2)
    error('Failed to properly parse nd-array using max_numeric_collapse_depth = 2');
end

%Max string collapse depth & column order for strings
%--------------------------------------------------------------------------
JSON_STR = '[["a","b","c"],["d","e","f"]]';

%Note this doesn't make much sense because strings are stored in cells ...
data = json.parse(JSON_STR,'max_string_collapse_depth',0);
d2 = {{'a';'b';'c'},{'d';'e';'f'}};
if ~isequal(data,d2)
    error('Failed to properly parse nd-array using max_string_collapse_depth = 0');    
end

data = json.parse(JSON_STR,'max_string_collapse_depth',1);
if ~isequal(data,d2)
    error('Failed to properly parse nd-array using max_string_collapse_depth = 1');    
end

data = json.parse(JSON_STR,'max_string_collapse_depth',2);
d2 = [{'a';'b';'c'},{'d';'e';'f'}];
if ~isequal(data,d2)
    error('Failed to properly parse nd-array using max_string_collapse_depth = 2');    
end

data = json.parse(JSON_STR,'column_major',false);
d2 = [{'a' 'b' 'c'};{'d' 'e' 'f'}];
if ~isequal(data,d2)
    error('Failed to properly parse string nd-array using column_major = false');    
end

%Max logical collapse depth & column order for logicals
%--------------------------------------------------------------------------
JSON_STR = '[[true,false,true],[false,true,false]]';

%This is incorrect ...
data = json.parse(JSON_STR,'max_bool_collapse_depth',0);
d2 = {{true false true},{false true false}};
if ~isequal(data,d2)
    error('Failed to properly parse nd-array using max_bool_collapse_depth = 0');    
end

data = json.parse(JSON_STR,'max_bool_collapse_depth',1);
d2 = {[true; false;true],[false;true;false]};
if ~isequal(data,d2)
    error('Failed to properly parse nd-array using max_bool_collapse_depth = 1');    
end

data = json.parse(JSON_STR,'max_string_collapse_depth',2);
d2 = [true false; false true; true false];
if ~isequal(data,d2)
    error('Failed to properly parse nd-array using max_bool_collapse_depth = 2');    
end

data = json.parse(JSON_STR,'column_major',false);
d2 = [true false true; false true false];
if ~isequal(data,d2)
    error('Failed to properly parse string nd-array using column_major = false');    
end

%Collapse Objects
%--------------------------------------------------------------------------
JSON_STR = '[{"a":1,"b":2},{"a":3,"b":4}]';
data = json.parse(JSON_STR,'collapse_objects',true);
d2 = struct('a',{1 3},'b',{2 4});
if ~isequal(data,d2)
    error('Failed to properly parse object array with collapse_objects = true');    
end

data = json.parse(JSON_STR,'collapse_objects',false);
s1 = struct('a',1,'b',2);
s2 = struct('a',3,'b',4);
d2 = {s1 s2};
if ~isequal(data,d2)
    error('Failed to properly parse object array with collapse_objects = false');    
end


%   max_bool_collapse_depth : default -1
%
%
%   collapse_objects : default true






end