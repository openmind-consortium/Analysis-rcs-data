classdef write_state < handle
    %
    %   write_state
    
    properties
        I
        n
        
        %arrays
        buffer  %data
        depth   %depth
        next
        type
        index
        %arrays
        
        out
        out_I
        indent = true;
    end
    
    
    methods
        function obj = write_state()
            obj.I = 0;
            obj.n = 1;
            obj.buffer = cell(1,100);
            obj.depth = zeros(1,100,'uint8');
            obj.next = zeros(1,100);
            obj.type = zeros(1,100,'uint8');
            obj.index = zeros(1,100,'uint8');
            obj.out = zeros(1,1000,'uint8');
            obj.out_I = 0;
        end
    end
    
    methods
        function initStructArray(obj)
            %
            %
            %   
            
            if obj.indent
                cur_depth = obj.depth(obj.I);
                str_to_add = uint8([repmat(32,1,cur_depth*5) 91 10]);
                h__addString(obj,str_to_add);
            else
                str_to_add = uint8([91 10]);
                h__addString(obj,str_to_add);
            end
            obj.indent = true;
        end
        function addNextObjectArrayElement(obj)
            %
            %
            %   Should be either:
            %   1) Structure array
            %   2) Cell array
            
            cur_data = obj.buffer{obj.I};
            current_index = obj.index(obj.I);
            if current_index == length(cur_data)
                %close array
                cur_depth = obj.depth(obj.I);
                str_to_add = uint8([10 repmat(32,1,cur_depth*5) 93 10]);
                h__addString(obj,str_to_add);
                obj.I = obj.next(obj.I);
                return
            end
            
            next_index = current_index + 1;
            obj.index(obj.I) = next_index;
            
            s = obj.buffer{obj.I}(next_index);
            addStructToBuffer(obj,s)
        end
    end
    methods
        function initCellArray(obj)
            
        end
        function addArrayElement(obj)
            
        end
    end
    methods
        function initObject(obj)
            if obj.indent
                cur_depth = obj.depth(obj.I);
                str_to_add = uint8([repmat(32,1,cur_depth*5) 123 10]);
                h__addString(obj,str_to_add);
            else
                str_to_add = uint8([123 10]);
                h__addString(obj,str_to_add);
            end
            obj.indent = true;
        end
        function addNextKey(obj)
            %
            %   - at parent
            
            s = obj.buffer{obj.I};
            fn = fieldnames(s);
            
            current_index = obj.index(obj.I);
            handle_close = true;
            cur_depth = obj.depth(obj.I);
            
            if current_index == length(fn)
                %
                %   - close object
                str_to_add = uint8([10 repmat(32,1,cur_depth*5) 125 10]);
                h__addString(obj,str_to_add);
                obj.I = obj.next(obj.I);
                return
            end
            
            next_index = current_index + 1;
            obj.index(obj.I) = next_index;
            cur_name = fn{next_index};
            
            %Add
            str_to_add = uint8([repmat(32,1,(cur_depth+1)*5) 34 ...
                uint8(cur_name) 34 58 32]);
            h__addString(obj,str_to_add);
            obj.indent = false;
            
            
            %If simple, just convert
            %- string
            %- logical
            %- numeric
            
            %Process key value
            %----------------------------------------
            next_value = s.(cur_name);
            
            if isstruct(next_value)
                obj.addStructToBuffer(next_value)
                handle_close = false;
            elseif iscell(next_value)
                %- cellstr
                %- all numeric ...
                str_to_add = uint8('CELL - FIX ME');
                h__addString(obj,str_to_add);
            else
                if isnumeric(next_value)
                    h__addNumericToString(obj,next_value)
                elseif ischar(next_value)
                    h__convertAndAddString(obj,next_value);
                else
                    keyboard
                end
            end
            
            
            if handle_close
                obj.indent = true;
                if next_index == length(fn)
                    %close
                    str_to_add = uint8([10 repmat(32,1,cur_depth*5) 125 10]);
                    h__addString(obj,str_to_add);
                    obj.I = obj.next(obj.I);
                else
                    %add comma
                    h__addString(obj,uint8([44 10]))
                end
                
            end
        end
        function addStructToBuffer(obj,s)
            next_I = obj.I + 1;
            obj.n = next_I;
            
            obj.buffer{next_I} = s;
            obj.depth(next_I) = obj.depth(obj.I)+1;
            obj.index(next_I) = 0;
            obj.next(next_I) = obj.I;
            
            %TODO: We can't support matrices yet ...
            if length(s) > 1
                obj.type(next_I) = 0;
            else
                obj.type(next_I) = 1;
            end
            
            obj.I = obj.I + 1;
        end
        function addCellToBuffer(obj)
            
        end
    end
    
end

function h__addNumericToString(obj,numeric_value)

%NOT YET IMPLEMENTED
if isscalar(numeric_value)
    str_to_add = uint8(sprintf('%g',numeric_value));
    h__addString(obj,str_to_add)
elseif isvector(numeric_value)
    %For right now we'll write as a single array ...
    keyboard
elseif ismatrix(numeric_value)
    %row or column major ...
    keyboard
else
    keyboard
end
end

% function h__addStringsToString(obj,string_value)
% % h__addString(obj,uint8('STRING GOES HERE'));
% % return
% 
% %NOT YET IMPLEMENTED
% if isscalar(string_value)
%     h__convertAndAddString(obj,string_value)
% elseif isvector(string_value)
%     keyboard
% elseif ismatrix(string_value)
%     %row or column major ...
%     keyboard
% else
%     keyboard
% end
% end

function h__convertAndAddString(obj,str)
    str_to_add = [34 uint8(str) 34];
    h__addString(obj,str_to_add)
end

function h__addString(obj,str_to_add)
end_I = obj.out_I + length(str_to_add);
if length(obj.out) < end_I
    temp = obj.out;
    obj.out = zeros(1,2*length(temp));
    obj.out(1:length(temp)) = temp;
end
obj.out(obj.out_I+1:end_I) = str_to_add;
obj.out_I = end_I;
end
