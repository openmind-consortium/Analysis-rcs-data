function RCSdatabaseBL = combine_Left_Right_databases(RCSdatabase_outL,RCSdatabase_outR,patientrootdir)

% function combine_Left_Right_databases(PATIENTID)

% This file will combine precomputed RCS databases from the L and R side into one large database, so that the files from each sides can be loaded and processes together. 


% INPUTS:
%   1. RCSdatabase_outL is the table variable database for Left Side
%   2. RCSdatabase_outR is " " for the Right side
%   3. patientrootdir is the root directory above where all patients folders are located
%
% Prasad Shirvalkar MD,PhD
% July 23, 2022


outputpath = patientrootdir;

disp(['Save directory is ' outputpath]);
RIGHT  = RCSdatabase_outR;
LEFT = RCSdatabase_outL;


% Take the  longer database first, and match the shorter one to to the longer one
if size(RIGHT,1)>size(LEFT,1)
RCSdatabaseBL = synchronize(RIGHT,LEFT,'first','nearest'); 

RCSdatabaseBL = timetable2table(RCSdatabaseBL); 
RCSdatabaseBL.Properties.VariableNames{1} = 'time_RIGHT';
% delete all extra rows on LEFT because they will repeat after done

elseif size(RIGHT,1)<size(LEFT,1)
    RCSdatabaseBL = synchronize(LEFT,RIGHT,'first','nearest');

 RCSdatabaseBL = timetable2table(RCSdatabaseBL);
RCSdatabaseBL.Properties.VariableNames{1} = 'time_LEFT';
end 


%  reorder and delete the columns based on what we care about





    
% 
% 
% %SAVE ALL THE STUFFS
% 
% fn=[outputpath ptID '_' activityname '_LFPbilateral.mat'];
% epath=exist(outputpath,'dir');
% if ~(epath==7) %if folder does not exist
%     mkdir(outputpath);
% end
% 
% set(0, 'DefaultUIControlFontSize', 12); %set font back to small
% 
% save(fn,'LFP*','bndpwrbl')
% 
% 
% disp(['LEFT:' Qbl '    RIGHT:' Qbl ' Session(s) were saved under  ' fn ])