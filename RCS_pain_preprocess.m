% This is the first attempt at preprocessing RC+S data using the new deserialization pipeline
% This will create combined MAT files for all recording sessions and create
% a database index of all files
% 
% MUST USE MATLAB 2019a or earlier (given JSON issue) 
% 
% Prasad Shirvalkar Nov 11, 2020
 

% define locations of JSON file inputs,  MAT file outputs 
loaddir = '/Users/pshirvalkar/Desktop/RCS_repo.nosync/CPRCS01/SummitData/SummitContinuousBilateralStreaming/CPRCS01/Session1573619434071/DeviceNPC700435H';
matfile_dir = '/Users/pshirvalkar/Desktop/RCS_repo.nosync/CPRCS01/preprocessed/';
github_dir = '/Users/pshirvalkar/Documents/GitHub/UCSF-rcs-data-analysis';

cd(github_dir)
addpath(genpath(github_dir))


%%  Check if mat file exists, if not, load raw data and save to new matfile

for j = 1:length(filesLoad)
    if ismac || isunix
        ff = findFilesBVQX(matfile_dir,filesLoad{j});
    elseif ispc
        ff = {fullfile(matfile_dir,filesLoad{j})};
    end

    [fileExists, fn] = checkIfMatExists(ff{1});
    if fileExists
        disp([fn ' exists...'])
    else
        

                %only outputting TD data right now
                    % NOTE: I edited   'assigntime.m' to add a field called Time (human
                    % readable time converted from Unix time based on TimeZone)

                    %Demo  wrapper updated by me to export settings;
                    [data,settings] = DEMO_ProcessRCS(loaddir) ;



                       %SAVE COMBINED FILE with all settings and data here in future. 
                                          save(fullfile(dirname,[filesLoad{j} '.mat']),'data','settings');

    end
    
        
        
%         
% function [fileExists, fnout] = checkIfMatExists(fn)
% [pn,fn,ext] = fileparts(fn);
% if exist(fullfile(pn,[fn '.mat']),'file')
%     fileExists = 1; 
%     fnout = fullfile(pn,[fn '.mat']);
% else
%     fileExists = 0; 
%     fnout = [];
% end
% end

end






%%   Kurtosis find periods of stim

close all
winsize = 3000
noverlap = 0.1
d = data.key1;
  
k = movwin(d,winsize,noverlap,@kurtosis);
plot(linspace(1,numel(k),numel(d)),d)
hold on 
plot(k)
%find periods of stimulation
[p,l]= findpeaks(k,'threshold',0.5,'MinPeakProminence',3)