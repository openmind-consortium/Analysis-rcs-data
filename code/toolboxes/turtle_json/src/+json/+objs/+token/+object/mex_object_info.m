classdef mex_object_info
    %
    %   Class
    %   json.objs.token.object.mex_object_info
    
    %This class is largely meant for debugging. It may be a bit slow
    %to access, so it is only created on demand ...
    
    properties
        n_properties
        next_sibling_md_index
        id
        fields
    end
    
    methods
        function obj = mex_object_info(mex_struct,md_index)
            info = mex_struct.object_info;
            obj_data_index = mex_struct.d1(md_index)+1;
            obj.n_properties = info.child_count_object(obj_data_index);
            obj.next_sibling_md_index = info.next_sibling_index_object(obj_data_index)+1;
            obj.id = info.object_ids(obj_data_index)+1;
            temp = info.objects{obj.id};
            obj.fields = fieldnames(temp);
        end
    end
    
end

