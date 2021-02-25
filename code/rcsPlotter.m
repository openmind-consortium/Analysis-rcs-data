classdef rcsPlotter < handle
    % 
    %
    %% plotting helper for Summit RC+S data 
    % 
    %
    %% Background: 
    % 
    %       This class is built as as a utility function to make plotting RC+S
    %       data easier. It wraps other functions in this repo and handles
    %       loading multiple folders and plotting specific data streams
    %       such as time domain, acitgraphy, power bands, adaptive etc. 
    %
    %       There are 2 main "type" of methods in this function: 
    %       
    %       1. "plotXX" methods: will help plot specific streams 
    %       2. "reportXX" methods: report some aspect of the data 
    % 
    % 
    %% Usage / Philosophy: 
    % 
    %       This function creats an object of type "rcsPlotter" with
    %       several associated methods. 
    %       Each type of data stream can be plotted without arguments in a
    %       new figure. However, the main utilty of the function is in
    %       stringing together several folders of RC+S data (for example
    %       recorded throughout a day) and easily plotting requested data
    %       streams (such as time domain, power and adaptive) in subplots.
    %       This is acheived by passing the subplot handle to the function.
    %       Below are some example workflows. 
    %
    %
    %% Basic usage: 
    %
    %       1. Plot time domain data: 
    %              rc = rcsPlotter()
    %              rc.addFolder('path to rc+s folder'); 
    %              rc.loadData()
    %              rc.plotTdChannel(1)
    % 
    %
    %% Advanced usage: 
    % 
    %       2. Plot 2 time domain channels, 1 actigraphy channel 
    %              rc = rcsPlotter()
    %              rc.addFolder('path to rc+s folder'); 
    %              rc.loadData()
    %              
    %              % create figure
    %              hfig = figure('Color','w');
    %              hsb = gobjects();
    %              nplots = 3; 
    %              for i = 1:nplots; hsb(i,1) = subplot(nplots,1,i); end;
    %              rc.plotTdChannel(1,hsb(1,1));
    %              rc.plotTdChannel(2,hsb(2,1));
    %              rc.plotActigraphyChannel('X',hsb(3,1));
    %              % link axes since time domain and acc have differnt
    %              % sample rates: 
    %              linkaxes(hsb,'x');
    
    properties
        FolderNames
        Dates
        NumberOfSessions
        NumberOfFolders
        Data
        SessionTable
    end
    
    %%%%%%
    %
    % public methods 
    %
    %%%%%%
    methods
        
        
        %%%%%%
        %
        % init object    
        %
        %%%%%%                                
        function obj = rcsPlotter()
            obj.Dates = NaT;
            obj.NumberOfSessions = 0; % these are valid session with data
            obj.NumberOfFolders = 0; % these are just fodlers that may or may not have data
            obj.SessionTable = table();
        end
        
        %%%%%%
        %
        % add folders    
        %
        %%%%%%                        
        function addFolder(obj,folder)
            %% add folder to rcsPlotter object to open / plot 
            % 
            %% Input: 
            %      1. path (str) to folder with rc+s .json files 
            % 
            %% Usage: 
            %       rc.addFolder('path to folder'); 
            %  
            % next run rc.loadData() to run load all folders added 
            if ischar(folder)
                if exist(folder,'dir')
                    obj.NumberOfFolders = obj.NumberOfFolders + 1;
                    obj.FolderNames{obj.NumberOfFolders,1} = folder;
                else
                    error('folder can not be reached');
                end
            else
                error('input should be char array representing folder');
            end
        end
        
        %%%%%%
        %
        % report loaded folders   
        %
        %%%%%%                
        function reportFolder(obj)
            fprintf('%d folders found:\n',size(obj.FolderNames,1));
            for i = 1:size(obj.FolderNames,1)
                fprintf('\t[%0.2d]\t%s\n',i,obj.FolderNames{i});
            end
        end
        
        %%%%%%
        %
        % load data using RC+S functions  
        %
        %%%%%%        
        function loadData(obj)
            %% load data using functions in repo 
            % 
            %% no input 
            %      * note must have added at least one folder with data 
            % 
            %% Usage: 
            %       rc.loadData();
            %  
            % next run a plotting function to plot some data 

            if isempty(obj.Data)
                obj.Data = struct();
            end
            
            for i = 1:size(obj.FolderNames,1)
                fprintf('\t[%0.2d]\t%s\n',i,obj.FolderNames{i});
                clear combinedDataTable
                try
                    
                    [unifiedDerivedTimes,...
                        timeDomainData, timeDomainData_onlyTimeVariables, timeDomain_timeVariableNames,...
                        AccelData, AccelData_onlyTimeVariables, Accel_timeVariableNames,...
                        PowerData, PowerData_onlyTimeVariables, Power_timeVariableNames,...
                        FFTData, FFTData_onlyTimeVariables, FFT_timeVariableNames,...
                        AdaptiveData, AdaptiveData_onlyTimeVariables, Adaptive_timeVariableNames,...
                        timeDomainSettings, powerSettings, fftSettings, eventLogTable,...
                        metaData, stimSettingsOut, stimMetaData, stimLogSettings,...
                        DetectorSettings, AdaptiveStimSettings, AdaptiveEmbeddedRuns_StimSettings] = ProcessRCS(obj.FolderNames{i},3);
                    dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};
                    [combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);

                    %%
                catch
                    fnreport = fullfile(obj.FolderNames{i},'error_open_report.txt');
                    fid = fopen(fnreport,'w+');
                    fprintf(fid,'file error\n');
                    fclose(fid);
                end
                if exist('combinedDataTable','var')
                    if size(combinedDataTable,1) > 100 % this is had coded to avoid files that are really short - prob. bogus, consider changing 
                        nSession = obj.NumberOfSessions + 1;
                        % place all data in to object structure 
                        obj.Data(nSession).folder                            = obj.FolderNames{i};
                        obj.Data(nSession).combinedDataTable                 = combinedDataTable;
                        obj.Data(nSession).timeDomainSettings                = timeDomainSettings;
                        obj.Data(nSession).powerSettings                     = powerSettings;
                        obj.Data(nSession).fftSettings                       = fftSettings;
                        obj.Data(nSession).eventLogTable                     = eventLogTable;
                        obj.Data(nSession).metaData                          = metaData;
                        obj.Data(nSession).stimSettingsOut                   = stimSettingsOut;
                        obj.Data(nSession).stimMetaData                      = stimMetaData;
                        obj.Data(nSession).stimLogSettings                   = stimLogSettings;
                        obj.Data(nSession).DetectorSettings                  = DetectorSettings;
                        obj.Data(nSession).AdaptiveStimSettings              = AdaptiveStimSettings;
                        obj.Data(nSession).AdaptiveEmbeddedRuns_StimSettings = AdaptiveEmbeddedRuns_StimSettings;
                        
                        obj.NumberOfSessions = nSession;
                        
                        % create session table 
                        obj.SessionTable.subjectID{nSession} = metaData.subjectID;
                        obj.SessionTable.target{nSession} = [metaData.leadTargets{:}];
                        obj.SessionTable.startTime(nSession) = combinedDataTable.localTime(1);
                        obj.SessionTable.endTime(nSession) = combinedDataTable.localTime(end);
                        obj.SessionTable.duration(nSession) = combinedDataTable.localTime(end) - combinedDataTable.localTime(1);

                    end
                end
                
            end
        end
        
        
        
        
        
        %%%%%%
        %
        % export data using saved to target dir
        %
        %%%%%%        
        function exportData(obj,varargin)
            %% export data table to target dir using functions in repo 
            % 
            %% input: 
            %      1. dirname to export data table (.mat) to 
            % 
            %% Usage: 
            %       rc.exportData('\path\to\export\datatable\');
            %  
            if nargin == 1
                error('select a directoy to export data to'); 
            end
            if nargin == 2
                exportDir = varargin{1};
            end
            
            if ~exist(exportDir,'dir')
                error('cant save /access directory %s',exportDir);
            end

           
            
            for i = 1:size(obj.FolderNames,1)
                fprintf('\t[%0.2d]\t%s\n',i,obj.FolderNames{i});
                clear combinedDataTable
                try
                    fileNameToCopy = fullfile(obj.FolderNames{i},'AllDataTables.mat');
                    if exist(fileNameToCopy,'file')
                        % putting each file in sep dir so that 
                        % rcs plotter can keep working to load and plot
                        % data 
                        % as RC+S plotter relies on only one file existing
                        % within each dir 
                        % I know it's not as efficient.... 
                        patient = obj.Data(i).metaData.subjectID; 
                        recstart = obj.Data(i).combinedDataTable.localTime(1);
                        recend = obj.Data(i).combinedDataTable.localTime(end);
                        recstart.Format = 'yyyy_MM-dd__HH-mm';
                        recend.Format = 'yyyy_MM-dd__HH-mm';
                        dirnameMake = sprintf('%s__%s---%s',patient,recstart,recend); 
                        targetDir = fullfile(exportDir,dirnameMake);
                        if ~exist(targetDir,'dir')
                            mkdir(targetDir); 
                        end
                        exportFullFilename = fullfile(targetDir,'AllDataTables.mat'); 
                        copyfile(fileNameToCopy,exportFullFilename);
                    end
                    %%
                catch
                    fnreport = fullfile(obj.FolderNames{i},'error_open_report.txt');
                    fid = fopen(fnreport,'w+');
                    fprintf(fid,'file error\n');
                    fclose(fid);
                end
                if exist('combinedDataTable','var')
                    if size(combinedDataTable,1) > 100 % this is had coded to avoid files that are really short - prob. bogus, consider changing 
                        nSession = obj.NumberOfSessions + 1;
                        % place all data in to object structure 
                        obj.Data(nSession).folder                            = obj.FolderNames{i};
                        obj.Data(nSession).combinedDataTable                 = combinedDataTable;
                        obj.Data(nSession).timeDomainSettings                = timeDomainSettings;
                        obj.Data(nSession).powerSettings                     = powerSettings;
                        obj.Data(nSession).fftSettings                       = fftSettings;
                        obj.Data(nSession).eventLogTable                     = eventLogTable;
                        obj.Data(nSession).metaData                          = metaData;
                        obj.Data(nSession).stimSettingsOut                   = stimSettingsOut;
                        obj.Data(nSession).stimMetaData                      = stimMetaData;
                        obj.Data(nSession).stimLogSettings                   = stimLogSettings;
                        obj.Data(nSession).DetectorSettings                  = DetectorSettings;
                        obj.Data(nSession).AdaptiveStimSettings              = AdaptiveStimSettings;
                        obj.Data(nSession).AdaptiveEmbeddedRuns_StimSettings = AdaptiveEmbeddedRuns_StimSettings;
                        
                        obj.NumberOfSessions = nSession;
                        
                        % create session table 
                        obj.SessionTable.subjectID{nSession} = metaData.subjectID;
                        obj.SessionTable.target{nSession} = [metaData.leadTargets{:}];
                        obj.SessionTable.startTime(nSession) = combinedDataTable.localTime(1);
                        obj.SessionTable.endTime(nSession) = combinedDataTable.localTime(end);
                        obj.SessionTable.duration(nSession) = combinedDataTable.localTime(end) - combinedDataTable.localTime(1);

                    end
                end
                
            end
        end
        
        
        %%%%%%
        %
        % erase data 
        %
        %%%%%%
        function eraseData(obj)
            %% erase data from RC+S object 
            %
            % used to help clear up memory 
            %
            %% usage:
            %
            % rc.eraseData();
            % 

            obj.Data = struct();
            obj.NumberOfSessions = 0;
        end
        
        %%%%%%
        %
        % plot time domain data 
        %
        %%%%%%
        function plotTdChannel(obj,varargin)
            %% plot RC+S raw td channgels 
            %
            % 
            %% input:
            %       1. channel (int, 1-4) 
            %       2. handle to subplot (optional) 
            %
            %% usage:
            %
            % rc.plotTdChannel(1); 
            % 
            % note that the data is plotted rectified (mean subtracted) 
            if nargin == 1
                error('select at least one channel (int)');
            end
            if nargin == 2
                chan = varargin{1};
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);
            end
            if nargin == 3
                chan  = varargin{1};
                hAxes = varargin{2};
            end
            % validate input
            if ~isnumeric(chan)
                error('channel input must be integer between 1-4');
            end
            if ~ismember(chan,[1 : 1 : 4])
                error('channel input must be integer between 1-4');
            end
            
            hold(hAxes,'on');
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    dt = obj.Data(i).combinedDataTable;
                    x = datenum(dt.localTime);
                    chanfn = sprintf('TD_key%d',chan-1);
                    y = dt.(chanfn);
                    y = y - nanmean(y);
                    y = y.*1e3;
                    hplt = plot(x,y,'Parent',hAxes);
                    hplt.LineWidth = 0.5;
                    hplt.Color = [0 0 0.8 0.5];
                    % get settings
                    tdSettings = obj.Data(i).timeDomainSettings;
                    chanfn = sprintf('chan%d',chan);
                    title(tdSettings.(chanfn){1},'Parent',hAxes);
                    obj.addLocalTimeDataTip(hplt,dt.localTime);
                    ylabel(hAxes,'\muV');
                end
            end
            datetick(hAxes,'x',15,'keepticks','keeplimits');
        end
        
        %%%%%%
        %
        % plot time domain data filtered 
        %
        %%%%%%
        function plotTdChannelBandpass(obj,varargin)
            %% plot RC+S bandpass filter of time domain data with envelope 
            %
            % 
            %% input:
            %       1. channel (int, 1-4)  (required) 
            %       2. filter range, hz (e.g. 12-30) (required)
            %       2. handle to subplot (optional) 
            %
            %% usage:
            %
            % rc.plotTdChannelBandpass(1,[12 30]); 
            % 
            % note that if sampling rate was changed within session this
            % function will error out 
            if nargin < 2
                error('select at least one channel and band pass range (int)');
            end
            if nargin == 3
                chan = varargin{1};
                bandsUsed = varargin{2};
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);
            end
            if nargin == 4
                chan  = varargin{1};
                bandsUsed = varargin{2};
                hAxes = varargin{3};
            end
            % validate input
            if ~isnumeric(chan)
                error('channel input must be integer between 1-4');
            end
            if ~ismember(chan,[1 : 1 : 4])
                error('channel input must be integer between 1-4');
            end
            
            hold(hAxes,'on');
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    
                    dt = obj.Data(i).combinedDataTable;
                    x = datenum(dt.localTime);
                    chanfn = sprintf('TD_key%d',chan-1);
                    y = dt.(chanfn);
                    idxnan = ~isnan(y);
                    % verify that you have time domain data
                    if sum(isnan(y)) == length(y)
                        warningMessage = sprintf('no time domain data exists for: %s\n',...
                            obj.Data(i).folder);
                        warning(warningMessage);
                    else
                        y = y - nanmean(y);
                        y = y.*1e3;
                        
                        idxnan = ~isnan(dt.TD_samplerate);
                        uniqueSampleRate = unique(dt.TD_samplerate(idxnan));
                        if length(uniqueSampleRate) >1
                            error('can only bandpass data in which sample rate is the same');
                        else
                            sr = uniqueSampleRate;
                        end
                        

                        % first make sure that y does'nt have NaN's at start or
                        % end
                        timeUseRaw = x;
                        
                        % check start:
                        
                        cntNan = 1;
                        if isnan(y(1))
                            while isnan(y(cntNan))
                                cntNan = cntNan + 1;
                            end
                        end
                        y = y(cntNan:end);
                        cntStart = cntNan;
                        timeUseRaw = timeUseRaw(cntNan:end);
                        % check end:
                        cntNan = length(y);
                        if isnan(y(cntNan))
                            while isnan(y(cntNan))
                                cntNan = cntNan - 1;
                            end
                        end
                        cntEnd = cntNan;
                        y = y(1:cntEnd);
                        timeUseNoNans = timeUseRaw(1:cntEnd);
                        
                        yFilled = fillmissing(y,'constant',0);
                        
                        %                     idxGapStart = find(diff(isnan(y))==1) + 1;
                        %                     idxGapEnd = find(diff(isnan(y))==-1) + 1;
                        %                     for te = 1:size(idxGapStart,1)
                        %                         timeGap(te,1) = timeUseNoNans(idxGapStart(te)) - seconds(0.2);
                        %                         timeGap(te,2) = timeUseNoNans(idxGapEnd(te)) + seconds(0.2);
                        %                         idxBlank = spectTimes >= timeGap(te,1) & spectTimes <= timeGap(te,2);
                        %                         ppp(:,idxBlank) = NaN;
                        %                     end
                        %
                        
                        
                        [b,a]        = butter(3,[bandsUsed(1) bandsUsed(end)] / (sr/2),'bandpass'); % user 3rd order butter filter
                        y_filt       = filtfilt(b,a,yFilled); %filter all
                        y_filt_hilbert       = abs(hilbert(y_filt));
                        hplt = plot(hAxes,timeUseNoNans,y_filt,'LineWidth',0.5,'Color',[0.8 0 0 0.1]);
                        obj.addLocalTimeDataTip(hplt,dt.localTime);
                        hplt = plot(hAxes,timeUseNoNans,y_filt_hilbert,'LineWidth',3,'Color',[0.8 0 0 0.6]);
                        obj.addLocalTimeDataTip(hplt,dt.localTime);
                        
                        
                        % get settings
                        tdSettings = obj.Data(i).timeDomainSettings;
                        chanfn = sprintf('chan%d',chan);
                        title(tdSettings.(chanfn){1},'Parent',hAxes);
                    end
                end
            end
            datetick(hAxes,'x',15,'keepticks','keeplimits');
        end
        
        
        
        %%%%%%
        %
        % plot time domain data psds  
        %
        %%%%%%
        function plotTdChannelPsd(obj,varargin)
            %% plot RC+S pwelch of time domain data with envelope 
            %
            % divides the data into chunks (5 minutes is default) 
            % plots psd for each chunk
            %
            %% input:
            %       1. channel (int, 1-4)  (required) 
            %       2. psd chunk sizes (duration) 
            %       3. handle to subplot (optional) 
            %
            %% usage:
            %
            % % rc.plotTdChannelBandpass(1); 
            %
            % can also specifiy timing algo duration. 
            % 
            % will not compute PSS if a gap exist in data chunk 
            % if many chunks it data this may result in very few PSD's 
            % given duration of recording 
            %
            % to specify duration of data input into each pwelch
            % computation: 
            %
            % rc.plotTdChannelBandpass(1,seconds(30),hAxes); 
            % or 
            % rc.plotTdChannelBandpass(1,minutes(10),hAxes); 
            % (hAxes is handle to subplot) 
            % 
            % default PSD averaged is 5 minutes. 
            % note that if sampling rate was changed within session this
            % function will error out 
            %
            
            if nargin < 2
                error('select at least one channel and band pass range (int)');
            end
            if nargin == 2
                chan = varargin{1};
                psdDuration = minutes(5);
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);
            end
            if nargin == 3
                chan  = varargin{1};
                psdDuration = varargin{2};
                
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);

            end
            if nargin == 4
                chan  = varargin{1};
                psdDuration = varargin{2};
                hAxes = varargin{3};
            end
            % validate input
            if ~isnumeric(chan)
                error('channel input must be integer between 1-4');
            end
            if ~ismember(chan,[1 : 1 : 4])
                error('channel input must be integer between 1-4');
            end
            
            hold(hAxes,'on');
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    
                    chanfn = sprintf('TD_key%d',chan-1);
                    dt = obj.Data(i).combinedDataTable;
                    x = datenum(dt.localTime);
                    y = dt.(chanfn);
                    y = y.*1e3; % so data is in microvolt 
                    yRaw = y;

                    % verify that you have time domain data
                    if sum(isnan(y)) == length(y)
                        warningMessage = sprintf('no time domain data exists for: %s\n',...
                            obj.Data(i).folder);
                        warning(warningMessage);
                    else
                        idxnan = isnan(y);
                        
                        idxnanSampleRate = isnan(dt.TD_samplerate);
                        uniqueSampleRate = unique(dt.TD_samplerate(~idxnanSampleRate));
                        if length(uniqueSampleRate) >1
                            error('can only perform psd anlaysis on data in which sample rate is the same');
                        elseif length(y) < (seconds(psdDuration)*(max(uniqueSampleRate)))
                            error('data is smaller than psd chunk duration selected');
                        else
                            sr = uniqueSampleRate;
                        end
                        
                        % find data with no gaps - 
                        % then for each continous section of data without
                        % gaps 
                        % reshape data according to psd duration size 
                        % then concatenate all for psd computation
                        % also save (for later) the time index for PSD
                        % (middle of window) 
                        diffNans = diff(idxnan);
                        idxgapEnd = find(diffNans == 1) + 1;
                        idxgapStart = find(diffNans == -1) + 1;
                        if idxnan(1) == 0 % if data start with no gap
                            idxgapStart = [1; idxgapStart ];
                        end
                        if idxnan(end) == 0 % if data ends with gap
                            idxgapEnd = [idxgapEnd; length(idxnan) ];
                        end
                        localTime = dt.localTime;
                        gaps = localTime(idxgapEnd) - localTime(idxgapStart);
                        gaps.Format = 'hh:mm:ss.SSSS';
                        psdDuration.Format = 'hh:mm:ss.SSSS';
                        
                        totalRecLenth = (localTime(end) - localTime(1));
                        totalRecLenth.Format = 'hh:mm:ss.SSSS';
                        totalData     = sum(gaps);
                        totalData.Format = 'hh:mm:ss.SSSS';
                        % report how what % of data was capturd  
                        fprintf('%.2f of data of data recorded (%s / %s)\n', totalData/totalRecLenth,...
                                    totalRecLenth,totalData);

                        
                        % report how much data will be lost 
                        fprintf('%.2f of data has no gaps larger than %s (%s / %s)\n', sum(gaps(gaps > psdDuration))./sum(gaps),psdDuration,...
                            sum(gaps(gaps > psdDuration)), sum(gaps));

                        idxGapsUse = gaps > psdDuration;
                        gapsUse = gaps(idxGapsUse,:);
                        idxGapStartUse = idxgapStart(idxGapsUse);
                        idxGapEndUse = idxgapEnd(idxGapsUse);
                        if ~isempty(gapsUse)
                        else
                            error('at this window size (%s), all psd chunks have gaps in them / some NaNs',psdDuration)
                        end
                        
                        
                        rawDataForPSD = [];
                        for g = 1:length(idxGapStartUse)
                            y = yRaw(idxGapStartUse(g):idxGapEndUse(g));
                            reshapeFactor = seconds(psdDuration)*sr;
                            
                            yDatReshape = y(1:end-(mod(size(y,1), reshapeFactor)));
                            yDataComputePSD  = reshape(yDatReshape,reshapeFactor,size(yDatReshape,1)/reshapeFactor);
                            rawDataForPSD = [rawDataForPSD, yDataComputePSD];
                        end
                        
                        rawDataForPSDCentered = rawDataForPSD - ...
                                                   repmat(mean(rawDataForPSD,1),size(rawDataForPSD,1),1);
                        
                        
                        [fftOut,ff]   = pwelch(rawDataForPSDCentered,sr,sr/2,0:1:sr/2,sr,'psd');
                        
                        
                        hplt = plot(hAxes, ff,log10(fftOut),'Color',[0.8 0 0 0.5],'LineWidth',0.5);
                        ylabel(hAxes,'Power (log_1_0\muV^2/Hz)');
                        % get settings
                        tdSettings = obj.Data(i).timeDomainSettings;
                        chanfn = sprintf('chan%d',chan);
                        title(tdSettings.(chanfn){1},'Parent',hAxes);
                    end
                end
            end
            datetick(hAxes,'x',15,'keepticks','keeplimits');
        end
        
        
        
        
        
        %%%%%%
        %
        % plot time domain data gaps 
        %
        %%%%%%
        function plotTdChannelDataGaps(obj,varargin)
            %% plot RC+S data gaps - locations in which data is missing
            %
            % RC+S data often has gapbs bcs of lost packets, visualize the
            % gaps
            % 
            %% input:
            %       1. channel (int, 1-4)  (required) 
            %       2. handle to subplot (optional) 
            %
            %% usage:
            %
            % rc.plotTdChannelDataGaps(1)
            % 
            if nargin < 2
                error('select at least one channel and band pass range (int)');
            end
            if nargin == 2
                chan = varargin{1};
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);
            end
            if nargin == 3
                chan  = varargin{1};
                hAxes = varargin{2};
            end
            % validate input
            if ~isnumeric(chan)
                error('channel input must be integer between 1-4');
            end
            if ~ismember(chan,[1 : 1 : 4])
                error('channel input must be integer between 1-4');
            end
            
            hold(hAxes,'on');
            gapsAll = [];
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    chanfn = sprintf('TD_key%d',chan-1);
                    dt = obj.Data(i).combinedDataTable;
                    x = datenum(dt.localTime);
                    y = dt.(chanfn);
                    idxnan = isnan(y);
                    
                    % only plot the gaps 
                    imAlpha=ones(size(idxnan'));
                    imAlpha(~idxnan')=0;                    
                    hImg = imagesc(idxnan','AlphaData',imAlpha,'XData',x);

                    
                    % get settings
                    tdSettings = obj.Data(i).timeDomainSettings;
                    chanfn = sprintf('chan%d',chan);
                    ttlUse{1,1} = tdSettings.(chanfn){1};
                    
                    
                    % report gaps 
                    diffNans = diff(idxnan);
                    idxgapEnd = find(diffNans == -1) + 1; 
                    idxgapStart = find(diffNans == 1) + 1; 
                    if idxnan(1) == 1 % if data start with gap 
                        idxgapStart = [1; idxgapStart ];
                    end
                    if idxnan(end) == 1 % if data ends with gap
                        idxgapEnd = [idxgapEnd; length(idxnan) ];
                    end
                    localTime = dt.localTime;
                    gaps = localTime(idxgapEnd) - localTime(idxgapStart);
                    gapsAll = [gapsAll; gaps];
                end
            end
            modGap = mode(gaps);
            medGap = median(gaps);
            maxGap = max(gaps);
            
            modGap.Format = 'hh:mm:ss.SSSS';
            medGap.Format = 'hh:mm:ss.SSSS';
            maxGap.Format = 'hh:mm:ss.SSSS';

            
            datetick(hAxes,'x',15,'keepticks','keeplimits');
            ttlUse{2,1} = sprintf('gap mode: %s gap median %s gap max %s (HH:MM:ss.ssss)',...
                modGap,medGap,maxGap);
            title(ttlUse  ,'Parent',hAxes);
        end


        
        %%%%%%
        %
        % plot time domain data  - spectrogram 
        %
        %%%%%%        
        function plotTdChannelSpectral(obj,varargin)
            %% plot RC+S spectral td channgels 
            %
            % 
            %% input:
            %       1. channel (int, 1-4) 
            %       2. handle to subplot (optional) 
            %
            %% usage:
            %
            % rc.plotTdChannelSpectral(1); 
            % 
            % note that default spect params are chosen 
            % and missing data is handeled in specific manner 
            
            %% XXXX function not ready yet 
            if nargin == 1
                error('select at least one channel (int)');
            end
            if nargin == 2
                chan = varargin{1};
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);
            end
            if nargin == 3
                chan  = varargin{1};
                hAxes = varargin{2};
            end
            hold(hAxes,'on');
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    dt = obj.Data(i).combinedDataTable;
                    idxnanSampleRate = isnan(dt.TD_samplerate);
                    uniqueSampleRate = unique(dt.TD_samplerate(~idxnanSampleRate));
                    if length(uniqueSampleRate) >1
                        error('can only perform psd anlaysis on data in which sample rate is the same');
                    else
                        sr = uniqueSampleRate;
                    end

                    dt = obj.Data(i).combinedDataTable;
                    x = datenum(dt.localTime);
                    chanfn = sprintf('TD_key%d',chan-1);
                    y = dt.(chanfn);
                    y = y - nanmean(y);
                    y = y.*1e3;
                    
                    
                    
                    yFilled = fillmissing(y,'constant',0);

                    % set params.
                    params.windowSize     = sr;  % spect window size
                    params.windowOverlap  = ceil(params.windowSize*0.875);   % spect window overalp (points)
                    params.paddingGap     = seconds(1); % padding to add to window spec
                    params.windowUse       = 'kaiser'; % blackmanharris \ kaiser \ hann

                    
                    % blank should be bigger than window on each side
                    windowInSec = seconds(256/sr);
                    switch params.windowUse
                        case 'kaiser'
                            windowUse = kaiser(params.windowSize,2);
                        case 'blackmanharris'
                            windowUse = blackmanharris(params.windowSize);
                        case 'hann'
                            L = params.windowSize;
                            windowUse = 0.5*(1-cos(2*pi*(0:L-1)/(L-1)));
                            %             hann(params.windowSize);
                    end
                    
                    [sss,fff,ttt,ppp] = spectrogram(yFilled,...
                        windowUse,...
                        params.windowOverlap,...
                        256,sr,'yaxis');
                    
                    % put nan's in gaps for spectral data - to avoid
                    % plotting artifacts from gaps 
                    idxnan = isnan(y);
                    
                    % report gaps
                    diffNans = diff(idxnan);
                    idxgapEnd = find(diffNans == -1) + 1;
                    idxgapStart = find(diffNans == 1) + 1;
                    if idxnan(1) == 1 % if data start with gap
                        idxgapStart = [1; idxgapStart ];
                    end
                    if idxnan(end) == 1 % if data ends with gap
                        idxgapEnd = [idxgapEnd; length(idxnan) ];
                    end

                    spectTimes = dt.localTime(1) + seconds(ttt);
                    
                    localTime = dt.localTime;
                    for te = 1:size(idxgapStart,1)
                        timeGap(te,1) = localTime(idxgapStart(te)) - (windowInSec + params.paddingGap);
                        timeGap(te,2) = localTime(idxgapEnd(te))   + (windowInSec + params.paddingGap);
                        idxBlank = spectTimes >= timeGap(te,1) & spectTimes <= timeGap(te,2);
                        ppp(:,idxBlank) = NaN;
                    end
                    
                    imAlpha=ones(size(ppp'));
                    imAlpha(isnan(ppp'))=0;
                    
                    IblurY2 = imgaussfilt(ppp(:,~isnan(ppp(1,:))),[1 10],...
                        'Padding','circular',...
                        'FilterDomain','spatial');
                    pppPlot = ppp;
                    pppPlot(:,~isnan(ppp(1,:))) = IblurY2;
                    hImg = imagesc(hAxes, log10(pppPlot),'AlphaData',imAlpha','XData',datenum(spectTimes));
                    size(isnan(ppp(:,1)))
                    
                    allPCS = ppp(:,~isnan(ppp(1,:)));
                    
%                     hImg = imagesc(hAxes, log10(IblurY2));
%                     caxis(hAxes,log10([min(allPCS(:)) max(allPCS(:))]));
                    % add a datatip 
%                     hfig = get(hAxes,'Parent');
%                     h = datacursormode(hfig);
%                     set(h, 'Enable', 'on')
                    
                    % Here I have to pass the `clims` because I can't fetch them inside
%                     h.UpdateFcn = @addDataTipSpectral;

                    
%                     shading(hAxes,'interp');
                    % get settings
                    tdSettings = obj.Data(i).timeDomainSettings;
                    chanfn = sprintf('chan%d',chan);
                    title(tdSettings.(chanfn){1},'Parent',hAxes);
                    
                    set(hAxes,'YDir','normal')
                    yticks = [4 12 30 50 60 65 70 75 80 100];
                    tickLabels = {};
                    ticksuse = [];
                    for yy = 1:length(yticks)
                        [~,idx] = min(abs(yticks(yy)-fff));
                        ticksuse(yy) = idx;
                        tickLabels{yy} = sprintf('%d',yticks(yy));
                    end
                    
                    hAxes.YTick = ticksuse;
                    hAxes.YTickLabel = tickLabels;
                    % get time labels for x tick
                    colormap(hAxes,'jet');
                    
                    grid('on')
                    hAxes.GridAlpha = 0.8;
                    hAxes.Layer = 'top';
                    axis(hAxes,'tight');
                    ylabel(hAxes,'Frequency (Hz)');
                    [~,idx] = min(abs(yticks(end)-fff));
                    ylim(hAxes,[0 idx]);
                    caxis(hAxes,[-1 1]);

                end
            end
            datetick('x',15,'keepticks','keeplimits');
        end
        
        
        %%%%%%
        %
        % plot adaptive LD 
        %
        %%%%%%        
        function plotAdaptiveLd(obj,varargin)
            %% plot adaptive ld 
            %
            % 
            %% input:
            %       1. channel (int, 0 or 1) 
            %       2. handle to subplot (optional) 
            %
            %% usage:
            %
            % rc.plotAdaptiveLd(1); 
            % 
            if nargin == 1
                error('select at least one channel (int)');
            end
            if nargin == 2
                chan = varargin{1};
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);
            end
            if nargin == 3
                chan  = varargin{1};
                hAxes = varargin{2};
            end
            hold(hAxes,'on');
            hold(hAxes,'on');
            yDetAll = [];
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    dt = obj.Data(i).combinedDataTable;
                    % plot output
                    x = datenum(dt.localTime);
                    chanfn = sprintf('Adaptive_Ld%d_output',chan);
                    if sum(ismember(dt.Properties.VariableNames,chanfn)) % check if adaptive data exists
                        ydet = dt.(chanfn);
                        yDetAll = [yDetAll; ydet];
                        idplot = ~isnan(ydet);
                        hplt = plot(x(idplot),ydet(idplot),'Parent',hAxes);
                        hplt.LineWidth = 0.5;
                        hplt.Color = [0 0 0.8 0.5];
                        obj.addLocalTimeDataTip(hplt,datetime(dt.localTime(idplot)));
                        % plot upper thershold
                        chanfn = sprintf('Adaptive_Ld%d_highThreshold',chan);
                        yupper = dt.(chanfn);
                        idplot = ~isnan(yupper);
                        hplt = plot(x(idplot),yupper(idplot),'Parent',hAxes);
                        hplt.LineWidth = 0.5;
                        hplt.Color = [0.8 0 0 0.5];
                        hplt.LineStyle = '-.';
                        obj.addLocalTimeDataTip(hplt,datetime(dt.localTime(idplot)));
                        % plot lower thershold
                        chanfn = sprintf('Adaptive_Ld%d_lowThreshold',chan);
                        ylower = dt.(chanfn);
                        idplot = ~isnan(ylower);
                        hplt = plot(x(idplot),ylower(idplot),'Parent',hAxes);
                        hplt.LineWidth = 0.5;
                        hplt.Color = [0.8 0 0 0.5];
                        hplt.LineStyle = '-.';
                        obj.addLocalTimeDataTip(hplt,datetime(dt.localTime(idplot)));
                        % get input power bands
                        LDfnUse = sprintf('Ld%d',chan);
                        detectionString = obj.Data(i).DetectorSettings.(LDfnUse)(end).detectionInputs_BinaryCode;
                        detectionString = fliplr(detectionString); % bcs binary is read L to R but our last channel is first idx in binary
                        pwrSettings = obj.Data(i).powerSettings;
                        powerHtz = pwrSettings.powerBands(end).powerBandsInHz;
                        tdSettings = obj.Data(i).timeDomainSettings(end,:); % assuemes on setting
                        detectorInput = {};
                        cntInput = 1;
                        for b  = 1:length(detectionString)
                            if strcmp(detectionString(b),'1') % assumed no bridging
                                switch b
                                    case 1
                                        tdChan = 1;
                                    case 2
                                        tdChan = 1;
                                    case 3
                                        tdChan = 2;
                                    case 4
                                        tdChan = 2;
                                    case 5
                                        tdChan = 3;
                                    case 6
                                        tdChan = 3;
                                    case 7
                                        tdChan = 4;
                                    case 8
                                        tdChan = 4;
                                end
                                chanfn = sprintf('chan%d',tdChan);
                                tdRaw = tdSettings.(chanfn);
                                idxlfp = strfind(tdRaw{1},'LFP');
                                tdRaw{1}(1:idxlfp-1)
                                detectorInput{cntInput,1} = sprintf('[%s] %s',tdRaw{1}(1:idxlfp(1)-1),powerHtz{b});
                                cntInput = cntInput + 1;
                            end
                        end
                        title(hAxes,detectorInput);
                        axes(hAxes);
                        datetick('x',15,'keepticks','keeplimits');
                        
                    end
                end
            end
            % save percentils in user data in axes 
            allData = yDetAll(~isnan(yDetAll));
            prctiles = [2.5 5:5:95 97.5];
            for pp = 1:length(prctiles)
                percentilesZoom(pp,1) =  prctiles(pp);
                percentilesZoom(pp,2) =  prctile(allData,prctiles(pp));
            end
            hAxes.UserData.prctiles = percentilesZoom;
        end
        
        %%%%%%
        %
        % plot current (adaptive)
        %
        %%%%%%
        function plotAdaptiveCurrent(obj,varargin)
            %% plot adaptive current
            %
            % 
            %% input:
            %       1. program (int, 0 -3) 
            %       2. handle to subplot (optional) 
            %
            %% usage:
            %
            % rc.plotAdaptiveCurrent(1); 
            % 
            if nargin == 1
                error('select at least one program (int starts at zero)');
            end
            if nargin == 2
                program = varargin{1};
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);
            end
            if nargin == 3
                program  = varargin{1};
                hAxes = varargin{2};
            end
            hold(hAxes,'on');
            hold(hAxes,'on');
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data)
                    dt = obj.Data(i).combinedDataTable;
                    % plot output
                    x = datenum(dt.localTime);
                    chanfn = sprintf('Adaptive_Ld%d_output',0);% just to find out where data exists
                    if sum(ismember(dt.Properties.VariableNames,chanfn)) % check if adaptive data exists
                        ydet = dt.(chanfn);
                        idxkeep = ~isnan(ydet);
                        x = x(idxkeep);
                        chanfn = sprintf('Adaptive_CurrentProgramAmplitudesInMilliamps');
                        
                        ycurrent = dt.(chanfn)(idxkeep);
                        ycurrent = cell2mat(ycurrent);
                        
                        current = ycurrent(:,program+1);
                        hplt = plot(x,current,'Parent',hAxes);
                        hplt.LineWidth = 2;
                        hplt.Color = [0 0.8 0 0.5];
                        obj.addLocalTimeDataTip(hplt,datetime(dt.localTime(idxkeep)));
                    end
                end
            end
            axes(hAxes);
            datetick('x',15,'keepticks','keeplimits');
        end
        
        %%%%%%
        %
        % plot adaptive state
        %
        %%%%%%
        function plotAdaptiveState(obj,varargin)
            %% plot adaptive state
            %
            % 
            %% input:
            %       1. handle to subplot (optional) 
            %
            %% usage:
            %
            % rc.plotAdaptiveState(1); 

            if nargin == 1
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);
            end
            if nargin == 2
                hAxes = varargin{1};
            end
            hold(hAxes,'on');
            hold(hAxes,'on');
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data)
                    dt = obj.Data(i).combinedDataTable;
                    % plot output
                    x = datenum(dt.localTime);
                    chanfn = sprintf('Adaptive_CurrentAdaptiveState');
                    ystateRaw = dt.(chanfn);
                    idxstates = cellfun(@(x) isstr(x), ystateRaw);
                    
                    statesStrings = ystateRaw(idxstates);
                    xuse = x(idxstates);
                    
                    % only choose states that "exists" (e.g. get rid of "no
                    % state"
                    idxkeepStates = ~cellfun(@(x) strcmp(x,'No State'), statesStrings);
                    statesStringsStatesOnly = statesStrings(idxkeepStates);
                    xusePlot = xuse(idxkeepStates);
                    
                    statesNum = cellfun(@(x) x(end), statesStringsStatesOnly);
                    stateInts = str2num(statesNum);
                    
                    hplt = plot(xusePlot,stateInts,'Parent',hAxes);
                    hplt.LineWidth = 2;
                    hplt.Color = [0 0.8 0 0.5];
                    obj.addLocalTimeDataTip(hplt,datetime(xusePlot,'ConvertFrom','datenum'));
                end
            end
            axes(hAxes);
            datetick('x',15,'keepticks','keeplimits');
        end
        
        %%%%%%
        %
        % plot actigraphy (smoothed) 
        %
        %%%%%%
        function plotActigraphyRms(obj,varargin)
            % plot RMS of all actigraphy channels 
            % with a moving average of 20 seconds (based on sampling rate) 
            % input - first argument - program
            % second arugment - handle ot axes
            
            %% plot RMS of all actigraphy channels
            % with a moving average of 20 seconds (based on sampling rate)
            %
            % 
            %% input:
            %       1. handle to subplot (optional) 
            %
            %% usage:
            %
            % rc.plotActigraphyRms(1); 
            % 

            if nargin == 1
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);
            end
            if nargin == 2
                hAxes = varargin{1};
            end
            hold(hAxes,'on');
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    dt = obj.Data(i).combinedDataTable;
                    % plot output
                    x = datenum(dt.localTime);
                    chanfn = sprintf('Accel_%sSamples','Z');
                    if sum(ismember(dt.Properties.VariableNames,chanfn)) % check if acc data exists
                        ydet = dt.(chanfn);
                        idxkeep = ~isnan( dt.Accel_samplerate ); 
                        tuse = dt.localTime(idxkeep); 
                        unqSampleRates = unique(dt.Accel_samplerate(idxkeep));
                        sampleRateUse = max(unqSampleRates); % average using window from largest sample rate
                        accXraw = dt.Accel_XSamples(idxkeep);
                        accYraw = dt.Accel_YSamples(idxkeep);
                        accZraw = dt.Accel_ZSamples(idxkeep);
                        % computer RMS
                        x = accXraw - mean(accXraw);
                        y = accYraw - mean(accYraw);
                        z = accZraw - mean(accZraw);
                        % reshape actigraphy over 3 seconds window (64*3)
                        accAxes = {'x','y','z'};
                        yAvg = [];
                        for ac = 1:length(accAxes)
                            yDat = eval(accAxes{ac});
                            uxtimesPower = tuse;
                            reshapeFactor = sampleRateUse*3;
                            yDatReshape = yDat(1:end-(mod(size(yDat,1), reshapeFactor)));
                            timeToReshape= uxtimesPower(1:end-(mod(size(yDat,1), reshapeFactor)));
                            yDatToAverage  = reshape(yDatReshape,reshapeFactor,size(yDatReshape,1)/reshapeFactor);
                            timeToAverage  = reshape(timeToReshape,reshapeFactor,size(yDatReshape,1)/reshapeFactor);
                            
                            yAvg(ac,:) = rms(yDatToAverage - mean(yDatToAverage),1)'; % average rms
                            tUse = timeToAverage(reshapeFactor,:);
                        end
                        rmsAverage = log10(mean(yAvg));
                        % moving mean - 21 seconds 
                        mvMean = movmean(rmsAverage,7);
                        
                        % plot "raw" data" 
                        hplt = plot(hAxes, datenum(tUse),rmsAverage);
                        hplt.LineWidth = 1;
                        hplt.Color = [0.7 0.7 0 0.1];
                        obj.addLocalTimeDataTip(hplt,datetime(tUse));
                        
                        % pot moving mean moving mean - 21 seconds
                        mvMean = movmean(rmsAverage,7);
                        hplt = plot(hAxes,datenum(tUse),mvMean);
                        hplt.LineWidth = 2;
                        hplt.Color = [0.5 0.5 0 0.5];
                        obj.addLocalTimeDataTip(hplt,datetime(tUse));
                        legend(hplt,{'rms, 20 sec mov. avg.'});
                        title(hAxes ,'smoothed RMS of actigraphy');
                        ylabel(hAxes,'RMS of acc (log10(g))');
                        datetick(hAxes,'x',15,'keepticks','keeplimits');
                    end
                end
            end
            
        end
        
        
        %%%%%%
        %
        % plot actigraphy single channel
        %
        %%%%%%
        function plotActigraphyChannel(obj,varargin)
            %% plot raw actigraphy channel 
            %
            %
            %% input:
            %       1. channel (char, 'X','Y','Z')
            %       2. handle to subplot (optional)
            %
            %% usage:
            %
            % rc.plotActigraphyChannel('X');
            %
            % note that the data is plotted rectified (mean subtracted)
            
            if nargin == 1
                error('select at least one channel (int)');
            end
            if nargin == 2
                chan = varargin{1};
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);
            end
            if nargin == 3
                chan  = varargin{1};
                hAxes = varargin{2};
            end
            % validate input
            if ~ischar(chan)
                error('channel input must be str X/Y/Z');
            end
            if ~ismember(chan,{'X','Y','Z'})
                error('channel input must be str X/Y/Z (upper case)');
            end
            
            hold(hAxes,'on');
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    dt = obj.Data(i).combinedDataTable;
                    chan = upper(chan);
                    chanfn = sprintf('Accel_%sSamples',chan);
                    if sum(ismember(dt.Properties.VariableNames,chanfn)) % check if acc data exists
                        idxkeep = ~isnan( dt.Accel_samplerate );
                        ydet = dt.(chanfn)(idxkeep);
                        tuse = dt.localTime(idxkeep);
                        unqSampleRates = unique(dt.Accel_samplerate(idxkeep));
%                         ydet = ydet - nanmean(ydet);
                        hplt = plot(datenum(tuse),ydet,'Parent',hAxes);
                        hplt.LineWidth = 0.5;
                        hplt.Color = [0 0 0.8 0.5];
                        obj.addLocalTimeDataTip(hplt,tuse);
                    end
                    titleUse = sprintf('acc chan %s',chan);
                    title(titleUse,'Parent',hAxes);
                end
            end
            datetick(hAxes,'x',15,'keepticks','keeplimits');
        end
        
        
        
        %%%%%%
        %
        % plot power channel raw
        %
        %%%%%%        
        function plotPowerRaw(obj,varargin)
            %% plot raw power data 
            %
            %
            %% input:
            %       1. channel (int, 1-8)
            %       2. handle to subplot (optional)
            %
            %% usage:
            %
            % rc.plotPowerRaw(1);
            %
            if nargin == 1
                error('select at least one program (int starts at zero)');
            end
            if nargin == 2
                powerBand = varargin{1};
                hfig = figure;
                hfig.Color = 'w';
                hAxes = subplot(1,1,1);
                updateRate = 1;
            end
            if nargin == 3
                powerBand  = varargin{1};
                hAxes = varargin{2};
                updateRate = 1;
            end
            if nargin == 4
                powerBand  = varargin{1};
                hAxes = varargin{2};
                updateRate = varargin{3};
            end
            
            hold(hAxes,'on');
            hold(hAxes,'on');
            axes(hAxes);
            ypowerOut = [];
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    dt = obj.Data(i);
                    % get meta data
                    fftSettings = dt.fftSettings;
                    timeDomainSettings = dt.timeDomainSettings;
                    powerSettings = dt.powerSettings;
                    DetectorSettings = dt.DetectorSettings;
                    currentFFTconfig = struct();
                    currentFFTconfig.size = fftSettings.fftConfig(end).size;
                    currentTDsampleRate = timeDomainSettings.samplingRate(end);
                    powerBandsInHz = powerSettings.powerBands.powerBandsInHz;
                    
                    dt = obj.Data(i).combinedDataTable;
                    % plot output
                    x = datenum(dt.localTime);
                    chanfn = sprintf('Power_Band%d',powerBand);% just to find out where data exists
                    if sum(ismember(dt.Properties.VariableNames,chanfn)) % check if adaptive data exists
                        ydet = dt.(chanfn);
                        idxkeep = ~isnan(ydet);
                        x = x(idxkeep);
                        
                        ypower = dt.(chanfn)(idxkeep);
                        
                        % decide if you are going to apply update rate
                        ur = updateRate;
                        % trim x so easier to plot
                        x = x(1:(length(ypower)-rem(length(ypower),ur)));
                        pwrTrun = ypower(1:(length(ypower)-rem(length(ypower),ur)));
                        
                        reshpPower = reshape(pwrTrun,ur,length(pwrTrun)/ur);
                        powerUse = mean(reshpPower,1);
                        powerUseExpanded = repmat(powerUse,ur,1);
                        powerUseSerialized = powerUseExpanded(:);
                        
                        
                        
                        ypowerOut = [ypowerOut; powerUseSerialized];
                        
                        if ~isempty(powerUseSerialized)
                            hplt = plot(x,powerUseSerialized,'Parent',hAxes);
                            hplt.LineWidth = 2;
                            hplt.Color = [0.5 0.5 0 0.5];
                            obj.addLocalTimeDataTip(hplt,datetime(x,'ConvertFrom','datenum'));
                            
                            % get band
                            switch powerBand
                                case 1
                                    chanfn = 'chan1';
                                case 2
                                    chanfn = 'chan1';
                                case 3
                                    chanfn = 'chan2';
                                case 4
                                    chanfn = 'chan2';
                                case 5
                                    chanfn = 'chan3';
                                case 6
                                    chanfn = 'chan3';
                                case 7
                                    chanfn = 'chan4';
                                case 8
                                    chanfn = 'chan4';
                            end
                            chanfnraw = timeDomainSettings.(chanfn){end};
                            idxend = strfind(chanfnraw,'LFP');
                            
                            
                            titleUse = sprintf('[%s] [%0.2d] %s ',...
                                chanfnraw(1:idxend(1)-1),powerBand,powerBandsInHz{powerBand}); % note assumes only 1 setting in power table
                            title(titleUse);
                        end
                    end
                end
            end
            datetick('x',15,'keepticks','keeplimits');
            %% set limits;
            ylims(1) = prctile(ypowerOut,5);
            ylims(2) = prctile(ypowerOut,95);
            hAxes.YLim = ylims;
        end
        
        %%%%%%
        %
        % report power bands
        %
        %%%%%%        
        function reportPowerBands(obj)
            %% report power bands  
            %
            %
            %% input:
            %    none.
            %
            %% usage:
            %
            % rc.reportPowerBands()
            %   report power bands used in each folder 
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    dt = obj.Data(i);
                    fftSettings = dt.fftSettings;
                    timeDomainSettings = dt.timeDomainSettings;
                    powerSettings = dt.powerSettings;
                    DetectorSettings = dt.DetectorSettings;
                    currentFFTconfig = struct();
                    currentFFTconfig.size = fftSettings.fftConfig(end).size;
                    currentTDsampleRate = timeDomainSettings.samplingRate(end);
                    powerBandsInHz = powerSettings.powerBands.powerBandsInHz;
                    
                    fprintf('[%0.2d] power bands:\n\n',i);
                    for b = 1:length(powerBandsInHz)
                        switch b
                            case 1
                                chanfn = 'chan1';
                            case 2
                                chanfn = 'chan1';
                            case 3
                                chanfn = 'chan2';
                            case 4
                                chanfn = 'chan2';
                            case 5
                                chanfn = 'chan3';
                            case 6
                                chanfn = 'chan3';
                            case 7
                                chanfn = 'chan4';
                            case 8
                                chanfn = 'chan4';
                        end
                        chanfnraw = timeDomainSettings.(chanfn){end};
                        idxend = strfind(chanfnraw,'LFP');
                        
                        fprintf('[%s]\t\t [%0.2d] %s\n',...
                            chanfnraw(1:idxend(1)-1),b,powerBandsInHz{b}); % note assumes only 1 setting in power table
                        
                    end
                    fprintf('\n\n');
                    for LL = 0:1
                        fnuse = sprintf('Ld%d',LL);
                        binaryFlipped = fliplr(DetectorSettings.(fnuse)(end).detectionInputs_BinaryCode);
                        fprintf('[%0.2d] detector band LD%d:\n\n',i,LL);
                        for b = 1:length(binaryFlipped)
                            if strcmp(binaryFlipped(b) ,'1')
                                switch b
                                    case 1
                                        chanfn = 'chan1';
                                    case 2
                                        chanfn = 'chan1';
                                    case 3
                                        chanfn = 'chan2';
                                    case 4
                                        chanfn = 'chan2';
                                    case 5
                                        chanfn = 'chan3';
                                    case 6
                                        chanfn = 'chan3';
                                    case 7
                                        chanfn = 'chan4';
                                    case 8
                                        chanfn = 'chan4';
                                end
                                chanfnraw = timeDomainSettings.(chanfn){end};
                                idxend = strfind(chanfnraw,'LFP');
                                
                                
                                fprintf('[%s] [%0.2d] %s\n\n',...
                                    chanfnraw(1:idxend(1)-1),b,powerBandsInHz{b}); % note assumes only 1 setting in power table
                            end
                        end
                    end
                end
            end
            
        end
        

        %%%%%%
        %
        % report all events
        %
        %%%%%%                
        function eventOutAll = reportEventData(obj)
            % function that may be specific to data recorded using SCBS  
            % app:
            % https://github.com/openmind-consortium/App-SCBS-PatientFacingApp
            % prints out to screen event data written using data collectio software
            % omits battery information 
            % get power band used, assume one, and only read LD0 for now
            eventOutAll = table();
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    
                    eventOut = obj.Data(i).eventLogTable;
                    metaData = obj.Data(i).metaData;
                    
                    idxKeep = ~(strcmp(eventOut.EventType,'CTMLeftBatteryLevel') | ...
                        strcmp(eventOut.EventType,'CTMRightBatteryLevel') | ...
                        strcmp(eventOut.EventType,'INSRightBatteryLevel') | ...
                        strcmp(eventOut.EventType,'INSLeftBatteryLevel'));
                    idxInfo = (cellfun(@(x) any(strfind(x,'PatientID')),eventOut.EventType(:)) | ...
                        cellfun(@(x) any(strfind(x,'LeadLocation')),eventOut.EventType(:)) | ...
                        cellfun(@(x) any(strfind(x,'ImplantedLeads')),eventOut.EventType(:)) | ...
                        cellfun(@(x) any(strfind(x,'InsImplantLocation')),eventOut.EventType(:)));
                    
                    % keep the info re subject leads etc.
                    allEvents.subInfo = eventOut(idxInfo,:);
                    
                    
                    % for rest of analyis get rid of that
                    idxKeep = idxKeep & ~idxInfo;
                    eventOut = eventOut(idxKeep,:);
                    if isempty(eventOutAll)
                        eventOutAll = eventOut;
                    else
                        eventOutAll = [eventOutAll; eventOut];
                    end
                    
                    
                end
            end
            if ~isempty(eventOutAll)
                packtRxTimes    =  datetime(eventOutAll.UnixOnsetTime/1000,...
                    'ConvertFrom','posixTime','Format','dd-MMM-yyyy HH:mm:ss.SSS');
                localTime = packtRxTimes + hours( metaData.UTCoffset);
                eventOutAll.localTime = localTime;
                
                eventPrint = eventOutAll(:,{'localTime','EventType','EventSubType'});
                eventPrint
            end
        end
        
        %%%%%%
        %
        % report stim setings 
        %
        %%%%%%                
        function reportStimSettings(obj)
            % get power band used, assume one, and only read LD0 for now
            stimSettingsOutAll = table();
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    fprintf('[%0.2d] folder: \t\n',i);
                    stimLogSettings = obj.Data(i).stimLogSettings;
                    packtRxTimes    =  datetime(stimLogSettings.HostUnixTime/1000,...
                        'ConvertFrom','posixTime','Format','dd-MMM-yyyy HH:mm:ss.SSS');
                    localTime = packtRxTimes + hours( obj.Data(i).metaData.UTCoffset);
                    stimLogSettings = removevars(stimLogSettings,{'GroupA','GroupB','GroupC','GroupD','therapyStatus'});
                    stimLogSettings = addvars(stimLogSettings,localTime,'Before','HostUnixTime');
                    stimLogSettings = removevars(stimLogSettings,{'HostUnixTime'});
                    stimLogSettings
                    fprintf('\n\n'); 

                end
            end
        end
        
        
        %%%%%%
        %
        % plot time domain data psds
        %
        %%%%%%
        function reportDataQualityAndGaps(obj,varargin)
            %% report data quality for time domain data as well as gaps
            %
            % provide information about the quality of the data 
            % as well as longest stretches without gaps etc 
            %
            %% input:
            %       1. channel (int, 1-4)  (required)
            %
            %% usage:
            %
            % % rc.repotrDataQualityAndGaps(1);
            %
            % can also specifiy timing algo duration.
            %
            %
            
            if nargin < 1
                error('select at least one channel and band pass range (int)');
            end
            if nargin == 2
                chan = varargin{1};
            end
            % validate input
            if ~isnumeric(chan)
                error('channel input must be integer between 1-4');
            end
            if ~ismember(chan,[1 : 1 : 4])
                error('channel input must be integer between 1-4');
            end
            
            for i = 1:obj.NumberOfSessions
                if ~isempty(obj.Data(i))
                    
                    chanfn = sprintf('TD_key%d',chan);
                    dt = obj.Data(i).combinedDataTable;
                    x = datenum(dt.localTime);
                    y = dt.(chanfn);
                    y = y.*1e3; % so data is in microvolt
                    yRaw = y;
                    
                    % verify that you have time domain data
                    if sum(isnan(y)) == length(y)
                        warningMessage = sprintf('no time domain data exists for: %s\n',...
                            obj.Data(i).folder);
                        warning(warningMessage);
                    else
                        idxnan = isnan(y);
                        
                        idxnanSampleRate = isnan(dt.TD_samplerate);
                        uniqueSampleRate = unique(dt.TD_samplerate(~idxnanSampleRate));
                        if length(uniqueSampleRate) >1
                            error('can only perform psd anlaysis on data in which sample rate is the same');
                        else
                            sr = uniqueSampleRate;
                        end
                        
                        fprintf('[%0.2d] gap repot:\n',i);
                        fprintf('\t%s\n',obj.FolderNames{i});
                        
                        % find data with no gaps -
                        % then for each continous section of data without
                        % gaps
                        % reshape data according to psd duration size
                        % then concatenate all for psd computation
                        % also save (for later) the time index for PSD
                        % (middle of window)
                        diffNans = diff(idxnan);
                        idxgapEnd = find(diffNans == 1) + 1;
                        idxgapStart = find(diffNans == -1) + 1;
                        if idxnan(1) == 0 % if data start with no gap
                            idxgapStart = [1; idxgapStart ];
                        end
                        if idxnan(end) == 0 % if data ends with gap
                            idxgapEnd = [idxgapEnd; length(idxnan) ];
                        end
                        localTime = dt.localTime;
                        gaps = localTime(idxgapEnd) - localTime(idxgapStart);
                        gaps.Format = 'hh:mm:ss.SSSS';
                        
                        totalRecLenth = (localTime(end) - localTime(1));
                        totalRecLenth.Format = 'hh:mm:ss.SSSS';
                        totalData     = sum(gaps);
                        totalData.Format = 'hh:mm:ss.SSSS';
                        % report how what % of data was capturd
                        fprintf('\t\t%.2f of data of data recorded (%s / %s)\n', totalData/totalRecLenth,...
                            totalRecLenth,totalData);
                        
                        
                        % report some stats on data 
                        fprintf('\t\tcont. data wo gaps mode:\t %s\n', mode(gaps));
                        fprintf('\t\tcont. data wo gaps median:\t %s\n', mean(gaps));
                        fprintf('\t\tcont. data wo gaps mean:\t %s\n', median(gaps));
                        
                        % 10 larges cont data segments 
                        sortedGaps = sort(gaps,'descend');
                        fprintf('\n\ntop ten data segments no gaps:\n');
                        if length(sortedGaps) > 10
                            maxidx = 10;
                        else
                            maxidx = length(sortedGaps);
                        end
                        for gg = 1:maxidx;
                            fprintf('\t\t[%0.2d] %s\n',gg,sortedGaps(gg));
                        end
                        
                        % now repot some stuff on the gaps
                        diffNans = diff(idxnan);
                        idxgapEnd = find(diffNans == -1) + 1;
                        idxgapStart = find(diffNans == 1) + 1;
                        if idxnan(1) == 1 % if data start with gap
                            idxgapStart = [1; idxgapStart ];
                        end
                        if idxnan(end) == 1 % if data ends with gap
                            idxgapEnd = [idxgapEnd; length(idxnan) ];
                        end
                        localTime = dt.localTime;
                        gaps = localTime(idxgapEnd) - localTime(idxgapStart);
                        gaps.Format = 'hh:mm:ss.SSSS';
                        % report some stats on data
                        fprintf('\t\tgap mode:\t\t %s\n', mode(gaps));
                        fprintf('\t\tgap median:\t\t %s\n', mean(gaps));
                        fprintf('\t\tgap mean:\t\t %s\n', median(gaps));
                        fprintf('\t\tgap max:\t\t %s\n', max(gaps));
                        
                        % 10 larges gaps oin data 
                        idxgapsLarge = gaps > seconds(6); 
                        gapsLarge = gaps(idxgapsLarge);
                        sortedGaps = sort(gapsLarge,'descend');
                        gapStartLarge = idxgapStart(idxgapsLarge);
                        gapendLarge = idxgapEnd(idxgapsLarge);
                        
                        fprintf('\n\nnumber of gaps larger than 6 seconds in data: (capped at 10)\n');
                        if length(sortedGaps) > 10
                            maxidx = 10;
                        else
                            maxidx = length(sortedGaps);
                        end
                        for gg = 1:maxidx;
                            fprintf('\t\t[%0.2d] %s (%s - %s)\n',gg,sortedGaps(gg),...
                               localTime(gapStartLarge(gg)),localTime(gapendLarge(gg)));
                        end



                    end
                end
            end
        end
        
        
        
        %%%%%%
        %
        % utility plotting function 
        %
        %%%%%%
        function utilitySetYLim(obj,varargin)
            %% utility funciton to set the Y limit if percentil exsists 
            %
            % often in embedded adaptive or power a lot of transient 
            % make it needed to zoom 
            % for both of these function rcsPlotter computes percentils 
            % if percentiles exist for plotting data, you can zoom to 5-95%
            % (default) or give a value (2 element matrix) with percentiles
            % Note that percentiles computed are [2.5 5:5:95 97.5]; 
            
            %% input:
            %       1. axes (required)
            %       2. percentile (5-95 default) 
            %% usage:
            %
            % % rc.utilitySetYLim(hAxes);
            % % rc.utilitySetYLim(hAxes,[2.5 95]);
            %
            %
            if nargin == 1
                error('need to supply hanld to axes');
            end
            if nargin == 2
                hAxes = varargin{1}; 
                prctilZoom = [5 95];
            end
            if ishandle(hAxes)
                if isfield(hAxes.UserData,'prctiles')
                    prctiles = hAxes.UserData.prctiles;
                    idx1 = prctilZoom(1) == prctiles(:,1);
                    idx2 = prctilZoom(2) == prctiles(:,1);
                    if prctiles(idx1,2) > prctiles(idx2,2)
                        hAxes.YLim = [prctiles(idx1,2) prctiles(idx2,2)];
                    end
                end
                
            end
            i
        end
    end


    
    
    
    
    %%%%%%
    %
    % private methods / utility functions for class 
    %
    %%%%%%

    methods (Access = private)
        
        %%%%%%
        %
        % utility function add local time to data tip of local time
        %
        %%%%%%
        %
        % all of the plotting function use datenum as the x axis
        % reason is that for plotting spectral data using imagesc (fastest
        % performance, compared to pcolor etc. which is slow in
        % largedatasets) you need a numeric axee.
        % This utility function allows one to see a human readable time on
        % mouseover
        function addLocalTimeDataTip(obj,hplt,xTime)
            % add data tip for human readable time if matlab
            % version allows this:
            %
            if ~verLessThan('matlab','9.8') % it only work on 9.6 and above...
                row = dataTipTextRow('local time',xTime);
                hplt.DataTipTemplate.DataTipRows(end+1) = row;
            end
        end
        


        
    end
end

      

      
    
    
