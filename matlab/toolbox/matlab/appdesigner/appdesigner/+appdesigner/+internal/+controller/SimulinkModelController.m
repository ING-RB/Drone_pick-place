classdef SimulinkModelController < appdesservices.internal.interfaces.controller.AbstractController
    % SIMULINKMODELCONTROLLER Controller for SimulinkModel

    % Copyright 2022-2024 The MathWorks, Inc.

    properties
        ComponentAddedListener
    end

    methods
        function obj = SimulinkModelController(model, proxyView)
            obj = obj@appdesservices.internal.interfaces.controller.AbstractController(model, [], proxyView);
            obj.ComponentAddedListener = addlistener(obj.Model.Parent, 'ComponentAdded', @obj.handleComponentAdded);

            if ~isempty(proxyView) && ~isempty(proxyView.PeerNode)
                % Set up propertiesSet event listener
                addlistener(proxyView.PeerNode, 'propertiesSet', ...
                    obj.wrapLegacyProxyViewPropertiesChangedCallback(@obj.handlePropertiesChanged));
            end
        end

        function delete(obj)
            delete(obj.ComponentAddedListener);
            if ~isempty(obj.Model.Parent.UIFigure) && isvalid(obj.Model.Parent.UIFigure)
                descendants = appdesigner.internal.application.getDescendants(obj.Model.Parent.UIFigure);
    
                for i=1:length(descendants)
                    obj.assignSimulinkModel(descendants(i), true);
                end
            end
        end

        function createProxyView(obj, ~)
            % No-op
        end

        function simulinkSimulation = getSimulinkSimulation(obj)
            simulinkSimulation = obj.Model.SimulinkSimulation;
        end
    end

    methods(Access = protected)
        function handleEvent(obj, ~, event)
            % handler for peer node events from the client
            switch event.Data.Name
                case 'activateBindMode'
                    try
                        appdesignerBindModeHandler = appdesigner.internal.simulinkapps.AppDesignerSimulinkBindModeHandler(...
                            event.Data.BindData, event.Data.AppModelId, obj);
                        appdesignerBindModeHandler.openModel();
                        appdesignerBindModeHandler.activate();
                        obj.ClientEventSender.sendEventToClient('bindModeActivated', {});
                    catch ex
                        obj.ClientEventSender.sendEventToClient('simulinkModelLoadFailed', {'ErrorMessage', ex.message});
                    end

                case 'validateBindings'
                    try
                        existingBindings = event.Data.Bindings;

                        if isempty(obj.Model.SimulinkSimulation)
                            obj.createSimulinkSimulation(obj, event.Data.ModelName)
                        end

                        anyVariableBindings = any(strcmp({existingBindings.Destination}, 'Simulation.TunableVariables'));

                        % UpdateDiagram is needed only if there are variable bindings
                        if (anyVariableBindings)
                            [~, updateDiagramNeeded] = BindMode.utils.getParametersUsedByBlk(obj.Model.SimulinkSimulation.ModelName);
                        else
                            updateDiagramNeeded = false;
                        end


                        if ~isempty(existingBindings) && ~updateDiagramNeeded
                            bindPropertyName = '';

                            keys = [];
                            signalKeys =  obj.Model.SimulinkSimulation.LoggedSignals.keys;
                            variableKeys = obj.Model.SimulinkSimulation.TunableVariables.keys;

                            for i = 1: numel(existingBindings)
                                if strcmp(existingBindings(i).Source, 'Simulation.LoggedSignals')
                                    keys =  signalKeys;
                                    bindPropertyName = 'SourceParameter';

                                elseif strcmp(existingBindings(i).Destination, 'Simulation.TunableVariables')
                                    keys = variableKeys;
                                    bindPropertyName = 'DestinationParameter';
                                end

                                existingBindings(i).IsValid = any(strcmp(keys, existingBindings(i).(bindPropertyName)));
                            end
                        end
                        obj.ClientEventSender.sendEventToClient('bindingValidationCompleted', {'Bindings', existingBindings, 'IsModelUpToDate', ~updateDiagramNeeded, 'CommandId', event.Data.CommandId});
                    catch ex
                        obj.ClientEventSender.sendEventToClient('bindingValidationFailed', {'ErrorMessage', ex.message, 'CommandId', event.Data.CommandId});
                    end
            end
        end

        function getPropertiesForView(~, ~)
            % No-Op implemented for Base Class
        end

        function unhandledProperties = handlePropertiesChanged(obj, changedPropertiesStruct)
            handlePropertiesChanged@appdesservices.internal.interfaces.controller.AbstractController(obj, changedPropertiesStruct);

            if(isfield(changedPropertiesStruct, 'Filename'))
                obj.handleSimulinkModelFileChanged(changedPropertiesStruct.Filename);
            end
        end
    end

    methods(Access = private)
        function handleSimulinkModelFileChanged(obj, fileName)
            obj.Model.Filename = fileName;
            obj.createSimulinkSimulation(fileName);
            descendants = appdesigner.internal.application.getDescendants(obj.Model.Parent.UIFigure);

            for i=1:length(descendants)
                obj.assignSimulinkModel(descendants(i), true);
            end
        end

        function createSimulinkSimulation(obj, fileName)
            try
                if isempty(fileName)
                    obj.Model.SimulinkSimulation = [];
                    obj.ViewModel.setProperties({'ModelUUID', ''});
                else
                    [~, modelName, ~] = fileparts(fileName);
                    obj.Model.SimulinkSimulation = simulation(modelName);
                    obj.ViewModel.setProperties({'ModelUUID', obj.Model.SimulinkSimulation.getModelParameter('ModelUUID').Value});
                end
            catch ex
                obj.ClientEventSender.sendEventToClient('simulinkModelLoadFailed', {'ErrorMessage', ex.message});
            end
        end

        function assignSimulinkModel(obj, component, updateCodeGen)
            if startsWith(component.Type, 'simulink.ui.control.')
                component.Simulation = obj.Model.SimulinkSimulation;

                if (updateCodeGen)
                    component.getControllerHandle().updateGeneratedCode();
                end
            end
        end

        function handleComponentAdded(obj, ~, event)
            obj.assignSimulinkModel(event.Component, false);
        end
    end
end
