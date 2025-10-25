classdef (Abstract) UIComponentPropertyTranslationUtils < handle
    %UICOMPONENTPROPERTYTRANSLATOR A class to handle translation of
    % properties from UIComponent values to UIControl values.

    % Copyright 2019 The MathWorks, Inc.

    properties (Constant, Access = private)
        PropertyConversionFunctions = appdesigner.appmigration.internal.UIComponentPropertyTranslationUtils.createConversionFunctionMap()
    end

    methods (Static)
        function control = createUIControl(uicomponent)
            % Create a UIControl such that its properties map to those of a
            % UI component.
            
            import appdesigner.appmigration.internal.UIComponentPropertyTranslationUtils;

            propNames = properties(uicomponent);
            pvPairs = UIComponentPropertyTranslationUtils.translatePropertiesToUIControlProperties(uicomponent, propNames);
            
            additionalPVPairs = UIComponentPropertyTranslationUtils.getAdditionalPVPairsForType(uicomponent.Type);
            pvPairs = [pvPairs additionalPVPairs];
            
            style = UIComponentPropertyTranslationUtils.translateComponentTypeToStyle(uicomponent.Type);
            control = uicontrol('Style', style, 'Parent', [], 'FontUnits', 'pixels', pvPairs{:});
        end

        function pvPairs = translatePropertiesToUIControlProperties(uicomponent, propNames)
            % Find the relevant property conversion functions.  If one
            % exists, use it to convert the UIComponent's property to the
            % corresponding UIControl properties.  Return the resulting PV
            % pairs that should be applied to the UIControl.

            conversionFunctions = appdesigner.appmigration.internal.UIComponentPropertyTranslationUtils.PropertyConversionFunctions;

            pvPairs = {};
            for idx = 1:length(propNames)
                propName = propNames{idx};
                if isKey(conversionFunctions, propName)
                    conversionFcn = conversionFunctions(propName);
                    pvp = conversionFcn(uicomponent, propName);
                    pvPairs = [pvPairs pvp];
                end
            end
        end
    end

    methods (Static, Access = private)
        function conversionFunctionMap = createConversionFunctionMap()
            conversionFunctions = matlab.ui.internal.componentconversion.UIComponentConversionUtils.getPropertyConversionFunctions();

            % Initialize a map of property names to conversion functions.
            conversionFunctionMap = containers.Map();

            for idx = 1:length(conversionFunctions)
                conversionInfo = conversionFunctions{idx};
                [propName, conversionFcn] = conversionInfo{:};
                conversionFunctionMap(propName) = conversionFcn;
            end
        end
        
        function pvPairs = getAdditionalPVPairsForType(type)
            % Retrieve any additional PV pairs that are needed to express
            % the correct UIControl configuration for this type of UI
            % component.  Not all of this information can be determined
            % from the UI component's properties as it may be encoded
            % differently.  E.g. TextArea is a new component, whereas a
            % UIControl is a multiline text area if it has style 'edit' and
            % abs(Max - Min) > 1.
            % Any such information that cannot be deduced from the UI
            % component properties should be placed here.
            switch type
                case 'uitextarea'
                    pvPairs = {'Max', 2};
                otherwise
                    pvPairs = {};
            end
        end

        function style = translateComponentTypeToStyle(type)
            switch type
                case 'uilistbox'
                    style = 'listbox';
                case 'uistatebutton'
                    style = 'togglebutton';
                case 'uilabel'
                    style = 'text';
                case 'uieditfield'
                    style = 'edit';
                case 'uitextarea'
                    style = 'edit';
                case 'uibutton'
                    style = 'pushbutton';
                case 'uislider'
                    style = 'slider';
                case 'uidropdown'
                    style = 'popupmenu';
                case 'uiradiobutton'
                    style = 'radiobutton';
                case 'uicheckbox'
                    style = 'checkbox';
                otherwise
                    error('uicontrol:conversion:UnsupportedComponentType', type);
            end
        end
    end
end