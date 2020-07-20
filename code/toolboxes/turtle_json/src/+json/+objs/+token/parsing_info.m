classdef parsing_info
    %
    %   Class:
    %   json.objs.token.parsing_info
    
    properties
       ns_per_char
       timing_info
       
       d_content = '---------- content  --------'
       chars_per_token
       
       
       d_allocation = '---------- allocation info (ai) --------'
       main_ai
       object_ai
       array_ai
       key_ai
       string_ai
       number_ai
       
       memory_allocation_estimate_mb
       memory_used_estimate_mb
       memory_allocated_to_file_size_ratio
       memory_used_to_file_size_ratio
    end
    
    methods
        function obj = parsing_info(result)
            
            
            %Elapsed time
            %--------------------------------------------------------
            ti = result.timing_info;
            non_read_time = ti.total_elapsed_time_mex - ti.elapsed_read_time;
            ti.non_read_time = non_read_time;
            obj.timing_info = ti;
            obj.ns_per_char = 1e9*non_read_time/length(result.json_string);

            obj.chars_per_token = length(result.json_string)/length(result.d1);
            
            ai = result.allocation_info;
                        
            obj.main_ai = h__createAISummaryString(ai.n_tokens_allocated,...
                length(result.d1),ai.n_data_allocations);
            obj.object_ai = h__createAISummaryString(ai.n_objects_allocated,...
                length(result.object_info.child_count_object),ai.n_object_allocations);
            obj.array_ai = h__createAISummaryString(ai.n_arrays_allocated,...
                length(result.array_info.child_count_array),ai.n_array_allocations);
            obj.key_ai = h__createAISummaryString(ai.n_keys_allocated,...
                length(result.key_info.key_p),ai.n_key_allocations);
            obj.string_ai = h__createAISummaryString(ai.n_strings_allocated,...
                length(result.string_p),ai.n_string_allocations);
            obj.number_ai = h__createAISummaryString(ai.n_numbers_allocated,...
                length(result.numeric_p),ai.n_numeric_allocations);

            %TODO: Reimplement memory estimates
%             obj.memory_allocation_estimate_mb = ((1+4+4)*obj.n_tokens_allocated + ...
%                 (8 + 4)*obj.n_keys_allocated + ...
%                 (8 + 4)*obj.n_strings_allocated + ...
%                 (8)*obj.n_numbers_allocated)/1e6;
%             
%             obj.memory_used_estimate_mb = ((1+4+4)*obj.n_tokens + ...
%                 (8 + 4)*obj.n_keys + ...
%                 (8 + 4)*obj.n_strings + ...
%                 (8)*obj.n_numbers)/1e6;
            
            %obj.memory_allocated_to_file_size_ratio = obj.memory_allocation_estimate_mb/(length(result.json_string)/1e6);
            %obj.memory_used_to_file_size_ratio = obj.memory_used_estimate_mb/(length(result.json_string)/1e6);
            
            %TODO: Provide estimate of memory consumption
            %types + 4*d1 + 4*d2 + 8*numeric_data
            %- also need string_p, key_p, numeric_p 
        end
    end
    
end

function str = h__createAISummaryString(n_allocated,n_actual,n_allocations)
    if n_allocations == 1
        plural_string = '';
    else
        plural_string = 's';
    end
    str = sprintf('%%%5.2f: %10d/%-10d, %d allocation%s', ...
        100*double(n_actual)/double(n_allocated),n_actual,n_allocated,n_allocations,plural_string);
end
