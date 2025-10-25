classdef ViewModelAddChildPlaceholder < appdesservices.internal.interfaces.view.ViewModelOperationPlaceholder
    %VIEWMODELADDCHILDPLACEHOLDER A class to act as a placeholder to hold addChild() call of a ViewModel

    % Copyright 2024 MathWorks, Inc.
    
    properties (SetAccess = private)
        ViewModelPlaceholder
        Type
        Props
        IsJSON = false;
    end
    
    methods
        function obj = ViewModelAddChildPlaceholder(vmPlaceholder, type, props, isJSON)
            arguments
                vmPlaceholder
                type
                props = [];
                isJSON = false;

            end
            obj.ViewModelPlaceholder = vmPlaceholder;
            obj.Type = type;
            obj.Props = props;
            obj.IsJSON = isJSON;
        end
        
        function attach(obj, parentVM)
            if isempty(obj.Props)
                viewModel = parentVM.addChild(obj.Type);
            else
                if obj.IsJSON
                    viewModel = parentVM.addChildWithJSONValues(obj.Type, obj.Props);
                else
                    viewModel = parentVM.addChild(obj.Type, obj.Props);
                end
            end

            obj.ViewModelPlaceholder.attach(viewModel);
        end
    end
end

