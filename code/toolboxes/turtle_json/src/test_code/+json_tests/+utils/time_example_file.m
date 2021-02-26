classdef time_example_file
    %
    %   Class:
    %   json_tests.time_example_file
    %
    %   Access
    %   ------
    %   all_results = json_tests.time_example_file.testAll()
    %
    %   json_tests.utils.testExample
    %
    %   This class may move to a 'support' folder
    
    properties
       average_elapsed_time
       average_tokenize_time
       average_convert_time
       method  %TODO: Make this a string ...
       file_name
       file_path
       data
       tokens
    end
    
    methods (Static)
        function all_results = testAll(varargin)
            %
            %   all_results = json_tests.time_example_file.testAll
            %   
            %   This might be better in a file that clearly indicates that
            %   it is a test
            
            file_names = json.utils.examples.FILE_LIST;
            n_files = length(file_names);
            all_results = cell(1,n_files);
            for iFile = 1:n_files
                fprintf('Running example %d of %d: %s\n',iFile,n_files,file_names{iFile});
                all_results{iFile} = json_tests.utils.time_example_file(file_names{iFile},varargin{:});
            end
            all_results = [all_results{:}];
        end
    end
    
    methods
        function obj = time_example_file(name_or_index,varargin)
            %
            %   result = json_tests.utils.time_example_file(name_or_index)
            %
            %   result = json_tests.utils.time_example_file('big.json','n_runs',1)
            %
            %   Optional Inputs
            %   ---------------
            %   n_runs: scalar
            %       # of times to run the code
            %   method: scalar (default 1)
            %       1 - turtle_json
            %       2 - Matlab mex
            %
            
            in.n_runs = 10;
            in.method = 1;
            in.load_options = {};
            in = json.sl.in.processVarargin(in,varargin);
            
            file_path = json.utils.examples.getFilePath(name_or_index);
            obj.file_path = file_path;
            [~,obj.file_name] = fileparts(file_path);
            
            n_runs = in.n_runs;
            if in.method == 1
                t0 = tic;
                for iRun = 1:n_runs
                    token = json.tokens.load(file_path,in.load_options{:});
                end
                t1 = toc(t0)/n_runs;
                obj.average_tokenize_time = t1;
                obj.tokens = token;
                t2 = tic;
                for iRun = 1:n_runs
                    data = token.getParsedData();
                end
                t3 = toc(t2)/n_runs;
                obj.average_convert_time = t3;
                
                obj.average_elapsed_time = t3 + t1;
            elseif in.method == 2
                t0 = tic;
                if ismac
                    error('Not yet implemented')
                else
                    for iRun = 1:n_runs
                        temp = fileread(file_path);
                        data = mexDecodeJSON(temp, @makeArray, @makeStructure);
                    end
                end
                
                t3 = toc(t0)/n_runs;
                obj.average_elapsed_time = t3;
            elseif in.method == 3
                %What is this?????
                
                t0 = tic;

                for iRun = 1:n_runs
                    temp = fileread(file_path);
                    data = jsondecode(temp);
                end

                
                t3 = toc(t0)/n_runs;

            end
            
            obj.method = in.method;
            obj.data = data;

        end
    end
    
end

function data = makeStructure(names, values, areNamesUnique, areNamesValid)
% Create a structure from names and values cell arrays. Ensure the names
% are unique.

if ~(areNamesUnique && areNamesValid)
    names = matlab.lang.makeUniqueStrings(names);
    names = matlab.lang.makeValidName(names);
end
data = cell2struct(values, names, 1);
if isempty(data)
    data = struct;
end
end

%-------------------------------------------------------------------------%

function arr = makeArray(data, depth)
% Create an array from data cell array.

arr = reshape(data, [ones(1, depth - 1) numel(data) 1]);
try
    % do not try to convert a cell array to a matrix if it
    % contains characters
    if ~isempty(arr) && iscell(arr) && ~iscellstr(arr)
        arr = cell2mat(arr);
    elseif isempty(arr)
        arr = [];
    end
catch %#ok<CTCH>
end
if iscell(arr) && depth > 1
    % Remove singleton dimensions in each element of data which
    % can result from the earlier reshape.
    arr = cellfun(@squeeze, arr, 'UniformOutput', false);
end
end
