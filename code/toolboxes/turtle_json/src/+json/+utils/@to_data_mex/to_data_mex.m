classdef to_data_mex
    %
    %   Class
    %   json.utils.to_data_mex
    %
    %   This was written to document these functions in Matlab, rather
    %   than just in mex. They are also called by the tests
    %
    %   See Also
    %   --------
    %   json_tests.toData.functions.f2__get_key_value_type_and_index
    
    properties
    end
    
    methods (Static)
        function [key_value_type,md_index_1b] = f2__get_key_value_type_and_index(s,object_md_index_1b,key_index_1b)
            %
            %   Inputs
            %   ------
            %   s :
            %   object_md_index_1b :
            %   key_index_1b : 
            %
            %   Outputs
            %   -------
            %   key_value_type :
            %   md_index_1b :
            %
            
            [key_value_type,md_index_1b] = json_info_to_data(2,s,object_md_index_1b,key_index_1b);
        end
    end
    
end

