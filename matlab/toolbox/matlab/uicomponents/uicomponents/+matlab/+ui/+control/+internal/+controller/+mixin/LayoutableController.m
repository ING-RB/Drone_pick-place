classdef (Hidden) LayoutableController <  appdesservices.internal.interfaces.controller.AbstractControllerMixin
    % Mixin Controller Class for the Layoutable mixin
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    
    methods (Static = true)
        
        function additionalProperties = getAdditonalLayoutPropertyNamesForView()
            % These are non - public properties that need to be explicitly
            % added
            additionalProperties = {...
                'Layout_I';...
                };            
        end
        
        function excludedPropertyNames = getExcludedLayoutPropertyNamesForView()
            % Provide a list of property names that needs 
            % to be excluded from the properties to sent to the view
            % 
            
            excludedPropertyNames = {...
                'Layout';...
                'Layout_I';...
                };
        end        
        
        function constraintsStruct = convertContraintsToStruct(constraints)
            % Convert the constraints object to a struct that will be sent
            % to the view.
            
            % Convert the object into a struct via 'get', and
            % Add a 'type' field to the struct
            % so the view knows which type of layout
            % container the component is in 
            if isempty(constraints)
                constraintsStruct = struct('Type','Absolute');
            else
                constraintsStruct = matlab.ui.control.internal.controller.mixin.LayoutableController.getPublicPropsFromValObject(constraints);
                
                % The type is determined by looking at the class name of
                % the Layout property, which is of the form
                % [LayoutType]LayoutOptions, e.g. GridLayoutOptions                
                fullClassName = class(constraints);                
                shortClassNameStartIdx = regexp(fullClassName, '\.\w*LayoutOptions');
                offset = length('LayoutOptions');                
                constraintsShortClassName = fullClassName(shortClassNameStartIdx+1 : end-offset);                

                constraintsStruct.Type = constraintsShortClassName;                
            end
        end
        
        function valObjStruct = getPublicPropsFromValObject(valueObject)
            cl = metaclass(valueObject);
            propList = cl.PropertyList;
            valObjStruct = struct;
            
            if numel(propList) > 0
                for i=1:length(propList)
                    propName = propList(i).Name;
                    valObjStruct.(propName) = valueObject.(propName);
                end
            end
            
        end
        
        function updateLayoutFromClient(model, valueStruct)
            % Update component's Layout property according to value struct
            % from client side            
            
            if strcmp(valueStruct.Type, 'Absolute')
                layoutOptionClassName = 'matlab.ui.layout.LayoutOptions';
            else
                layoutOptionClassName = ['matlab.ui.layout.' valueStruct.Type 'LayoutOptions'];
            end            
            
            if ~strcmp(class(model.Layout), layoutOptionClassName)
                % Layout type has been changed, and so need to create a new
                % LayoutOption
                if strcmp(layoutOptionClassName, 'matlab.ui.layout.LayoutOptions')
                    % Component is no longer in a layout manager, create an empty layout option
                    model.Layout = matlab.ui.layout.LayoutOptions.empty();
                else
                    model.Layout = feval(layoutOptionClassName);
                end
            end            
                
            % Get the updated property list of the LayoutOption from the
            % value struct
            propList = fieldnames(valueStruct);
            % Remove 'Type' from the property list
            propList(strcmp(propList, 'Type')) = [];
            
            % Update layout properties with client-side value
            for i=1:numel(propList)
                propName = propList{i};
                model.Layout.(propName) = valueStruct.(propName);
            end
        end
    end
    
    
    methods
        
        function viewPvPairs = getLayoutConstraintsForView(obj, propertyNames)
            % Format the LayoutConstraints property so it can be sent to
            % the view
            import appdesservices.internal.util.ismemberForStringArrays;
            viewPvPairs = {};
            propertiesToCheck = ["Layout", "Layout_I"];
            propertyIsPresent = ismemberForStringArrays(propertiesToCheck, propertyNames);

            if any(propertyIsPresent) 
                constraints = obj.Model.Layout;
                constraintsStruct = matlab.ui.control.internal.controller.mixin.LayoutableController.convertContraintsToStruct(constraints);
                viewPvPairs = [viewPvPairs, ...
                    {'LayoutConstraints', constraintsStruct} ...
                    ];
            end
        end
    end
    
end

