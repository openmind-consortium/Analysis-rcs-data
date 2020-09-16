classdef time_averager < handle
    %
    %   Class:
    %   json.utils.time_averager
    
    properties
        I = 0;
        fieldnames = {
        'elapsed_read_time'
        'c_parse_init_time'
        'c_parse_time'
        'parsed_data_logging_time'
        'total_elapsed_parse_time'
        'object_parsing_time'
        'object_init_time'
        'array_parsing_time'
        'number_parsing_time'
        'string_memory_allocation_time'
        'string_parsing_time'
        'total_elapsed_pp_time'
        'total_elapsed_time_mex'
        }
        summary_fields = {
        'total_elapsed_parse_time'    
        'total_elapsed_pp_time'
        }
        
        elapsed_read_time
        d0 = '------  first pass ------'
        c_parse_init_time
        c_parse_time
        parsed_data_logging_time
        total_elapsed_parse_time
        d1 = '-------- post-process --------'
        object_parsing_time
        object_init_time
        array_parsing_time
        number_parsing_time
        string_memory_allocation_time
        string_parsing_time
        total_elapsed_pp_time
        d2 = '-------- Total fcn time -------'
        total_elapsed_time_mex
        
    end
    
    methods
        function obj = time_averager(N)
            for i = 1:length(obj.fieldnames)
                cur_name = obj.fieldnames{i};
                obj.(cur_name) = zeros(1,N);
            end
        end
        function add(obj,data)
            obj.I = obj.I + 1;
            I2 = obj.I;
            temp = json.utils.getMexC(data,true);
            for i = 1:length(obj.fieldnames)
                cur_name = obj.fieldnames{i};
                cur_name2 = ['time__' cur_name];
                obj.(cur_name)(I2) = temp.(cur_name2);
            end
        end
        function s = getMeans(obj)
            s = struct;
            for i = 1:length(obj.fieldnames)
                cur_name = obj.fieldnames{i};
                data = obj.(cur_name);
                s.(cur_name) = mean(data);
            end
        end
        function dm(obj)
            %dm - display means
            s = obj.getMeans();
            disp(s)
        end
        function s = getPercentages(obj)
            s = struct;
            for i = 1:length(obj.fieldnames)
                cur_name = obj.fieldnames{i};
                data = obj.(cur_name);
                s.(cur_name) = mean(data);
            end
            for i = 1:length(obj.fieldnames)
                cur_name = obj.fieldnames{i};
                s.(cur_name) = 100*s.(cur_name)./s.total_elapsed_time_mex;
            end
        end
        function dp(obj)
            %dp - display percents
            s = getPercentages(obj);
            disp(s)
        end
    end
end

