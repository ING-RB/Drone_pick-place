classdef SimulinkModel < handle...
        & appdesigner.internal.model.AbstractAppDesignerModel
		%SimulinkModel  Server-side representation of Simulink Model from the client

    % Copyright 2022-2023 The MathWorks, Inc.
    properties
        SimulinkSimulation
        Filename
        Parent
    end

    methods
        function obj = SimulinkModel(appModel, proxyView)
            obj.Parent = appModel;

            appModel.SimulinkModel = obj;

            obj.createController(proxyView);

            obj.Parent.addChild(obj);
        end

        function delete (obj)
            obj.SimulinkSimulation = [];
            obj.Filename = [];
            obj.Parent.SimulinkModel = [];
        end

        function controller = createController(obj,  proxyView)
            % Creates the controller for this Model.  this method is the concrete implementation of the
            % abstract method from appdesigner.internal.model.AbstractAppDesignerModel
            controller = appdesigner.internal.controller.SimulinkModelController(obj, proxyView);
            controller.populateView(proxyView);
        end

        function setDataOnSerializer(obj, serializer)
            serializer.Simulink = struct;
            serializer.Simulink.Filename = obj.Filename;
        end
    end
end
