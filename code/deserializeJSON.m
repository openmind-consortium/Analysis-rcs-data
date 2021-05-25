function data = deserializeJSON(filename)
%%
% Reads .JSON files from RC+S and loads data into Matlab. In cases where
% end closing brackets is missing, will add in order to make file readable.
% Requires turtle_json toolbox
%%

% Add turtle_json toolbox to path
pathToCode = mfilename('fullpath');
filePath = fileparts(pathToCode);
addpath(genpath(fullfile(filePath,'toolboxes', 'turtle_json','src')))

% Try loading json file - may need to have a closing bracket added
start = tic;
try
    data = json.load(filename);
    fprintf('File loaded in %.2f seconds\n',toc(start));
catch
    warning('Not able to open file - attempting fix');
    fprintf('Defective file %s\n',filename);
    [~,jsonFileName,~]=fileparts(filename);
    
    try
        % First attempt to fix by simply adding missing curly and square braces
        data = jsondecode(fixMalformedJson(fileread(filename),jsonFileName));
    catch
        try 
            % If this fix fails, attempt to remove last record in JSON array
            data = jsondecode(fixMalformedJson(fileread(filename),jsonFileName,false));
        catch
            data = [];
            warning('Failed to fix')
        end
    end
end

end