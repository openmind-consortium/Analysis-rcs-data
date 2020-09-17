function [outdatcomplete,outRec,eventTable,outdatcompleteAcc,powerOut,adaptiveTable] =  MAIN_load_rcs_data_from_folder(varargin)
%% function load rcs data from a folder 
if isempty(varargin)
    [dirname] = uigetdir(pwd,'choose a dir with rcs .json data');
else
    dirname  = varargin{1};
end
if nargin>=2 % check if there is a params argument 
    params  = varargin{2};
else
    params = []; 
end

% initialize return variables as empty matrices 
outdatcomplete = table(); 
outRec = struct(); 
eventTable = table(); 
outdatcompleteAcc = table();  
powerTable = table();
%% load files 

filesLoad = {'RawDataTD.json','DeviceSettings.json','EventLog.json','RawDataAccel.json','RawDataPower.json','AdaptiveLog.json','StimLog.json'}; 
for j = 1:length(filesLoad)
    if ismac || isunix
        ff = findFilesBVQX(dirname,filesLoad{j});
    elseif ispc
        ff = {fullfile(dirname,filesLoad{j})};
    end
    checkForErrors(ff);
    [fileExists, fn] = checkIfMatExists(ff{1});
    if fileExists
        if strcmp(filesLoad{j},'RawDataAccel.json') % if acc file rename it 
            a = load(fn); 
            outdatcompleteAcc = a.outdatcomplete; 
            sratesAcc = a.srates; 
            unqsratesAcc = a.unqsrates;
        elseif strcmp(filesLoad{j},'RawDataPower.json') % if power file load bands and table and return that
                load(fn,'powerTable','powerBandInHz');
                powerOut.powerTable = powerTable;
                powerOut.bands      = powerBandInHz;
        else
            load(fn);
        end
    else
        switch filesLoad{j}
            case 'RawDataTD.json'
                fileload = fullfile(dirname,'RawDataTD.json');
                if ~isempty(params)
                    % relies on .json mex reader package that only works on PC's or Macs 
                    % for running larger muber of files
                    % on linux cluser need to do this (fast) step first on
                    % PC/MAC
                    if params.jsononly 
                        jsonojb = deserializeJSON(fileload); 
                        varinfo=whos('jsonojb');
                        if varinfo.bytes >= 2^31
                            save(fullfile(dirname,['RawDataTD' '_json_only_.mat']),'jsonojb' ,'-v7.3','-nocompression');
                        else
                            save(fullfile(dirname,['RawDataTD' '_json_only_.mat']),'jsonojb');
                        end
                    else 
                        [outdatcomplete, srates, unqsrates] = MAIN(fileload);
                    end
                else
                        [outdatcomplete, srates, unqsrates] = MAIN(fileload);
                end
            case 'RawDataAccel.json'
                fileload = fullfile(dirname,'RawDataAccel.json');
                if ~isempty(params)
                    if params.jsononly
                        jsonojb = deserializeJSON(fileload);
                        save(fullfile(dirname,['RawDataAccel' '_json_only_.mat']),'jsonojb');
                    else
                        fileload = fullfile(dirname,'RawDataAccel.json');
                        [outdatcompleteAcc, ~, ~] = MAIN(fileload);
                    end
                else
                    fileload = fullfile(dirname,'RawDataAccel.json');
                    [outdatcompleteAcc, ~, ~] = MAIN(fileload);
                end
            case 'DeviceSettings.json'
                fileload = fullfile(dirname,'DeviceSettings.json');
                outRec = loadDeviceSettings(fileload);
            case 'EventLog.json'
                fileload = fullfile(dirname,'EventLog.json');
                eventTable = loadEventLog(fileload);
                if isempty(eventTable)
                    sessionid = fileload(strfind(fileload,'Session')+7:strfind(fileload,'Session')+19);
                    eventTable = createDummyEventTable(outRec,sessionid);
                end
                [pn,fnm, ext] = fileparts(fileload);
                save(fullfile(pn,[fnm '.mat']),'eventTable');
            case 'RawDataPower.json'
                fileload = fullfile(dirname,'RawDataPower.json');
                [powerTable, powerBandInHz] = loadPowerData(fileload);
                save(fullfile(dirname,['RawDataPower' '.mat']),'powerTable','powerBandInHz');
                powerOut.powerTable = powerTable;
                powerOut.bands      = powerBandInHz;
            case 'AdaptiveLog.json'
                fileload = fullfile(dirname,'AdaptiveLog.json');
                res = readAdaptiveJson(fileload); 
                adaptiveTable = table();
                if ~isempty(res)
                    % load timing info
                    fn = fieldnames(res.timing);
                    for f = 1:length(fn)
                        adaptiveTable.(fn{f}) = res.timing.(fn{f})(:);
                    end
                    % load adaptive info
                    fna = fieldnames(res.adaptive);
                    for f = 1:length(fna)
                        if size(res.adaptive.(fna{f}),1)==1
                            adaptiveTable.(fna{f}) = res.adaptive.(fna{f})(:);
                        elseif size(res.adaptive.(fna{f}),1)==4
                            adaptiveTable.(fna{f}) = res.adaptive.(fna{f})';
                        end
                    end
                    save(fullfile(dirname,['AdaptiveLog' '.mat']),'adaptiveTable');
                end
            case 'StimLog.json'
                try 
                    loadStimSettings(fullfile(dirname,'StimLog.json'));
                catch 
                    warning('could not load stim settings');
                end
        end
        
    end
end


end

function checkForErrors(ff)
if isempty(ff)
    error('no time domain json'); 
elseif length(ff) > 2 
    error('more than one time domain files');  
end
end

function [fileExists, fnout] = checkIfMatExists(fn)
[pn,fn,ext] = fileparts(fn);
if exist(fullfile(pn,[fn '.mat']),'file')
    fileExists = 1; 
    fnout = fullfile(pn,[fn '.mat']);
else
    fileExists = 0; 
    fnout = [];
end
end