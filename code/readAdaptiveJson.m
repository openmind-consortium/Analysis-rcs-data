function res = readAdaptiveJson(fn)
%% read json
%% input is full path and filename of the .json adaptive file
%% this is always saved as AdaptiveLog.json
%% this does not save anything currently, just returns a structure (res)
%% that is used in order to plot the data
try
    adpObj = deserializeJSON(fn);
    
    %% read all fields and serialize them
    % put timing info in timing structure / table
    % put adaptive data in adaptive sructure / table
    %% record info
    badfile = 0;
    if isempty(adpObj)
        badfile = 1;
    end
    if badfile ==1
        res = [];
        return;
    end
    RecordInfo = [adpObj.RecordInfo];
    timing.HostUnixTime = [RecordInfo.HostUnixTime];
    
    %% adpObj.AdaptiveUpdate
    AdaptiveUpdate = [adpObj.AdaptiveUpdate];
    % non struct fields
    fnms = {'PacketGenTime','PacketRxUnixTime'};
    for f = 1:length(fnms)
        timing.(fnms{f}) = [AdaptiveUpdate.(fnms{f})];
    end
    
    fnms = {'CurrentAdaptiveState','CurrentProgramAmplitudesInMilliamps',...
        'IsInHoldOffOnStartup','Ld0DetectionStatus','Ld1DetectionStatus','PreviousAdaptiveState','SensingStatus',...
        'StateEntryCount','StateTime','StimFlags','StimRateInHz'};
    for f = 1:length(fnms)
        adaptive.(fnms{f}) = [AdaptiveUpdate.(fnms{f})];
    end
    % struct fields
    % header - this is all timing data
    Header = [AdaptiveUpdate.Header];
    fnms = {'dataSize','dataType','dataTypeSequence',...
        'globalSequence','info','systemTick'};
    for f = 1:length(fnms)
        timing.(fnms{f}) = [Header.(fnms{f})];
    end
    timestamps = [Header.timestamp];
    timing.timestamp =  struct2array(timestamps);
    
    % LD 0 status
    Ld0Status = [AdaptiveUpdate.Ld0Status];
    fnms = {'featureInputs','fixedDecimalPoint','highThreshold',...
        'lowThreshold','output'};
    for f = 1:length(fnms)
        adaptive.(['LD0_' fnms{f}]) = [Ld0Status.(fnms{f})];
    end
    
    % LD 1 status
    Ld1Status = [AdaptiveUpdate.Ld1Status];
    fnms = {'featureInputs','fixedDecimalPoint','highThreshold',...
        'lowThreshold','output'};
    for f = 1:length(fnms)
        adaptive.(['LD1_' fnms{f}]) = [Ld1Status.(fnms{f})];
    end
    
    res.timing = timing;
    res.adaptive = adaptive;
catch
    res = [];
    warning('error in reading adaptive file - returning empty matrix');
end

