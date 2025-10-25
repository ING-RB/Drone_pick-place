classdef EditorConverter < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Abstract EditorConverter class.  This class is extended to provide a
    % way to convert to and from server/client values.  Typical usage is
    % when creating the values to display on the client, or when setting a
    % value from the client.  For example
    %
    % c = SomeEditorConverter();
    % c.setServerValue(myObj.value);
    % clientValue = c.getClientValue();
    
    % Copyright 2015-2022 The MathWorks, Inc.

    properties
        InspectorID (1,1) string;
    end
    
    methods(Abstract = true)
        
        % Called to set the server-side value
        setServerValue(this, value, dataType, propName);
        
        % Called to set the client-side value
        setClientValue(this, value);
        
        % Called to get the server-side representation of the value
        value = getServerValue(this);
        
        % Called to get the client-side representation of the value
        value = getClientValue(this);
        
        % Called to get the editor state, which contains properties
        % specific to the editor
        props = getEditorState(this);
        
        % Called to set the editor state, which are properties specific to
        % the editor
        setEditorState(this, props);
    end
    
    methods
        % Called to set the validation settings for the property this
        % editor converter is being used for.  Default implementation in
        % the base class is a no-op, but classes which extend this can make
        % use of it if they need.
        function setValidation(this, validation)
            arguments
                this %#ok<*INUSA> 
                
                validation struct
            end
        end
    end

    methods (Static, Access = protected)
        function dataTypeName = getDataTypeName(dataType)
            % Returns the a property's data type, given its dataType from the
            % Property Inspector.  dataType will either be a MATLAB meta.type or
            % meta.class object (for property types defined in MATLAB class
            % files), or will be a string which is just the data type (for
            % dynamic properties).
            if isa(dataType, "meta.type") || isa(dataType, "meta.class") || isstruct(dataType)
                dataTypeName = dataType.Name;
            else
                dataTypeName = dataType;
            end
        end
    end
end
