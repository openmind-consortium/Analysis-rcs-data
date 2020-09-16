function error_coverage()

try
    %Mex function requires at least 1 input
    turtle_json_mex();
    error('Function was supposed to throw an error but didn''t')
catch ME
    if ~strcmp(ME.identifier,'turtle_json:n_inputs')
        error('Unexpected error identifier')
    end
end

try
    %json.load is for file paths, not strings
    json.load('This is a test');
    error('Function was supposed to throw an error but didn''t')
catch ME
    if ~strcmp(ME.identifier,'turtle_json:file_open')
        error('Unexpected error identifier')
    end
end

%Invalid inputs
%--------------------------------------------------------------------------
try
    %json.parse with not a string
    json.parse(1);
    error('Function was supposed to throw an error but didn''t')
catch ME
    if ~strcmp(ME.identifier,'turtle_json:invalid_input')
        error('Unexpected error identifier')
    end
end

try
    %json.load with not a string
    json.load(1);
    error('Function was supposed to throw an error but didn''t')
catch ME
    if ~strcmp(ME.identifier,'turtle_json:invalid_input')
        error('Unexpected error identifier')
    end
end





end

