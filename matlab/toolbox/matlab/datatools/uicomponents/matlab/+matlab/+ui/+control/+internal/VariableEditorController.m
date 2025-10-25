classdef (Hidden) VariableEditorController < ...
        matlab.ui.control.internal.controller.ComponentController
    % variableeditorController is the controller for VariableEditor component

    % Copyright 2021-2022 The MathWorks, Inc.

    methods
        function obj = VariableEditorController(varargin)
            obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});
        end
    end

    methods(Access = 'protected')
        function propertyNames = getAdditionalPropertyNamesForView(obj)
            % Get additional properties to be sent to the view

            propertyNames = getAdditionalPropertyNamesForView@matlab.ui.control.internal.controller.ComponentController(obj);

            % Non - public properties that need to be sent to the view
            propertyNames = [propertyNames; {...
                'UUID'; 'ParentName'; 'DocID'; 'Variable'...
                }];
        end


        function handleEvent(obj, src, event)
            % Allow super classes to handle their events
            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);

            %% Event handling goes here
            if(strcmp(event.Data.Name, 'GoUpButtonClicked'))
                obj.Model.Variable = obj.Model.ParentName;
            end
        end

        function changedPropertiesStruct = handlePropertiesChanged(obj, changedPropertiesStruct)
            % Handle specific property sets

            %% Special property handling goes here

            % Call the superclasses for unhandled properties
            handlePropertiesChanged@matlab.ui.control.internal.controller.ComponentController(obj, changedPropertiesStruct);
        end
    end
end

