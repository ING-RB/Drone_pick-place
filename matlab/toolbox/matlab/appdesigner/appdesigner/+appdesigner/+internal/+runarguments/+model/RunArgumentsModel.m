classdef RunArgumentsModel < handle...
        & appdesigner.internal.model.AbstractAppDesignerModel
    %RunArgumentsModel  Server-side representation of RunArguments from the client
    
    % Copyright 2017-2023 The MathWorks, Inc.
    properties
        % the run configurations for the app
        RunConfigurations;
    end
    
    methods        
        function obj = RunArgumentsModel(appModel, proxyView)
            % constructor
            
            % assign this object to the App Model handle
            appModel.RunArgsModel = obj;
            
            % instantiate a controller
            obj.createController(proxyView);
        end
           
        function controller = createController(obj,  proxyView)
            % Creates the controller for this Model.  this method is the concrete implementation of the
            % abstract method from appdesigner.internal.model.AbstractAppDesignerModel
            controller = appdesigner.internal.runarguments.controller.RunArgumentsController(obj, proxyView);
            controller.populateView(proxyView);
        end

        function setDataOnSerializer(obj, serializer)
            serializer.RunConfigurations = obj.RunConfigurations;
        end
    end
    
end
