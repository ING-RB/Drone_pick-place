classdef PropertyInspectorFactory
    %PROPERTYINSPECTORFACTORY
    %  1. Creates and returns an empty property inspector instance (using
    %  the getInstance method), or
    %  2. Creates a populated property inspector instance containing the
    %  inspected object (using the inspectObject() method).

    % Copyright 2021-2023 The MathWorks, Inc.

    %% Private Constructor
    methods (Access = private)
        function obj = PropertyInspectorFactory()
        end
    end

    methods (Static)
        function instance = getInstance(className)
            % Returns an instance of the property inspector. className is
            % the name of the class that will be inspected.

            arguments
                className (1, 1) string
            end
            parentFigure = ...
                uifigure(Name = message("instrument:general:instrumentPropertyInspector", className).getString());
            gridLayout = instrument.internal.PropertyInspectorFactory.getGridLayout(parentFigure);
            instance = matlab.ui.control.internal.Inspector(Parent = gridLayout);
        end

        function inspectObject(instance, varname)
            % Create a value wrapper object for the
            % instrument/serial/icgroup instance, and view it using the
            % UIInspector. 
            % instance - the instrument/serial/icgroup object
            % varname - the variable name of the instrument
            % instrument/serial/icgroup object in a MATLAB workspace.

            % Create the Wrapper Object to be inspected by the UIInspector.
            wrapper = internal.matlab.inspector.ValueObjectWrapper(instance, varname, "debug");

            className = string(class(instance));
            propertyInspector = instrument.internal.PropertyInspectorFactory.getInstance(className);

            propertyInspector.inspect(wrapper);
        end
    end

    methods (Access = private, Static)
        function gridLayout = getGridLayout(parent)
            % Creates and returns a uigridlayout.

            gridLayout = uigridlayout(parent);
            gridLayout.RowHeight = "1x";
            gridLayout.ColumnWidth = "1x";
            gridLayout.Padding = [0, 0, 0, 0];
        end
    end
end