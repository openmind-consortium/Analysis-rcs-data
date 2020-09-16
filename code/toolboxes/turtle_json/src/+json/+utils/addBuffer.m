function out_data = addBuffer(in_data)
%
%   out_data = json.utils.addBuffer(in_data)
%
%   This is currently largely for internal testing ...

if ischar(in_data)
    out_data = [in_data char([0,92,34,0,0,0,0,0,0,0,0,0,0,0,0,0,0])];
else
    out_data = [in_data uint8([0,92,34,0,0,0,0,0,0,0,0,0,0,0,0,0,0])];
end

end