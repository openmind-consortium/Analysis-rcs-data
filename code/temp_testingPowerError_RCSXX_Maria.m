
% Get repo parent directory path
fp = matlab.desktop.editor.getActiveFilename;
fp = convertCharsToStrings(fp);
fp = extractBefore(fp, "main");
% Save in all functions into matlab path
addpath(fp);
% Part 1: create & load 'AllDataTables.mat'
%bug -- breaks with twiddle '~'
in_fp = '/Users/juananso/Box/RC-S_Studies_Regulatory_and_Data/Patient In-Clinic Data/RCS14/InClinicVisits/v03_4wk_preprogramming/Data/aDBS/RCS14L/Session1618936204126/DeviceNPC700481H';
ProcessRCS(in_fp); % bug -- output is not matlab obj, some strange double
out_matobj_fp = (in_fp + "/AllDataTables.mat");
load(out_matobj_fp)
% Part 2: create combinedDataTable
dataStreams = {timeDomainData, AccelData, PowerData, FFTData, AdaptiveData};
[combinedDataTable] = createCombinedTable(dataStreams,unifiedDerivedTimes,metaData);
%Part 3: plotting helper for RC+S files
% -- plot time domain data
rc = rcsPlotter();
rc.addFolder(in_fp); 
rc.loadData()
rc.plotTdChannel(1)
%Part 4: Plot PSD
% Comparing 'off line' power data with the RCS streamed for default fft and power settings
[combinedPowerTable, powerTablesBySetting] = getPowerFromTimeDomain(combinedDataTable,fftSettings, powerSettings, metaData, 2);