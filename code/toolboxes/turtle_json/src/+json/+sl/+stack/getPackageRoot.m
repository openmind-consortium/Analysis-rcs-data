function package_root = getPackageRoot()
%
%   package_root = sl.stack.getPackageRoot()
%
%   Returns the path of the folder that contains the base package. Note,
%   for classes the folder containing the class is returned (if the class
%   is not in a package).
%
%   Examples:
%   ---------
%   Called from: 'C:\repos\matlab_git\my_repo\+package\my_function.m
%   Returns: 'C:\repos\matlab_git\my_repo\'
%

temp_path = json.sl.stack.getMyBasePath('','n_callers_up',1);

I = strfind(temp_path,'+');
if isempty(I)
    I = strfind(temp_path,'@');
    if isempty(I)
        package_root = temp_path;
        return
    end
end

%subtract off '+' or '@' and the path separator ('/' or '\')
last_char_I  = I(1)-2; 
package_root = temp_path(1:last_char_I);

end
