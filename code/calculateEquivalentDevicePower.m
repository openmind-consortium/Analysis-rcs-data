function newPowerFromTimeDomain = calculateEquivalentDevicePower(dataSource, settings, calculationType)
% calculates equivalent device power as a function of user chosen power
% bands
% 
% Input = 
% (1) dataSource: combinedDataTable or path to saved combinedDataTable.mat
% (2) settings: cell with two structures
%       1 = fftSettings (type = output from DEMO_Process)
%       2 = powerSettings (type = output from DEMO_Process)
%       3 = metaData (type = output from DEMO_Process)
% (3) calculationType:
%       1 = use parameters within recording
%       2 = user input parameters
% 
% Variable parameters as user input
% - powerSettings (user can choose differnt band based on same fft settings)
% - fftSettings (for now will leave this as the recording ones)
% 
% First prototype focuses only on user selecting a different power band
%

% Parse input variables, indicating dataSource and calculationType
if istable(dataSource) && size(dataSource,2) == 27 % NOTE this condition could change in the future
    combinedDataTable = dataSource;
    fftSettings = settings{1};
    powerSettings = settings{2};
    metaData = settings{3};
    disp('table in memory')
elseif isfile(dataSource)
    [filepath, fname, fext] = fileparts(dataSource);
    if strcmp([fname,fext],'combinedDataTable.mat')
        load(fullfile(filepath,'combinedDataTable.mat'));
        disp('file loaded in memory, combined data table loaded')
    else
        error('wrong file path')
    end
   
end

if calculationType == 1
    disp('Use parameters within recording')
    newPowerFromTimeDomain = createNewPowerTableFromTimeDomain(combinedDataTable,fftSettings,powerSettings,metaData);
elseif calculationType == 2
    disp('Choose input parameters (power bands)')
    numBands = input('how many power bands you want to compute (enter integer number, eg. 2)?');
    newPowerSettings = powerSettings; % initialize with the default sesttings
    for iBand = 1:numBands
        disp(strcat('For power band ',num2str(iBand),'...'));
        disp(powerSettings.powerBands.fftBins);
        binNums = input('choose bin numbers from this list (integer, eg. for bins 1, 2, 3, enter: [1,2,3])');
        newPowerSettings.powerBands.indices_BandStart_BandStop(iBand,1) = binNums(1);
        newPowerSettings.powerBands.indices_BandStart_BandStop(iBand,2) = binNums(end);
    end
    newPowerFromTimeDomain = createNewPowerTableFromTimeDomain(combinedDataTable,fftSettings,newPowerSettings,metaData);
end
   
end