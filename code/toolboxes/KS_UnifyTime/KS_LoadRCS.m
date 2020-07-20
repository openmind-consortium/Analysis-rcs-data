close all
clear all
clc
%%
% Load RC+S data using Ro'ees Matlab functions
fileToLoad = 'C:\Users\Kristin Sellers\Desktop\RCS_Data\Session1573236086189\DeviceNPC700419H';
% fileToLoad = 'C:\Users\Kristin Sellers\Desktop\RCS_Data\sample_data_gaps_stim_changes\Session1580160747770\DeviceNPC700239H';
% fileToLoad = 'C:\Users\Kristin Sellers\Desktop\RCS_Data\sample_data_gaps_stim_changes\Session1580161006112\DeviceNPC700239H';
% fileToLoad = 'C:\Users\Kristin Sellers\Desktop\RCS_Data\sample_data_gaps_stim_changes\Session1580161099214\DeviceNPC700239H';
% fileToLoad = 'C:\Users\Kristin Sellers\Desktop\RCS_Data\sample_data_gaps_stim_changes\Session1580161643936\DeviceNPC700239H';

% Long examples
% fileToLoad = 'C:\Users\Kristin Sellers\Desktop\RCS_Data\RCS_long_data_examples\Session1541628128409\DeviceNPC700395H';
% fileToLoad = 'C:\Users\Kristin Sellers\Desktop\RCS_Data\RCS_long_data_examples\Session1568667718731\DeviceNPC700239H'; 
% fileToLoad = 'C:\Users\Kristin Sellers\Desktop\RCS_Data\RCS_long_data_examples\Session1568860301794\DeviceNPC700419H';
% fileToLoad = 'C:\Users\Kristin Sellers\Desktop\RCS_Data\RCS_long_data_examples\Session1575962227148\DeviceNPC700424H';

% fileToLoad = 'C:\Users\Kristin Sellers\Desktop\RCS_Data\AmbiguousPacketLoss\Session1583435849518\DeviceNPC700354H';
%%
jsonobj = deserializeJSON([fileToLoad filesep 'RawDataTD.json']);
[outtable, srates] = unravelData(jsonobj);
unifiedTimes = unifyTime_KS(outtable);
%%
% Convert unifiedTimes to unixtime
staticTimeToAdd = 951897600; % Elapsed time from Jan 1, 1970 March 1, 2000 at midnight 
calculatedPacketUnixTimes = (unifiedTimes / 10000) + staticTimeToAdd;
%%
% Packets with NaN times should be deleted

% KS: To Do


%%
% Create timestamp for each sample within packets

% KS: To Do 