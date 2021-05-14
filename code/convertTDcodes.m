function TDsettings = convertTDcodes(TDdata)
%%
% Conversion of Medtronic numeric codes into values (e.g. Hz)
%
% Input: Data within "DeviceSettings.SensingConfig.timeDomainChannels",
% contained in DeviceSettings.json (after converted to table format)
%
% Output: Table of the same size as input, with coded values replaced
%
% This function is called from createDeviceSettingsTable.m
% Assumes no bridging across channels
%%

TDsettings = TDdata;
for iChan = 1:length(TDsettings)
    % Gain
    switch TDdata(iChan).gain
        case 0
            TDsettings(iChan).gain = 500;
        case 1
            TDsettings(iChan).gain = 1000;
        case 2
            TDsettings(iChan).gain = 250;
        case 4
            TDsettings(iChan).gain = 2000;
        otherwise
            TDsettings(iChan).gain = 'Unexpected';
    end
    
    % HPF
    switch TDdata(iChan).hpf
        case 0
            TDsettings(iChan).hpf = 8.5;
        case 16
            TDsettings(iChan).hpf = 1.2;
        case 32
            TDsettings(iChan).hpf = 3.3;
        case 96
            TDsettings(iChan).hpf = 8.6;
        otherwise
            TDsettings(iChan).hpf = 'Unexpected';
    end
    
    % LFP 1 (front end)
    switch TDdata(iChan).lpf1
        case 9
            TDsettings(iChan).lpf1 = 450;
        case 18
            TDsettings(iChan).lpf1 = 100;
        case 36
            TDsettings(iChan).lpf1 = 50;
        otherwise
            TDsettings(iChan).lpf1 = 'Unexpected';
    end
    % LFP 1 (back end amplifier)
    switch TDdata(iChan).lpf2
        case 9
            TDsettings(iChan).lpf2 = 100;
        case 11
            TDsettings(iChan).lpf2 = 160;
        case 12
            TDsettings(iChan).lpf2 = 350;
        case 14
            TDsettings(iChan).lpf2 = 1700;
        otherwise
            TDsettings(iChan).lpf2 = 'Unexpected';
    end
    % Channels - minus input
    switch TDdata(iChan).minusInput
        case 0
            TDsettings(iChan).minusInput = 'Floating';
        case 1
            TDsettings(iChan).minusInput = '0';
        case 2
            TDsettings(iChan).minusInput = '1';
        case 4
            TDsettings(iChan).minusInput = '2';
        case 8
            TDsettings(iChan).minusInput = '3';
        case 16
            TDsettings(iChan).minusInput = '4';
        case 32
            TDsettings(iChan).minusInput = '5';
        case 64
            TDsettings(iChan).minusInput = '6';
        case 128
            TDsettings(iChan).minusInput = '7';
        otherwise
            TDsettings(iChan).minusInput = 'Unexpected';
    end
    % For TD chans 3 and 4, shift electrode contact numbers to be 8-15 (corresponding to second lead)
    if iChan > 2
        if ~strcmp(TDsettings(iChan).minusInput,'Floating') && ~strcmp(TDsettings(iChan).minusInput,'Unexpected')
            TDsettings(iChan).minusInput = num2str(str2num(TDsettings(iChan).minusInput)+8);
        end
    end
    % Channels - plus input
    switch TDdata(iChan).plusInput
        case 0
            TDsettings(iChan).plusInput = 'Floating';
        case 1
            TDsettings(iChan).plusInput = '0';
        case 2
            TDsettings(iChan).plusInput = '1';
        case 4
            TDsettings(iChan).plusInput = '2';
        case 8
            TDsettings(iChan).plusInput = '3';
        case 16
            TDsettings(iChan).plusInput = '4';
        case 32
            TDsettings(iChan).plusInput = '5';
        case 64
            TDsettings(iChan).plusInput = '6';
        case 128
            TDsettings(iChan).plusInput = '7';
        otherwise
            TDsettings(iChan).plusInput = 'Unexpected';
    end
    % For TD chans 3 and 4, shift electrode contact numbers to be 8-15 (corresponding to second lead)
    if iChan > 2 % asssumes there is no bridging
        if ~strcmp(TDsettings(iChan).plusInput,'Floating') && ~strcmp(TDsettings(iChan).plusInput,'Unexpected')
            TDsettings(iChan).plusInput = num2str( str2num(TDsettings(iChan).plusInput)+8);
        end
    end
    % Sample rate
    switch TDdata(iChan).sampleRate
        case 0
            TDsettings(iChan).sampleRate = 250;
        case 1
            TDsettings(iChan).sampleRate = 500;
        case 2
            TDsettings(iChan).sampleRate = 1000;
        case 240
            TDsettings(iChan).sampleRate = 'Disabled';
        otherwise
            TDsettings(iChan).sampleRate = 'Unexpected';
    end
    TDsettings(iChan).chanOut = sprintf('+%s-%s',...
        TDsettings(iChan).plusInput,TDsettings(iChan).minusInput);
    % channel full string may hay have mix of double/str so need to account
    % for this: 
    if isstr(TDsettings(iChan).lpf1)
        charUseLPF1 = '%s';
    else
        charUseLPF1 = '%d';
    end
    
    if isstr(TDsettings(iChan).lpf2)
        charUseLPF2 = '%s';
    else
        charUseLPF2 = '%d';
    end
    
    if isstr(TDsettings(iChan).sampleRate)
        charUseSR = '%s';
    else
        charUseSR = '%d';
    end
    
    TDsettings(iChan).chanFullStr = sprintf(['%s' ' LFP1-' charUseLPF1 ' LFP2-' charUseLPF2 ' SR-' charUseSR],...
        TDsettings(iChan).chanOut,...
        TDsettings(iChan).lpf1,TDsettings(iChan).lpf2,TDsettings(iChan).sampleRate);
end