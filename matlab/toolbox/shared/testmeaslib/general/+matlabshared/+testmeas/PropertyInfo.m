classdef PropertyInfo < dynamicprops & matlabshared.testmeas.CustomDisplay
    % PROPERTYINFO class can be used by client teams to provide property
    % metadata for client hardware interfaces. This class also provides
    % default implementation for the metadata property values, which can
    % also be overridden by client teams extending this class.

    % Copyright 2023 The MathWorks, Inc.

    properties (Access = protected)
        % Weak handle to the hardware object
        HardwareWeakObj matlab.internal.WeakHandle = matlab.internal.WeakHandle.empty()
    end

    properties (Access = private)
        % List of all properties on the hardware object
        PropertyList    meta.property
    end

    properties (SetAccess = private)
        % Property name
        Name            (1,1) string
        % Property data type
        Type            (1,1) string
        % Property default value
        Default

    end

    properties(Dependent, SetAccess = private)
        % Property indicating if the property is currently read-only
        ReadOnly        (1,1) logical
        % All possible values for the property
        AllowedValues
    end

    methods(Access = public)
        function propertyInfoObj = PropertyInfo(hardwareObj,property)

            arguments
                hardwareObj (1,1)
                property    (1,1) string
            end

            try
                % Validate if the first input is a valid MATLAB handle object.
                if ~isobject(hardwareObj) || ~isvalid(hardwareObj)
                    error("testmeaslib:PropertyInfo:InvalidHandle",...
                        message("testmeaslib:PropertyInfo:InvalidHandle").getString());
                end
                % Store weak reference to the hardware object and the
                % property list from the metaclass object
                propertyInfoObj.HardwareWeakObj = matlab.internal.WeakHandle(hardwareObj);
                propertyInfoObj.PropertyList = metaclass(hardwareObj).PropertyList;

                % Validate the inputted property name
                propertyName = validateProperty(propertyInfoObj,property);
                propertyInfoObj.Name = propertyName;
                % Store type as string if the type passed in is "char" or
                % an enumeration
                propertyInfoObj.Type = class(hardwareObj.(propertyName));
                if propertyInfoObj.Type == "char" || isenum(propertyName)
                    propertyInfoObj.Type = "string";
                end

                % Call the getDefault function implemented by the hardware
                % class to retrieve the default value for the property
                propertyInfoObj.Default = getDefaultValueHook(propertyInfoObj);

                % Invoke custom properties addition hook to add custom property
                % metadata
                addCustomPropertiesHook(propertyInfoObj);

                % Delete propertyInfo object when the parent hardware
                % object is being deleted
                addlistener(hardwareObj,"ObjectBeingDestroyed",@(~,~)delete(propertyInfoObj));

                % Turn off footer for object display
                propertyInfoObj.ShowFooter = false;
            catch ex
                throwAsCaller(ex)
            end
        end
    end

    methods
        % Use getters to dynamically get latest values of
        % dynamic device properties
        function value = get.ReadOnly(propertyInfoObj)
            value = getReadOnlyStateHook(propertyInfoObj);
        end

        function value = get.AllowedValues(propertyInfoObj)
            value = getAllowedValuesHook(propertyInfoObj);
        end
    end

    methods(Access = protected)
        function default = getDefaultValueHook(propertyInfoObj)
            % Get default value of the specified property, if any, using class
            % metadata's property list
            default = [];
            index = find(matches({propertyInfoObj.PropertyList(:).Name}, propertyInfoObj.Name));
            if(~isempty(index) && propertyInfoObj.PropertyList(index).HasDefault)
                default = propertyInfoObj.PropertyList(index).DefaultValue;
            end
        end

        function isReadOnly = getReadOnlyStateHook(propertyInfoObj)
            % Get read-only state of the specified property using the set
            % access value or constant specifier of the property.
            isReadOnly = false;
            propData = findprop(propertyInfoObj.HardwareWeakObj.get,propertyInfoObj.Name);
            if propData.Constant || propData.SetAccess == "private"
                isReadOnly = true;
            end
        end

        function allowedValues = getAllowedValuesHook(~)
            % allowedValues = getAllowedValuesHook(propertyInfoObj)
            % Get all allowed values for the hardware property.
            % Default implementation is empty as allowed values for a
            % hardware property needs to be defined by the hardware
            % class.
            allowedValues = [];
        end

        function addCustomPropertiesHook(~)
            % addCustomPropertiesHook(propertyInfoObj)
            % Clients need to define this function to add additional
            % metadata properties to the propertyInfo class using the
            % addprop function.
            %
            % Example:
            %   metadata = addprop(propertyInfoObj,"DeviceSpecific");
            %   metadata.GetAccess = "public";
            %   metadata.SetAccess = "private";
            %   propertyInfoObj.DeviceSpecific = true;
            %   metadata.Dependent = true;
            %   metadata.GetMethod = @get_DeviceSpecific;
        end
    end

    methods(Access = private)
        function propertyName = validateProperty(propertyInfoObj,property)
            % Match inputted property name with properties on the hardware
            % object
            allProperties = properties(propertyInfoObj.HardwareWeakObj.get);
            propertyName = string(allProperties(matches(allProperties,property,...
                "IgnoreCase",true)));
            % Validate property name
            if isempty(propertyName)
                error("testmeaslib:PropertyInfo:InvalidProperty",...
                    message("testmeaslib:PropertyInfo:InvalidProperty",property,...
                    class(propertyInfoObj.HardwareWeakObj.get)).getString());
            end
        end
    end
end

