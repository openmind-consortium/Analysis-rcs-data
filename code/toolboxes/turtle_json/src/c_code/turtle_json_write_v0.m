function str = turtle_json_write_v0(s)

state = write_state();


%buffer of pointers to each element before diving

%{
s = json.loadExample('XJ30');
turtle_json_write_v0(s)
%}

%Part 1


%   Needs Buffer
%   --------------
%   {"a":1,"b":2}
%   ["a",1,2,"b",[1,2,3,4,"c"]]
%
%
%   1) array : next 0 p 0
%   2) "a"   : next 3
%   3) 1     : next 4
%   4) 2     : next 5
%   5) "b"   : next 6
%   6) array : next 0 p 1
%   7) 1     : next 8
%   8) 2     : next 9
%
%   Each buffer needs:
%   -------------------
%   data :
%   depth :
%       0 - top level
%   next :
%   type :
%       0 - array of objects (struct array)
%       1 - object (single struct)
%       2 - array (cell array)
%       3 - key
%
%
%   Or rather ****
%   1) array : next 0 p 0
%       - process "a",1,2,"b",
%   2) array : next 0 p 1
%       - process entire array
%       - close array
%       - goto parent
%       - close parent
%
%   - structure and structure array
%   - cell array that is not a cellstr
%
%   No Buffer
%   ----------
%   [1,2,3,4,5]
%   ["a","b"]
%   [[1,2],[3,4]]
%
%   - string
%   - number
%   - bool
%   - cellstr
%


state.buffer{1} = s;
state.I = 1;
if isstruct(s)
    if length(s) > 1
        %array of objects
        state.type(1) = 0;
    else
        state.type(1) = 1;
    end
elseif iscell(s)
    state.type{1} = 2;
else
    error('Expected cell or struct for writing JSON to string')
end

while (true)
    if state.I == 0
        break
    end
    
    %cur_item = state.buffer{state.I};
    switch state.type(state.I)
        case 0
            %array of objects
            if state.index(state.I) == 0
                state.initStructArray();
            end
            
            state.addNextObjectArrayElement();
        case 1
            %object (struct)
            %place each entry on the buffer
            %and advance to next
            
            %Add keys
            %---------------------
            if state.index(state.I) == 0
                state.initObject();
            end
            
            state.addNextKey();
            
            %- init
            %- add key (and process)
            %- close
            
        case 2
            %array (cell array)
        case 3
            %key
        otherwise
    end
end

str = state.out(1:state.out_I);

keyboard


%Options
%----------------------------
%1) column or row major
%2) scalar rules ...
%3)

%Approach
%----------------------------
%Keep track of
%1) # of chars
%2) depth

%Input should be a structure or cell array


end


