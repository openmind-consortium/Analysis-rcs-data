classdef examples
    %
    %   Class:
    %   json.utils.examples
    %
    %   See Also
    %   --------
    %   json_tests.time_example_file

    properties (Constant)
        %https://www.dropbox.com/s/
        %/file_name?d1=1
        
        FILE_INFO = {
            '1.json'                    'laiqo60iyibutk6'   ''
            'apache_builds.json'        'uy6df3hnzrk60uu'   ''
            'apache_builds.min.json'    '46x3qd23zzw1v7w'  ''
            'big.json'                  'bxvs5bxudb8b38a'  ''
            'canada.json'               '5lp5y8uxibmcep7'  ''
            'citm_catalog.json'         'ut14v8kr3zso0af'  ''
            'citylots.json'             '6ahnwmiybc3arhc'  ''
            'github_events.json'        '2ojeq1k7d2n5ide'  ''
            'github_events.min.json'    'f3dbs8kdn2l8918'  ''
            'instruments.json'          'o5s42w9ypdrdul3'  ''
            'instruments.min.json'      't7cgiq90kjqia0u'  ''
            'large-dict.json'           '1hfmqq12tt18k57'  ''
            'medium-dict.json'          'rb068joka70zfm1'  ''
            'mesh.json'                 'eas0in9dl7hf3ye'  ''
            'mesh.min.json'             'v056u7h4u66h3ra'  ''
            'small-dict.json'           '95foa7a638gct9t'  ''
            'svg_menu.json'             '5gvgfm4fkxrp0ou'  ''
            'svg_menu.min.json'         '3o9kuyyux2ahjvy'  ''
            'twitter.json'              'wyia47hbyus5dd2'  ''
            'twitter.min.json'          '8ffm49nkiw3ltq8'  ''
            'update-center.json'        'c5nocyy9g4js4st'  ''
            'update-center.min.json'    'mx8de1gpyz015pb'  ''
            'utf8_01.json'              'sacbncuxfctjqwz'  ''
            'wcon_testfile_new.json'    'mfk2rodxqov1fn4'  'created for OpenWorm project, array heavy'
            'XJ30_NaCl500mM4uL6h_10m45x10s40s_Ea.json' 'fxmzbo02yjz00o4' 'created for OpenWorm project, array heavy'
            };
    end
    
    properties
        file_names
        online_ids
        descriptions
        table
    end
    
    methods
        function obj = examples()
            %
            %   obj = json.utils.examples
            %
            %   ex = json.utils.examples()
            
            temp = obj.FILE_INFO;
            
            obj.file_names = temp(:,1);
            obj.online_ids = temp(:,2);
            obj.descriptions = temp(:,3);
            
            s = struct('file_names',obj.file_names,...
                'online_ids',obj.online_ids,...
                'descriptions',obj.descriptions);
            
            obj.table = struct2table(s);
        end
        function downloadFile(obj,file_name)
            %
            %
            %   Example
            %   -------
            %   ex = json.utils.examples
            %   ex.downloadFile('apache_builds.json')
            
            %https://www.dropbox.com/s/
            %/file_name?d1=1
            
            %TODO: Verify ends in .json, if not add
            I = find(strcmp(obj.file_names,file_name),1);
            if isempty(I)
                error('unable to find requested file: %s',file_name)
            end
            ID = obj.online_ids{I};
            url = ['https://www.dropbox.com/s/' ID '/' file_name '?dl=1'];
            
            root_path = obj.getExamplesRoot();
            file_path = fullfile(root_path,file_name);
            websave(file_path,url);
        end
    end
    
    methods (Static)
        function [data,time_info] = speedTokenTest(file_name_or_index,N,option)
            %
            %   [data,time_info] = json.utils.examples.speedTokenTest(file_name_or_index,N,*option)
            %
            %   Outputs
            %   -------
            %   data :
            %       Either the raw_mex_struct from the initial parse
            %       or an object, either json.objs.token.object or 
            %       json.objs.token.array
            %   time_info :
            %       for options 1-4 average time is returned
            %       
            %
            %   Inputs
            %   ------
            %   option :
            %       - 1 - as object
            %       - 2 - as raw struct
            %       - 3 - as object, don't time clearing data
            %       - 4 - as raw struct, don't time clearing data
            %       - 5 - as raw struct, provides more timing detail
            %             as an output in 'time_info'
            %   
            %   Examples
            %   --------
            %   data = json.utils.examples.speedTokenTest('1.json',10,2)
            %
            %   [data,time_info] = json.utils.examples.speedTokenTest('wcon',10,5)
            %   time_info.dm() %display averages
            %
            %   See Also
            %   --------
            %   json.utils.time_averager
            %   json.objs.token.object
            %   json.objs.token.array
            
            
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
                %This is because we ran once above
                %
                %Ideally we would clarify this to the user if they
                %are expecting more 
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
            %   data = json.utils.examples.speedDataTest(file_name_or_index,N,*option)
            %
            %   Note, these require additional librarise to be on the path
            %
            %   Optional Inputs
            %   ---------------
            %   option : scalar
            %       - 1 this
            %       - 2 jsondecode  (MATLAB's version)
            %       - 3 cpanton - fromjson
            %       - 4 loadjson
            %       - 5 c++ json - json_read
            %
            %   Examples
            %   --------
            %   json.utils.examples.speedDataTest('wcon',10);
            
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
        function file_path = getFilePath(file_name_or_index,varargin)
            %
            %   file_path = json.utils.examples.getFilePath(file_name_or_index)
            
            in.download = true;
            in = json.sl.in.processVarargin(in,varargin);
            
            ex = json.utils.examples();
            
            
            root_path = ex.getExamplesRoot();
            if ischar(file_name_or_index)
                file_name = file_name_or_index;
                I = find(strcmp(ex.file_names,file_name));
                if isempty(I)
                    I = find(json.sl.cellstr.contains(ex.file_names,file_name,'case_sensitive',false));
                    if isempty(I)
                        error('Unable to find example file with name or partial name of: %s',file_name);
                    elseif length(I) > 1
                        ex.file_names(I)
                        error('Multiple example files with name or partial name of: %s',file_name);
                    else
                        file_name = ex.file_names{I};
                        %all set!
                    end
                elseif length(I) > 1
                    error('Jim code error')
                else
                    %length = 1, all set!
                end
            else
                file_index = file_name_or_index;
                file_name = ex.file_names{file_index};
            end
            file_path = fullfile(root_path,file_name);
            if ~exist(file_path,'file')
                
                if in.download
                    fprintf('Downloading: %s\n',file_name);
                    ex.downloadFile(file_name);
                    fprintf('Downloading complete\n')
                else
                    error('File missing: %s',file_path)
                end
%                 
%                 %1) - file not downloadded
%                 %2) - partial file name given ...
%                 if ischar(file_name_or_index)
%                     d = dir(fullfile(root_path,['*' file_name '*']));
%                     if isempty(d)
%                         error('file missing')
%                     elseif length(d) == 1
%                         file_path = fullfile(root_path,d.name);
%                     else
%                         error('Multiple files found for: %s',file_name)
%                     end
%                 else
%                     %TODO: provide more info
%                     error('File missing')
%                 end
            end
        end
        function bin_path = getExamplesRoot()
            %
            %   json.utils.examples.getExamplesRoot()
            
            root_path = fileparts(json.sl.stack.getPackageRoot());

            bin_path = fullfile(root_path,'examples'); 
        end
    end
    
end

