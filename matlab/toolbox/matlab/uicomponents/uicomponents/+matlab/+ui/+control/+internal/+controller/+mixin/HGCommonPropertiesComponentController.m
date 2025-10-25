classdef (Hidden) HGCommonPropertiesComponentController < appdesservices.internal.interfaces.controller.AbstractControllerMixin
    % Mixin Controller Class for components with Text or UserData
    
    % Copyright 2016-2019 The MathWorks, Inc.
    
    methods
        
        function excludedProperties = getExcludedHGCommonPropertyNamesForView(obj)
            % Common HG Properties
            
            excludedProperties = {...
                'Type'; ...          % GraphicsBaseFunctions
                'UserData'; ...      % GraphicsBaseFunctions
                'CreateFcn'; ...     % GraphicsCoreProperties
                'DeleteFcn'; ...     % GraphicsCoreProperties
                'BeingDeleted'; ...  % GraphicsCoreProperties
                };
        end
    end
end