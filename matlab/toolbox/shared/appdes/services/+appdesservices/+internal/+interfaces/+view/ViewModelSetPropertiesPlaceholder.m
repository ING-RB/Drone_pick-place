classdef ViewModelSetPropertiesPlaceholder < appdesservices.internal.interfaces.view.ViewModelOperationPlaceholder
    %VIEWMODELSETPROPERTIESPLACEHOLDER A placeholder to queue setProperty() call
    % to a ViewModel

    % Copyright 2024 MathWorks, Inc.
    
    properties (SetAccess = private)
        PropStruct
    end
    
    methods
        function obj = ViewModelSetPropertiesPlaceholder(propStruct)
            obj.PropStruct = propStruct;
        end
        
        function attach(obj, vm)
            vm.setProperties(obj.PropStruct);
        end
    end
end

