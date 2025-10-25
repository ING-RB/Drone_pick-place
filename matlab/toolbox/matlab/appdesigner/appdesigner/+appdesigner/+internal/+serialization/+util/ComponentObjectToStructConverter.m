classdef ComponentObjectToStructConverter < appdesservices.internal.interfaces.controller.AbstractControllerMixin
    % COMPONENTOBJECTTOSTRUCTCONVERTER - Build component data for sending to client side
    % when loading an app
    %
    
    %   Copyright 2017-2023 The MathWorks, Inc.
    
    properties(Access=private)        
        UIFigure
    end
    
    methods
        % constructor
        function obj = ComponentObjectToStructConverter(uiFigure)
            obj.UIFigure = uiFigure;
        end
                
        function [componentData, erroredCodeNames] = getConvertedData(obj)
            % return the component data under UIFigure, including itself            
            % walk the UIFigure hierarchy to create a hierarchical
            % structure of structures

            [componentData, erroredCodeNames] = obj.buildComponentHierarchicalData(obj.UIFigure, []);
        end
    end  
    
    methods (Access = private)
        
        function [data, erroredCodeNames] = buildComponentHierarchicalData(obj, component, parentController)
            % recursively walk the children to build a structure of structures
            % if any components error during this process, report their
            % code names as well
            erroredCodeNames = {};
            data = struct.empty();
            
            try
                % Create controller to get PV pairs for view
                controller = obj.createController(component, parentController);
                
                % Create PV pairs for the component
                data = obj.buildComponentData(component, controller); 
            catch
                erroredCodeNames = [erroredCodeNames {component.DesignTimeProperties.CodeName}];
                % Component errored - do not descend into its children as
                % they may also be in a bad state.
                return;
            end
                
            % Recursively handle child components
            if isa(controller, 'appdesservices.internal.interfaces.controller.DesignTimeParentingController')
                % Call getAllChildren() function on the controller to get
                % all children, regardless of the HandleVisibility.
                % see g1494748
                children = controller.getAllChildren(component);
                
                order = 1:length(children);
                % reestablish the children in reverse order because HG
                % order is last created component is first child.
                %
                % Ex: The order for TabGroup is not reversed
                if (controller.isChildOrderReversed())
                    order = flip(order);
                end
                
                for i = order
                    childComponent = children(i);
                    [childData, erroredChildCodeNames] = obj.buildComponentHierarchicalData(childComponent, controller);
                    
                    if ~isempty(erroredChildCodeNames)
                        erroredCodeNames = [erroredCodeNames erroredChildCodeNames];
                    end
                    
                    if isempty(childData)
                        continue;
                    end
                    
                    data.Children(end+1) = childData;
                end
            end
        end
        
        function componentData = buildComponentData(obj, component, controller)
            % Build component data for client side
            
            if (isfield(component.DesignTimeProperties, 'ComponentCode') && ~isempty(component.DesignTimeProperties.ComponentCode))...
                    && controller.isOptimizedForAppLoad()
                % optimized process - only packages and sends non-default properties
                parsedCodegenProperties = appdesigner.internal.serialization.util.parseModifiedProperties(...
                    component.DesignTimeProperties.ComponentCode);
    
                parsedCodegenProperties = controller.adjustParsedCodegenPropertiesForAppLoad(parsedCodegenProperties);
    
                propertyNameValuesForView = controller.getPVPairsForView(component, string(parsedCodegenProperties));

                propertyNameValuesForView = controller.adjustPositionalPropertiesForAppLoad(propertyNameValuesForView);

                if ~isempty(component.ContextMenu)
                    propertyNameValuesForView = [propertyNameValuesForView, {'ContextMenuID', component.ContextMenu.ObjectID}];
                end
            else
                % non-optimized, either switched off for a specific
                % component (uislider) or component code is unavailable.
                propertyNameValuesForView = controller.getPVPairsForView(component);
            end
            
            propertyNameValuesForView = controller.addPropertyModeValues(propertyNameValuesForView);

            % convert the propertyNameValues to a struct with value be JSON compatible
            propertyValues = appdesservices.internal.peermodel.convertPvPairsToJSONCompatibleStruct(propertyNameValuesForView);
            
            % Handle design time properties:
            % Add the design time properties from the DesignTimeProperties
            % structure of the model to the list of properties going to the
            % client for creating components.
            % In this way the client will treat these properties as any other.
            % Also need to remove the DesignTimeProperties property from
            % the list of properties going to the client
            designTimeProperties = component.DesignTimeProperties;
            
            % iterate over the design time properties structure and set on
            % the values structure
            fields = fieldnames(designTimeProperties);
            for idx = 1:numel(fields)
                sourceFieldName = fields{idx};
                targetFieldName = sourceFieldName;

                % Rename the 'ComponentCode' property so that the client
                % side can easily compare the code generated by the release
                % that saved the app to the code generated by this release.
                % It also helps the client understand that this is an app
                % loading from disk.
                if strcmpi(sourceFieldName, 'ComponentCode')
                    targetFieldName = 'LoadedComponentCode';
                end

                propertyValues.(targetFieldName) = designTimeProperties.(sourceFieldName);
            end

            if isfield(propertyValues, 'DesignTimeProperties')
                propertyValues = rmfield(propertyValues, 'DesignTimeProperties');
            end
            
            % create a data structure of following fileds to hold component info
            %    Type - component type
            %    PropertyValues - a struct of pv pairs
            %    Children - an array of structs just like this, where each
            %               struct in the array is a child of the component
            componentData = struct;
            componentData.Type = class(component);
            componentData.PropertyValues = propertyValues;
            componentData.Children = struct('Type',{}, 'PropertyValues',{}, 'Children',{});
        end
        
        function controller = createController(~, component, parentController)
            % Create controller for getting property/value pair to be sent
            % to client side
            componentType = class(component);
            proxyView = appdesigner.internal.componentview.EmptyProxyView(true);
            
            controller = ...
                appdesigner.internal.componentmodel.DesignTimeComponentFactory.createController(...
                componentType, component, parentController, proxyView);           
        end
    end
end
