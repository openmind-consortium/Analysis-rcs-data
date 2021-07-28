function  DLpiafilesRCS(PATIENTID,varargin)
% function  DLpiafilesRCS(PATIENTID,[whereTOsaveFILES,whereTOcheckPIA])
% INPUT
%   PATIENTID  should be total name of folder to check ie)  'RCS02'
%
%  
% WILL LOOK ON EXTERNAL HARDDRIVE FOR RCS files
% 
%check pia to see latest files on server, download any new ones for the
%desired patient.
% 
% Prasad Shirvalkar MDPHD 
% May 10,2019
% 2/2021 for RCS



if nargin > 1
    DLpath = varargin{1};   
else   
    localrootdir  ='/Volumes/Prasad_X5/' ;
    DLpath = [localrootdir PATIENTID '/'];
%     (PATIENTID starts at = 20)
end

if nargin > 2
    PIApath = varargin{2};
else
    piaroot = '/datastore_spirit/human/rcs_chronic_pain/rcs_device_data/raw/';
    PIApath = [piaroot PATIENTID '/'];
end

% ssh2_conn = ssh2_config('pia.cin.ucsf.edu','gchin','changeme321',7777); 
%  check pia recursively to DL folders
ssh2_conn = ssh2_config('pia.cin.ucsf.edu','pshirvalkar','11Zasdasd',7777);
ssh2_conn = ssh2_command(ssh2_conn,['ls -R ' PIApath],1);
piafoldershold = ssh2_command_response(ssh2_conn);
diridx = cellfun(@(x) contains(x,'/Device'),piafoldershold);
piafolders_full = piafoldershold(diridx);
%take the folder names after the root
piafolders = erase(piafolders_full,{PIApath,':'});



%  check local harddrive recursively to see if i have these folders (and files).
localfolders = dir(fullfile(DLpath,'**/'));
localfolders2 = localfolders([localfolders.isdir] & contains({localfolders.folder},'/Device')); %keep only directories
localfolders3 = unique({localfolders2.folder}'); 
% remove root from fnames
localfolders4= erase(localfolders3,DLpath);


clc
% Download the folders from pia that are not on the local drive

%     First see which folders to copy over 
% get names after unique root dir
% pianames = piafolders(
[foldersonserver,IA] = setdiff(piafolders,localfolders4);  %which folders  are different?
folderstoDL = piafolders_full(IA);
folderstoDL = erase(folderstoDL, {PIApath,':'});

%     Go through each folder and get all files
if ~isempty(folderstoDL) && ~isempty(folderstoDL{1})
    for f=1:numel(folderstoDL)
        tempfiles=[];
        PIAsubpath  = [PIApath folderstoDL{f} '/'];
        DLsubpath = [DLpath folderstoDL{f} '/'];
        
        ssh2_conn = ssh2_command(ssh2_conn, ['ls ' PIAsubpath],1);
        tempfiles = ssh2_command_response(ssh2_conn);
        
        % make the new local directory
        mkdir(DLpath,folderstoDL{f});
        
        %copy the files
        ssh2_conn = scp_get(ssh2_conn,tempfiles,DLsubpath,PIAsubpath);
        
        disp([PIAsubpath '  and files retrieved from PIA'])
    end
    
    disp([num2str(f) ' total folders retrieved']);
    disp(PATIENTID)
    disp(folderstoDL)
else
    disp('No Files/ Folders to Retrieve - All is up to date')
    
end

% CLOSE THE CONNECTION
ssh2_conn = ssh2_close(ssh2_conn);
