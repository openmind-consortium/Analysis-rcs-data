function outRec  = loadDeviceSettings(jsonfn)
DeviceSettings = jsondecode(fixMalformedJson(fileread(jsonfn),'DeviceSettings'));
%% load stimulation config
% this code (re stim sweep part) assumes no change in stimulation from initial states
% this code will fail for stim sweeps or if any changes were made to
% stimilation 
% need to fix this to include stim changes and when the occured to color
% data properly according to stim changes and when the took place for in
% clinic testing 

if isstruct(DeviceSettings)
    DeviceSettings = {DeviceSettings};
end
therapyStatus = DeviceSettings{1}.GeneralData.therapyStatusData;
groups = [ 0 1 2 3]; 
groupNames = {'A','B','C','D'}; 
stimState = table(); 
cnt = 1; 
for g = 1:length(groups) 
    fn = sprintf('TherapyConfigGroup%d',groups(g));
    for p = 1:4
        if DeviceSettings{1}.TherapyConfigGroup0.programs(p).isEnabled==0
            stimState.group(cnt) = groupNames{g};
            if (g-1) == therapyStatus.activeGroup
                stimState.activeGroup(cnt) = 1;
                if therapyStatus.therapyStatus
                    stimState.stimulation_on(cnt) = 1;
                else
                    stimState.stimulation_on(cnt) = 0;
                end
            else
                stimState.activeGroup(cnt) = 0;
                stimState.stimulation_on(cnt) = 0;
            end
            
            stimState.program(cnt) = p;
            stimState.pulseWidth_mcrSec(cnt) = DeviceSettings{1}.(fn).programs(p).pulseWidthInMicroseconds;
            stimState.amplitude_mA(cnt) = DeviceSettings{1}.(fn).programs(p).amplitudeInMilliamps;
            stimState.rate_Hz(cnt) = DeviceSettings{1}.(fn).rateInHz;
            elecs = DeviceSettings{1}.(fn).programs(p).electrodes.electrodes;
            elecStr = ''; 
            for e = 1:length(elecs)
                if elecs(e).isOff == 0 % electrode active 
                    if e == 17
                        elecUse = 'c'; 
                    else
                        elecUse = num2str(e-1);
                    end
                    if elecs(e).electrodeType==1 % anode 
                        elecSign = '-';
                    else
                        elecSign = '+';
                    end
                    elecSnippet = [elecSign elecUse ' '];
                    elecStr = [elecStr elecSnippet];
                end
            end

            stimState.electrodes{cnt} = elecStr; 
            cnt = cnt + 1; 
        end
    end
end 
if ~isempty(stimState)
    stimStatus = stimState(logical(stimState.activeGroup),:);
else
    stimStatus = [];
end
%% load the device configration for sensing 

recNum = 0;
inRecord = 0; 
for f = 1:length(DeviceSettings)
    fnms = fieldnames(DeviceSettings{f});
    curStr = DeviceSettings{f};
    if isfield(curStr,'SensingConfig')
        if isfield(curStr.SensingConfig,'timeDomainChannels')
            curStr.SensingConfig.timeDomainChannels
            tdData = translateTimeDomainChannelsStruct(curStr.SensingConfig.timeDomainChannels);
        end
        if  isfield(curStr.SensingConfig,'fftConfig')
            fftConfig = curStr.SensingConfig.fftConfig; 
        end
        if isfield(curStr.SensingConfig,'powerChannels')
             powerChannels = curStr.SensingConfig.powerChannels; 
        end
    end
    if isfield(curStr,'SensingConfig')
        if isfield(curStr.SensingConfig,'fftConfig')
            fftConfig = curStr.SensingConfig.fftConfig;
        end
        if isfield(curStr.SensingConfig,'powerChannels')
            powerChannels = curStr.SensingConfig.powerChannels; 
        end
        
    end
    if isfield(curStr,'StreamState')
        if ~inRecord
            if curStr.StreamState.TimeDomainStreamEnabled % recording started
                recNum = recNum + 1;
                timenum = curStr.RecordInfo.HostUnixTime;
                t = datetime(timenum/1000,'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
                outRec(recNum).timeStart = t;
                outRec(recNum).unixtimeStart  = timenum;
                outRec(recNum).tdData = tdData;
                outRec(recNum).powerChannels = powerChannels;
                outRec(recNum).fftConfig = fftConfig;
                inRecord = 1;
            end
        end
        if inRecord 
            if ~curStr.StreamState.TimeDomainStreamEnabled % recording ended
                inRecord = 0; 
                timenum = curStr.RecordInfo.HostUnixTime;
                t = datetime(timenum/1000,'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
                outRec(recNum).timeEnd = t;
                outRec(recNum).unixtimeEnd  = timenum;
                outRec(recNum).duration = outRec(recNum).timeEnd - outRec(recNum).timeStart;
            end
        end
    end
end

if ~exist('outRec','var') % if no data exists create empty 'outRec' structure 
    outRec = []; 
end

%%

% loop on structures and construct table of files that exist

[pn,fnm,ext ] = fileparts(jsonfn);
save(fullfile(pn,[fnm '.mat']),'outRec','stimState','stimStatus','DeviceSettings');
% tblout = struct2table(outRec);
end

function outstruc = translateTimeDomainChannelsStruct(tdDat)
%% assume no bridging
outstruc = tdDat;
for f = 1:length(outstruc)
    % lpf 1 (front end)
    switch tdDat(f).lpf1
        case 9
            outstruc(f).lpf1 = '450Hz';
        case 18
            outstruc(f).lpf1 = '100Hz';
        case 36
            outstruc(f).lpf1 = '50Hz';
        otherwise
            outstruc(f).lpf1 = 'unexpected';
    end
    % lpf 1 (bacnk end amplifier)
    switch tdDat(f).lpf2
        case 9
            outstruc(f).lpf2 = '100Hz';
        case 11
            outstruc(f).lpf2 = '160Hz';
        case 12
            outstruc(f).lpf2 = '350Hz';
        case 14
            outstruc(f).lpf2 = '1700Hz';
        otherwise
            outstruc(f).lpf2 = 'unexpected';
    end
    % channels - minus input
    switch tdDat(f).minusInput
        case 0
            outstruc(f).minusInput = 'floating';
        case 1
            outstruc(f).minusInput = '0';
        case 2
            outstruc(f).minusInput = '1';
        case 4
            outstruc(f).minusInput = '2';
        case 8
            outstruc(f).minusInput = '3';
        case 16
            outstruc(f).minusInput = '4';
        case 32
            outstruc(f).minusInput = '5';
        case 64
            outstruc(f).minusInput = '6';
        case 128
            outstruc(f).minusInput = '7';
        otherwise
            outstruc(f).minusInput = 'unexpected';
    end
    if ~strcmp(outstruc(f).minusInput,'floating') & ~strcmp(outstruc(f).minusInput,'unexpected')
        if f > 2 % asssumes there is no bridging 
            outstruc(f).minusInput = num2str( str2num(outstruc(f).minusInput)+8);
        end
    end
    % channels - plus input
      switch tdDat(f).plusInput
        case 0
            outstruc(f).plusInput = 'floating';
        case 1
            outstruc(f).plusInput = '0';
        case 2
            outstruc(f).plusInput = '1';
        case 4
            outstruc(f).plusInput = '2';
        case 8
            outstruc(f).plusInput = '3';
        case 16
            outstruc(f).plusInput = '4';
        case 32
            outstruc(f).plusInput = '5';
        case 64
            outstruc(f).plusInput = '6';
        case 128
            outstruc(f).plusInput = '7';
        otherwise
            outstruc(f).plusInput = 'unexpected';
      end
      if ~strcmp(outstruc(f).plusInput,'floating') & ~strcmp(outstruc(f).plusInput,'unexpected')
          if f > 2 % asssumes there is no bridging
              outstruc(f).plusInput = num2str( str2num(outstruc(f).plusInput)+8);
          end
      end
    % sample rate 
    switch tdDat(f).sampleRate
        case 0
            outstruc(f).sampleRate = '250Hz';
        case 1
            outstruc(f).sampleRate = '500Hz';
        case 2 
            outstruc(f).sampleRate = '1000Hz';
        case 240
            outstruc(f).sampleRate = 'disabled';     
        otherwise
            outstruc(f).plusInput = 'unexpected';
    end
    outstruc(f).chanOut = sprintf('+%s-%s',...
        outstruc(f).plusInput,outstruc(f).minusInput);
    outstruc(f).chanFullStr = sprintf('%s lpf1-%s lpf2-%s sr-%s',...
        outstruc(f).chanOut,...
        outstruc(f).lpf1,outstruc(f).lpf2,outstruc(f).sampleRate);
end

end

