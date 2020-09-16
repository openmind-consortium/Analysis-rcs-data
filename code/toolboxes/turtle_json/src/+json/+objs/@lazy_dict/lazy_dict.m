classdef lazy_dict < handle
    %
    %   Class:
    %   json.lazy_dict
    %
    %   This class supports arbitrary property (attribute) names as well
    %   as specification of lazy property instantiation.
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
    %   3) This class is not designed to support inheritance with
    %   additional properties. This could potentially be fixed.
    %
    %
    %   Lazy Attribute Access:
    %   ----------------------
    %   obj.addLazyField(name,value)
    %
    %   Lazy fields are evaluated upon request. If extracting the
    %   properties (obj.props), make sure to use obj.getProperties()
    %
    %
    %   Internal Class Usage:
    %   ---------------------
    %   Matlab does not support calling subsref and subsasgn methods
    %   within class methods. In other words, the following works outside
    %   a class method, but does not work inside a class method.
    %
    %   obj.my_new_property = new_value
    %
    %   Inside the class, the following needs to be used:
    %   obj.addProp('my_new_property',new_value);
    %
    %
    %   Based On:
    %   ---------
    %   http://undocumentedmatlab.com/blog/class-object-tab-completion-and-improper-field-names
    
    
    %{
    obj.method(values) %with no return
    
    wtf = json.lazy_dict;
    wtf.('my data') = 1:10;
    test = wtf.('my data')
    test2 = wtf.('my data')(5:6)
    
    %}
    
    properties
        props
        lazy_fields
    end
    
    %Methods for class design
    %------------------------
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
        function addLazyField(obj,name,value)
            %x 
            %
            %   addLazyField(obj,name,value)
            %
            %   Inputs
            %   ------
            %   name : string
            %   value : function handle
            %       When evaluated the function handle should return the
            %       actual value of the property.
            
            try
                obj.lazy_fields.(name) = value;
            catch
                obj.lazy_fields = json.utils.setField(obj.lazy_fields,name,value);
            end
            
            obj.addProp(name,'Not yet evaluated (Lazy Property)')
        end
    end
    
    methods
        function mask = isfield(obj,field_or_fieldnames)
            mask = isfield(obj.props,field_or_fieldnames);
        end
        % Overload property names retrieval => 2014a
        function names = properties(obj)
            names = fieldnames(obj);
        end
        % Overload fieldnames retrieval <= 2014a
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
                %would be of placing properties in the class itself.
                
                try
                    obj.props.(name) = value;
                catch
                    try
                        obj.props = json.utils.setField(obj.props,name,value);
                    catch ME
                        error('Could not assign "%s" property value', subStruct.subs);
                    end
                end
                
            else  % '()' or '{}'
                error('subsasgn operation not supported on lazy_dict');
            end
        end
        % Overload property retrieval (referencing)
        function value = evaluateLazyField(obj,name)
            %x
            %
            %   value = evaluateLazyField(obj,name)
            
            lazy_fields_local = obj.lazy_fields;
            fh = lazy_fields_local.(name);
            value = fh(); %evaluate function
            obj.lazy_fields = rmfield(lazy_fields_local,name);
            
            %Hold onto the value
            try
                obj.props.(name) = value;
            catch
                obj.props = json.utils.setField(obj.props,name,value);
            end
        end
        function varargout = subsref(obj, subStruct)
            %
            %   http://www.mathworks.com/help/matlab/matlab_oop/code-patterns-for-subsref-and-subsasgn-methods.html
            %
            
            %TODO: This needs to run with varargout
            s1 = subStruct(1);
            if strcmp(s1.type,'.')
                name = s1.subs;
                lazy_fields_local = obj.lazy_fields;
                if isfield(lazy_fields_local,name)
                    varargout{1} = obj.evaluateLazyField(name);
                else
                    try
                        varargout{1} = obj.props.(name);
                    catch
                        %This was failing for:
                        %obj.method(inputs)
                        %TODO: Might want to look for s1.subs being a method
                        %see commented out code above
                        try
                            varargout = {builtin('subsref', obj, subStruct)};
                        catch
                            %For no outputs
                            %For some reason this only seems to happen when
                            %evaluating code manually :/
                            
                            builtin('subsref', obj, subStruct)
                        end
                        return
                    end
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
        function disp(objs)
            if length(objs) > 1
                fprintf('%s of size %dx%d\n',class(objs),size(objs,1),size(objs,2));
            else
                if isempty(objs.props) || isempty(fieldnames(objs.props))
                    fprintf('%s with no properties\n',class(objs));
                else
                    fprintf('%s with properties:\n\n',class(objs));
                    disp(objs.props)
                end
            end
        end
    end
    
    methods
        function value = struct(obj)
            %x
            %
            %   value = struct(obj)
            %
            %   This function ensures that all lazy properties have been
            %   evaluated.
            
            if ~isempty(obj.lazy_fields)
                lazy_fields_local = fieldnames(obj.lazy_fields);
                for iField = 1:length(lazy_fields_local)
                    cur_name = lazy_fields_local{iField};
                    evaluateLazyField(obj,cur_name);
                end
            end
            value = obj.props;
        end
    end
    
end


