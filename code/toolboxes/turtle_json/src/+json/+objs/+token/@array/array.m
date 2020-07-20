classdef array < json.objs.token
    %
    %   Class:
    %   json.objs.token.array
    %
    %   See Also
    %   --------
    %   json.objs.token
    %   json.objs.token.object
    
    %{
        expected_data = [1,4; 2,5; 3,6];
        s = '[[1,2,3],[4,5,6]]';
        s2 = json.stringToTokens(s);
        r = s2.getRootInfo;
        d = r.get2dNumericArray;
        isequal(d,expected_data)
    %}
    
    properties (Constant)
        all_type_strings = {
            'other_type' %0
            '1d_numeric' %1
            '1d_string'  %2
            '1d_logical' %3
            '1d_objects_same_type' %4
            '1d_objects_diff_type' %5
            'nd_numeric'    %6
            'nd_string'     %7
            'nd_logical'    %8
            }
    end
        
    properties
        name
        full_name
    end
    
    properties (Dependent)
        n_elements
        array_depth
        array_type
        array_type_string
        dimensions
    end
    
    methods
        function value = get.n_elements(obj)
           value = obj.p__n_elements;
           if isempty(value)
               lp = obj.mex;
               array_data_index = lp.d1(obj.md_index)+1;
               array_info = lp.array_info;
               value = array_info.child_count_array(array_data_index);
               obj.p__n_elements = value;
           end  
        end
        function value = get.array_depth(obj)
           value = obj.p__array_depth;
           if isempty(value)
               lp = obj.mex;
               array_data_index = lp.d1(obj.md_index)+1;
               array_info = lp.array_info;
               value = double(array_info.array_depths(array_data_index));
               obj.p__array_depth = value;
           end  
        end
        function value = get.array_type(obj)
           value = obj.p__array_type;
           if isempty(value)
               lp = obj.mex;
               array_data_index = lp.d1(obj.md_index)+1;
               array_info = lp.array_info;
               value = array_info.array_types(array_data_index);
               obj.p__array_type = value;
           end  
        end
        function value = get.array_type_string(obj)
           value = obj.all_type_strings{obj.array_type+1};
        end
        function value = get.dimensions(obj)
            value = obj.p__dimensions;
            if isempty(value)
               lp = obj.mex;
               array_data_index = lp.d1(obj.md_index)+1;
               array_info = lp.array_info;
               cur_depth = double(array_info.array_depths(array_data_index));
               obj.p__dimensions = array_info.child_count_array(array_data_index:array_data_index+cur_depth-1);
               value = obj.p__dimensions;
            end
        end
    end
    
    properties (Hidden)
       p__n_elements
       p__array_depth
       p__array_type
       p__dimensions
    end
    
    methods
        function obj = array(name,full_name,md_index,mex)
            obj.name = name;
            obj.full_name = full_name;
            obj.md_index = md_index;
            obj.mex = mex;            
        end
        function output = getCellstr(obj)
            %
            %   output = getCellstr(obj)
            %   
            %   cell array of strings => {'as' 'df'}
                        
            output = json_info_to_data(3,obj.mex,obj.md_index);
        end
        function output = get1dNumericArray(obj)
            %
            %   output = get1dNumericArray(obj)
            %   
            %   1d numeric array => [1,2,3,4,5]
            
            output = json_info_to_data(4,obj.mex,obj.md_index,0);            
        end
        function output = get2dNumericArray(obj)
            %
            %   output = get2dNumericArray(obj)
            %
            %   2d numeric array => [1,2,3;
            %                        4,5,6];
            
            output = json_info_to_data(4,obj.mex,obj.md_index,0);  
        end
        function output = getArrayOf1dNumericArrays(obj)
            %
            %   output = getArrayOf1dNumericArrays(obj)       
            %   
            %   array of 1d numeric arrays => {[1,2,3],[4,5],[6]}
            
            output = json_info_to_data(5,obj.mex,obj.md_index);      
        end
        function output = getObjectArray(obj)
            %
            %   Use this when the array holds all objects
            
            lp = obj.mex;
            d1 = lp.d1;
            object_info = lp.object_info;
            next_sibling_index_object = object_info.next_sibling_index_object;
            
            local_array_type = obj.array_type;
            if ~(local_array_type == 4 || local_array_type == 5)
               error('Array of objects not detected')
            end
            
            object_md_index = obj.md_index+1;
            n_objects = obj.n_elements;
            array_full_name = obj.full_name;
            temp_output = cell(1,n_objects);
            for iObject = 1:n_objects
                local_name = sprintf('(%d)',iObject);
                local_full_name = [array_full_name local_name];
                temp_output{iObject} = json.objs.token.object(local_name,local_full_name,object_md_index,lp);
                object_data_index = d1(object_md_index)+1;
                object_md_index = next_sibling_index_object(object_data_index)+1;
            end
            
            output = [temp_output{:}];
        end
    end
    
end
