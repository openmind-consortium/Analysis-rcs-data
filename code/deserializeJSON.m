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
    warning('Not able to open file - attmepting fix');
    fprintf('Defective file %s\n',filename);
    
    % Try to fix the file; separate fixes for Adaptive vs all other JSON
    % file types
    dat = fileread(filename);
    [~,jsonFileName,~] = fileparts(filename);
    
    if strcmp(jsonFileName,'AdaptiveLog')
        adaptiveFile = filename;
        try
            data = jsondecode(fixMalformedJson(fileread(adaptiveFile),'AdaptiveLog'));
        catch
            data = [];
        end
    else
        if strcmp(dat(end),'}')  % it's missing the end closing brackets
            fileID = fopen(filename,'a');
            fprintf(fileID,'%s',']}]');
            fclose(fileID);
            try
                data = json.load(filename);
                fprintf('File loaded in %.2f seconds\n',toc(start));
            catch
                fprintf('File failed to load problem with json\n');
                data = [];
            end
        else
            data = [];
        end
    end
end

end