classdef examples
    %
    %   Class:
    %   json.utils.examples
    %
    %   See Also
    %   --------
    %   json_tests.time_example_file

    properties (Constant)
        %I don't think this is used ...
        FILE_LIST = {
            '1.json'        
            'big.json'          
            'canada.json'       
            'citm_catalog.json' 
            'citylots.json'      
            'large-dict.json'   
            'medium-dict.json' 
            'small-dict.json' 
            'twitter.json' 
            'utf8_01.json' 
            'wcon_testfile_new.json' 
            'XJ30_NaCl500mM4uL6h_10m45x10s40s_Ea.json'
            };
        DRIVE_PATH = 'https://drive.google.com/drive/folders/0B7to9gBdZEyGMExwTFA0ZWh1OTA?usp=sharing';
        
        %Apparently we can't download directly from Google drive anymore :/
        %
        %   Actually, this may be possible, with a bit of work ...
        %
        %https://gsuiteupdates.googleblog.com/2015/08/deprecating-web-hosting-support-in.html
        %http://stackoverflow.com/questions/25010369/wget-curl-large-file-from-google-drive
    end
    
    methods (Static)
        function [data,time_info] = speedTokenTest(file_name_or_index,N,option)
            %
            %   [data,time_info] = json.utils.examples.speedTokenTest(file_name_or_index,N,*option)
            %
            %   TODO: Document option ...
            %
            %   Inputs
            %   ------
            %   option :
            %       - 1 - as object
            %       - 2 - as raw struct
            %       - 3 - as object, don't time clearing data
            %       - 4 - as raw struct, don't time clearing data
            %       - 5 - 
            %   
            %   Examples
            %   --------
            %   data = json.utils.examples.speedTokenTest('1.json',10,2)
            
            if nargin < 3
                option = 1;
            end
            
            %turtle_json_mex
            
            if option == 1 || option == 3
                fh = @json.tokens.load;
            elseif option == 2 || option == 4 || option == 5
                fh = @turtle_json_mex;
            end
            
            file_path = json.utils.examples.getFilePath(file_name_or_index);
            
            
            %TODO: Ideally we would discard the first time because
            %it might not be stable ...
            tic
            data = fh(file_path);
            t = toc;
            clear('data')
            
            
            if nargin == 1
                if t > 1
                    N = 4;
                elseif t > 0.1
                    N = 100;
                else
                    N = 1000;
                end
            else
                N = N-1;
            end
            
            if option <= 2
                tic
                for i = 1:N
                    data = fh(file_path);
                end
                t = toc;
            elseif option == 5
                ta = json.utils.time_averager(N);
                for i = 1:N
                    data = fh(file_path);
                    ta.add(data);
                end
            else
                t = 0;
                for i = 1:N
                    tic
                    data = fh(file_path);
                    t = t + toc;
                    if i ~= N
                        clear('data')
                    end
                end
            end
            
            if option == 5
                m = ta.getMeans();
                avg_time = m.total_elapsed_time_mex/1000;
                time_info = ta;
            else
                avg_time = t/(N+1);
                time_info = avg_time;
            end
                if avg_time > 1
                    fprintf('avg elapsed time: %0.2f (s)\n',avg_time);
                else
                    fprintf('avg elapsed time: %0.2f (ms)\n',1000*avg_time);
                end    
        end
        function data = speedDataTest(file_name_or_index,N,option)
            %
            %   json.utils.examples.speedDataTest(file_name_or_index)
            
            %option
            %1) this
            %2) jsondecode
            %3) cpanton - fromjson
            %4) loadjson
            %5) c++ json - json_read
            
            if nargin < 3
                option = 1;
            end
            
            %turtle_json_mex
            
            if option == 1
                fh = @json.load;
            elseif option == 2
                fh = @(x)jsondecode(fileread(x));
            elseif option == 3
                fh = @(x)fromjson(fileread(x));
            elseif option == 4
                fh = @loadjson;
            elseif option == 5
                fh = @json_read;
            end
            
            file_path = json.utils.examples.getFilePath(file_name_or_index);
            tic
            data = fh(file_path);
            t = toc;
            if nargin == 1
                if t > 1
                    N = 4;
                elseif t > 0.1
                    N = 100;
                else
                    N = 1000;
                end
            else
                N = N - 1;
            end
            
            for i = 1:N
            	data = fh(file_path);
            end
            t = toc;
            
            avg_time = t/(N+1);
            if avg_time > 1
                fprintf('avg elapsed time: %0.2f (s)\n',avg_time);
            else
                fprintf('avg elapsed time: %0.2f (ms)\n',1000*avg_time);
            end
        end
        function file_path = getFilePath(file_name_or_index)
            %
            %   file_path = json.utils.examples.getFilePath(file_name_or_index)
            %
            %   TODO: allow regex if strcmp fails
            
            root_path = json.utils.examples.getExamplesRoot();
            if ischar(file_name_or_index)
                file_name = file_name_or_index;
            else
                file_name = json.utils.examples.FILE_LIST{file_name_or_index};
            end
            file_path = fullfile(root_path,file_name);
            if ~exist(file_path,'file')
                %1) - file not downloadded
                %2) - partial file name given ...
                if ischar(file_name_or_index)
                    d = dir(fullfile(root_path,['*' file_name '*']));
                    if isempty(d)
                        error('file missing')
                    elseif length(d) == 1
                        file_path = fullfile(root_path,d.name);
                    else
                        error('Multiple files found for: %s',file_name)
                    end
                else
                    %TODO: provide more info
                    error('File missing')
                end
            end
        end
        function bin_path = getExamplesRoot()
            %
            %   json.utils.examples.getExamplesRoot()
            
            root_path = fileparts(json.sl.stack.getPackageRoot());

            bin_path = fullfile(root_path,'examples'); 
        end
%         function downloadFile(file_name)
%             
%         end
    end
    
end

