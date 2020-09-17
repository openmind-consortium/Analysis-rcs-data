function [outdatcomplete, srates, unqsrates] = MAIN(varargin)
%% This function reads TimeDomain *.json from RC+S
%% The main reason for this function is to convert this *.json file to a 
%% an easier to analyze *.csv file, and in particular to deal with packet loss issues. 

%% Depedencies: 
% https://github.com/JimHokanson/turtle_json
% in the a folder called "toolboxes" in the directory where MAIN is. 
if isempty(varargin)
    [fn,pn] = uigetfile('*.json');
    filename = fullfile(pn,fn);
else
    filename  = varargin{1};
end

% check if you have a preloaded / converted json and load that 
% this is mainly so you can batch covnert many files at once on server 
%% XXXX TURN THIS FUNCTION OFF FOR NOW 
[pn,fn,ext] = fileparts(filename);
% if exist(fullfile(pn,[fn '_json_only_.mat' ]),'file') == 2
%     load(fullfile(pn,[fn '_json_only_.mat' ]),'jsonojb');
%     jsonobj = jsonojb; % consider fixing this type in next versions... XXXXXX
% else
%     jsonobj = deserializeJSON(filename);
% end
jsonobj = deserializeJSON(filename);
%% XXXX TURN THIS FUNCTION OFF FOR NOW 





if ~isempty(strfind(filename,'RawDataTD'))
    if ~isempty(jsonobj)
        if ~isempty(jsonobj.TimeDomainData)  % no data exists
            [outtable, srates] = unravelData(jsonobj);
        else
            outtable = table();
            srates = [];
        end
    else
        outtable = table();
        srates = [];
    end
end


if ~isempty(strfind(filename,'RawDataAccel'))
    if ~isempty(jsonobj)
        if ~isempty(jsonobj.AccelData)  % no data exists
            [outtable, srates] = unravelDataACC(jsonobj);
        else
            outtable = table();
            srates = [];
        end
        %check clean the data from packets that have bad years 
        x =2;
    else
        outtable = table();
        srates = [];
    end
end
if ~isempty(outtable)
    % XXXXXXX
    % XXXXXXX
    % XXXXXXX
    % XXXXXXX
    % XXXXXXX
    % XXXXXXX
    outdatcomplete = populateTimeStamp(outtable,srates,filename);
    % XXXXXXX
    % XXXXXXX
    % XXXXXXX
    % XXXXXXX
    % XXXXXXX
    % XXXXXXX
%     outdatcomplete = populateTimeStamp_KS(outtable,srates,filename);
else
    outdatcomplete = table();
end
[pn,fn,ext] = fileparts(filename); 
% writetable(outdatcomplete,fullfile(pn,[fn '.csv']));
unqsrates = unique(srates); 
save(fullfile(pn,[fn '.mat']),'outdatcomplete','srates','unqsrates','-v7.3');
end

