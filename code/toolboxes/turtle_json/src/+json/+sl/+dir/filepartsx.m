function path_out = filepartsx(file_or_folder_path,N)
%filepartsx   Applies fileparts() function numerous times
%
%   path_out = sl.dir.filepartsx(file_or_folder_path,N)
%
%   Small function to help clean up stripping of the path.
%
%   INPUTS:
%   -------
%   file_or_folder_path : path to file or folder
%   N                   : # of times to apply fileparts() function
%
%   Example:
%   --------
%   file_path = 'C:\my_dir1\my_dir2\my_file.txt';
%   path_out  = sl.dir.filepartsx(file_path,2);
%
%   path_out  => 'C:\my_dir1'
%
%   file_paths = {'C:\my_dir1\my_dir2\my_file.txt'; 'C:\my_dir1\my_dir3\my_file.txt';};
%   path_out  = sl.dir.filepartsx(file_paths,1);
%
%   See Also:
%   ---------
%   sl.dir.getFileName

if iscell(file_or_folder_path)
   path_out = cellfun(@(x) h__filepartsx_main(x,N),file_or_folder_path,'un',0);
else
   path_out = h__filepartsx_main(file_or_folder_path,N);
end

end

function path_out = h__filepartsx_main(file_or_folder_path,N)
path_out = file_or_folder_path;
for iN = 1:N
   path_out = fileparts(path_out); 
end

end