% function temp_plotOverviewData()

    close all
    clear all
    clc

    % load dataset
%     fn = '/Users/juananso/Starr Lab Dropbox/juan_testing/SCBS testing/Session1621450483512/DeviceNPC700378H';
%     fn = '~/Box/RC-S_Studies_Regulatory_and_Data/Patient In-Clinic Data/RCS10/study_visits/v07_gamma_entrainment/SCBS/RCS10L/Session1620066966468/DeviceNPC700436H';
%     fn = '~/Box/RC-S_Studies_Regulatory_and_Data/Patient In-Clinic Data/RCS10/study_visits/v07_gamma_entrainment/SCBS/RCS10L/Session1620067480821/DeviceNPC700436H';
%     fn = '~/Box/UCSF-Oxford-RCS-Modelling-Entrainment/Data/DataSet2/StimON/RCS10L/Session1620068354699/DeviceNPC700436H';
    fn = '/Users/juananso/Starr Lab Dropbox/RCS09/SummitData/SummitContinuousBilateralStreaming/RCS09R/Session1621621908173/DeviceNPC700449H';

    sessionName = 'Session1621621908173';
    
%     savedir = '~/Box/RC-S_Studies_Regulatory_and_Data/Patient In-Clinic Data/RCS10/study_visits/v07_gamma_entrainment/Figures/';
    savedir = '~/Box/RC-S_Studies_Regulatory_and_Data/Patient In-Clinic Data/RCS09/study_visits/v08_gamma_entrainment/Figures/';
        
    % add libraies
    addpath(' /Users/juananso/Dropbox (Personal)/Work/Git_Repo/UCSF-rcs-data-analysis/code')

    % create rc plotter object
    rc = rcsPlotter();
    rc.addFolder(fn);
    rc.loadData();

    % plot time domain
    hfig1 = figure('Color','w');
    hsb = gobjects();
    nplots = 5;
    for i = 1:nplots-1    
        hsb(i,1) = subplot(nplots,1,i)    
        rc.plotTdChannel(i,hsb(i,1))
    end
    linkaxes(hsb,'x');
    
    % Identifying segments of data wiht change in stimulation
    numRecs = size(rc.Data.stimLogSettings,1);
    stimSequence = table();
    timeFormat = sprintf('%+03.0f:00',rc.Data.metaData.UTCoffset);
    for ii=1:numRecs
        time = rc.Data.stimLogSettings.HostUnixTime(ii);
        stimSequence.DerivedTime(ii) = datetime(time/1000,...
                'ConvertFrom','posixTime','TimeZone',timeFormat,'Format','dd-MMM-yyyy HH:mm:ss.SSS');
        stimSequence.StimParams{ii} = rc.Data.stimLogSettings.stimParams_prog1{ii};
    end

    % plot spectrogram
%     hfig2 = figure('Color','w');
    hfig2 = figure('units','normalized','outerposition',[0 0 1 1]);
    hsb = gobjects();
    nplots = 5;
    for i = 1:nplots-1
        hsb(i,1) = subplot(nplots,1,i)    
        rc.plotTdChannelSpectral(i,hsb(i,1))
    end
    hsb(5,1) = subplot(nplots,1,5);
    idxma = strfind(stimSequence.StimParams{1},'mA');
    for ii=1:size(stimSequence,1)
        stimVals(ii) = str2num(stimSequence.StimParams{ii}(idxma-3:idxma-1));        
    end
    plot(stimSequence.DerivedTime,stimVals,'s','MarkerFaceColor','red','MarkerSize',10);
    axis tight
    ylabel('Stim Amp (mA)')
    xlabel('date time(hh:mm)')
    set(hsb,'FontSize',16)
%     linkaxes(hsb,'x');

    %% Plot 60 seconds chuncks
    DURATION_CHUNCK = seconds(60);
    hfig3 = figure('Color','w')
    hsb = gobjects();
    nplots = 4
    for i = 1:nplots    
        hsb(i,1) = subplot(2,2,i)    
        rc.plotTdChannelPsd(i,DURATION_CHUNCK,hsb(i,1))
    end
    
    %% Plot M1 channel for each Stim Change Event
    sr = rc.Data.timeDomainSettings.samplingRate(1);
    hfig4 = figure('units','normalized','outerposition',[0 0 1 1]), hold on
    stimContacts = char(rc.Data.stimSettingsOut.activeGroup);
    patientSide = rc.Data.metaData.subjectID
    title(patientSide)
    for ii=1:size(stimSequence,1)-1
        tstart = stimSequence.DerivedTime(ii);
        tend = stimSequence.DerivedTime(ii+1);
        idxUse = (rc.Data.combinedDataTable.localTime >= tstart & rc.Data.combinedDataTable.localTime <= tend);
        tdch = rc.Data.combinedDataTable.TD_key3(idxUse);
        idxnotnan = ~isnan(tdch);
        if length(tdch(idxnotnan))>sr
            [fftOut,ff]   = pwelch(tdch(idxnotnan),sr,sr/2,0:1:sr/2,sr,'psd');
            hplt(ii) = plot(ff,log10(fftOut),'LineWidth',2);
        end
        legend(hplt(1:ii),char(stimSequence.StimParams{1:ii}))
        ylabel('Power (log_1_0\muV^2/Hz)');
        xlabel('Hz');
    end    
%     xlim([60 80])
    set(gca,'FontSize',20)
    
    
%% save figure
figname = [sessionName,'_',patientSide];
saveas(hfig2,[savedir,figname,'_SPECTROGRAM'],'png')
saveas(hfig4,[savedir,figname,'_PSD_focused'],'png')

    
% end