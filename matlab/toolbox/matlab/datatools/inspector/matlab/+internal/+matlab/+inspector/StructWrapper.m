% This class is unsupported and might change or be removed without notice in a
% future version.

% This class is a wrapper for allowing structs to show in the Object Browser and
% Property Inspector.  It extends the NonHandleObjWrapper, which presents the
% fields of the struct to the InspectorProxyMixin, to use in the inspector.

% Copyright 2021 The MathWorks, Inc.

classdef StructWrapper < internal.matlab.inspector.NonHandleObjWrapper
    
    methods
        function this = StructWrapper(obj, varName, workspace, isReadOnly)
            % Creates a StructWrapper for the given value object
            
            arguments
                % The struct being inspected
                obj
                
                % The variable name of the struct
                varName string
                
                % The workspace the struct is in.  May be text (like "base"), or
                % a workspace-like object
                workspace
                
                % Whether this struct's properties should be read-only or not.
                isReadOnly logical = false
            end

            this@internal.matlab.inspector.NonHandleObjWrapper(obj, fieldnames(obj), varName, workspace, isReadOnly);
            
            % Initialize the PreviousData property with the struct data.  This
            % is used by comparison later to, to see if values have changed
            % outside the inspector.
            this.PreviousData{1} = this.CreateStructFcn(obj);
        end
    end
    
    methods(Access = protected)
        function propertyList = getPublicNonHiddenProps(~, obj)
            % Called by the inspector to get the non-hidden properties, but this
            % doesn't realliy apply to structs.  Just return the full list of
            % fieldnames.
            
            arguments
                ~
                obj struct
            end
            
            propertyList = fieldnames(obj);
        end
    end
end
