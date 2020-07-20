classdef dict < handle
    %
    %   Class:
    %   sl.obj.dict
    %
    %   This class supports arbitrary property (attribute) names.
    %
    %   All attributes can be accessed via parentheses:
    %       obj.(<property>) e.g. obj.('my awesome property!)
    %
    %   Valid variable names can be accessed via just the dot operator:
    %       obj.<valid_property>  e.g. obj.valid_property
    %
    %   Issues:
    %   -------
    %   1) Providing methods for this class makes property attribute
    %   and method lookup ambiguous. 
    %   2) Tab complete does not work when accessing via parentheses,
    %       e.g.: 
    %           obj.('my_va   <= tab complete wouldn't work
    %           obj.my_va   <= tab complete would work
    %
    %
    %   http://undocumentedmatlab.com/blog/class-object-tab-completion-and-improper-field-names
    
    properties
        props
    end
    
    methods
        %These are internal functions, normally subsasgn will work
        function addProp(obj,name,value)
            %x  Adds a property to the class
            %
            %   addProp(obj,name,value)   
            %
            %   If you are writing code inside a class that inherits
            %   from lazy_dict, then use this method. Otherwise just
            %   treat the class as a structure.
            %
            %   Matlab doesn't support calling subsref inside a function.
            %   This means that the following type of code works
            %   differently inside a class method, vs in other code that 
            %   calls the class:
            %
            %   obj.('new_prop') = value;
            %
            %   Inside the class: 
            %   -----------------
            %   Tries to directly assign to the 'new_prop' property, which
            %   doesn't exist.
            %
            %   Outside the class: 
            %   ------------------
            %   Calls the class' subsasgn method which handles the logic
            %   appropriately of adding the new property to the class.
            %
            %   
            %
            
            %obj.props is a structure, so we try and add the field
            %via dynamic indexing. If the field name is invalid, we fall
            %back to mex code which allows the invalid assignment
            try
                obj.props.(name) = value;
            catch
                obj.props = json.utils.setField(obj.props,name,value);
            end
        end
    end
    
    methods 
        function mask = isfield(obj,field_or_fieldnames)
           if ischar(field_or_fieldnames)
               field_or_fieldnames = {field_or_fieldnames};
               %TODO: Need to look if props is empty ...
               mask = ismember(field_or_fieldnames,obj.fieldnames);
           end
        end
        % Overload property names retrieval
        function names = properties(obj)
            names = fieldnames(obj);
        end
        % Overload fieldnames retrieval
        function names = fieldnames(obj)
            names = sort(fieldnames(obj.props));  % return in sorted order
        end
        
    end
    
    methods (Hidden=true)
        % Overload property assignment
        function obj = subsasgn(obj, subStruct, value)
            if strcmp(subStruct.type,'.')
                name = subStruct.subs;
                
                %NOTE: As designed we don't really support having
                %properties in the class itself, we could try and change it
                %so that we do, although I'm not really sure what the value
                %would be of placing properties in the class itself ...
                
                try
                    %Did this change, I'm getting subs as a {'string'}
                    %instead of 'string'
                    %2016a - string
                    %other versions?
                    %Does it depend on the form of the call?
                    obj.props.(name) = value;
                catch
                    try
                        obj.props = sl.struct.setField(obj.props,name,value);
                    catch ME
                       error('Could not assign "%s" property value', subStruct.subs); 
                    end
                end
            else  % '()' or '{}'
                %return obj;
                error('not supported');
            end
        end
        % Overload property retrieval (referencing)
        function varargout = subsref(obj, subStruct)
            %
            %   http://www.mathworks.com/help/matlab/matlab_oop/code-patterns-for-subsref-and-subsasgn-methods.html
            %
            
            s1 = subStruct(1);
            if strcmp(s1.type,'.')
                try
                    varargout{1} = obj.props.(s1.subs);
                catch
                    %TODO: Might want to look for s1.subs being a method
                    %see commented out code above
                    try
                        varargout{1} = builtin('subsref', obj, subStruct);
                    catch ME
                        %Ran into with w.data(1).plotWorm
                        if strcmp(ME.identifier,'MATLAB:maxlhs')
                            builtin('subsref', obj, subStruct);
                        else
                            rethrow(ME)
                        end
                    end
                    return
                end
                %TODO: Can we avoid the check on prop_lookup_failed by 
                %doing a return in the catch????
            else  % '()' or '{}'
                %f.data(1).x
                %   
                %   data => sl.obj.dict
                %
                %   () .  <= 2 events, () followed by .
                %
                varargout = {builtin('subsref', obj, subStruct(1))};
            end
            
            if length(subStruct) > 1
                varargout = {subsref(varargout{:},subStruct(2:end))}; 
            end

        end
        function output = struct(obj)
           output = obj.props;
        end
        function disp(objs)
            
            if length(objs) > 1
                fprintf('%s of size %dx%d\n',class(objs),size(objs,1),size(objs,2));
            else
                %TODO: we need to check for properties that have been
                %defined in the inherited class ...
                if isempty(objs.props) || isempty(fieldnames(objs.props))
                    fprintf('%s with no properties\n',class(objs));
                else
                    fprintf('%s with properties:\n\n',class(objs));
                    disp(objs.props)
                end
            end
            

        end
    end
    
end

