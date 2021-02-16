function output = getPerformanceLog(mex_struct,use_ms_time)
%X Retrieve mex c-struct from turtle_json as Matlab structure
%
%   output = json.utils.getPerformanceLog(mex_struct,*use_ms_time)
%
%   Note, this is only for debugging and is not optimized for running in a
%   loop when reading multiple files. Note, if used in a loop when
%   debugging that is OK as the timing information needed to assess
%   performance is contained in this structure.
%
%   See Also
%   --------
%
%
%   TODO: rename tj_get_log_struct_as_mx
%
%   Improvements
%   ------------
%   1) TODO: Add on fields to delineate each section ...

%This is the mex call ... (see private folder)
output = tj_get_log_struct_as_mx(mex_struct.slog);

if nargin < 2
    use_ms_time = false;
end

if output.qpc_freq ~= 0
	scale_factor = 1/(1e6*output.qpc_freq);
else
    scale_factor = 1;
end
    
if use_ms_time
	scale_factor = 1000*scale_factor;
end

%Scaling any time fields ...
if scale_factor ~= 1
    fn = fieldnames(output);
    mask = strncmp(fn,'time__',6);
    time_fn = fn(mask);
    for i = 1:length(time_fn)
        cur_name = time_fn{i};
        output.(cur_name) = scale_factor*output.(cur_name);
    end
end

%Was going to keep 2 digits but we are way off sometimes ...
%fh = @(x) round(x*100*1e4)/1e4;

%TODO: Unfortunately our counts are integers, ideally we would return
%doubles so that any MATLAB math would work ...
fh = @(x,y) double(x)/double(y)*100;

output.pct_allocations = '---------------------------------';
output.pct_tokens_used = fh(output.n_tokens,output.alloc__n_tokens_allocated);
output.pct_arrays_used = fh(output.n_arrays,output.alloc__n_arrays_allocated);
output.pct_numbers_used = fh(output.n_numbers,output.alloc__n_numbers_allocated);
output.pct_objects_used = fh(output.n_objects,output.alloc__n_objects_allocated);
output.pct_keys_used = fh(output.n_keys,output.alloc__n_keys_allocated);
output.pct_strings_used = fh(output.n_strings,output.alloc__n_strings_allocated);

end