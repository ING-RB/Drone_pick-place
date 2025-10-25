classdef (Hidden, Sealed) Binding < handle
    %BINDING A binding between a source object property to a destination
    %property or method

    %   Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        Source handle = []
        SourceParameter char
        Destination handle = []
        DestinationParameter char                
    end

    properties
        Enabled (1,1) logical
    end

    properties (Constant, Access=private)
        BindingExtensionsService = matlab.lang.internal.bind.BindExtensionService;
    end

    properties (Access=private)        
        BindingSource
        BindingDestination
        BindingEngine
    end
    
    methods
        function obj = Binding(source, sourceParameter, destination, destinationParameter, nameValueArgs)
            arguments
                source (1,1) {mustBeA(source,'handle')}
                sourceParameter char
                destination (1,1) {mustBeA(destination,'handle')}
                destinationParameter char                
                nameValueArgs.Enabled (1,1) logical = true
            end

            obj.Source = source;
            obj.SourceParameter = sourceParameter;
            obj.Destination = destination;
            obj.DestinationParameter = destinationParameter;                        

            [obj.BindingSource, obj.BindingDestination, obj.BindingEngine] = obj.createBindingImplementations();
            
            obj.Enabled = nameValueArgs.Enabled;
        end

        function delete(obj)
            if ~isempty(obj.BindingEngine) && isvalid(obj.BindingEngine) && obj.Enabled
                obj.BindingEngine.stop(obj, obj.BindingSource, obj.BindingDestination);
            end
        end
        

        function set.Enabled(obj, value)
            arguments
                obj
                value logical
            end

            obj.Enabled = value;

            if value
                obj.BindingEngine.start(obj, obj.BindingSource, obj.BindingDestination);
            else
                obj.BindingEngine.stop(obj, obj.BindingSource, obj.BindingDestination);
            end
        end

        function h = keyHash(obj)
            h = keyHash({obj.Source, obj.SourceParameter, obj.Destination, obj.DestinationParameter});
        end
        
        function tf = keyMatch(objA, objB)
            tf = keyMatch({objA.Source, objA.SourceParameter, objA.Destination, objA.DestinationParameter},...
                {objB.Source, objB.SourceParameter, objB.Destination, objB.DestinationParameter});
        end
    end
    
    methods (Access=private)

        function [bindingSource, bindingDestination, bindingEngine] = createBindingImplementations(obj)

            sourceFactory = obj.getFactory(obj.Source);
            destinationFactory = obj.getFactory(obj.Destination);

            bindingSource = sourceFactory.createBindingSource(obj);
            bindingDestination = destinationFactory.createBindingDestination(obj);

            bindingEngine = sourceFactory.createBindingEngine(obj, bindingSource, bindingDestination);
        end

        function factory = getFactory(obj, objectToBind)
            
            bindingExtensions = obj.BindingExtensionsService.Extensions;

            objectClass = class(objectToBind);
            if isKey(bindingExtensions, objectClass)
                extensionInfo = bindingExtensions(objectClass);
                factoryClass = extensionInfo.factory;
                factory = feval(factoryClass);
            elseif isa(objectToBind, 'simulink.sim.Signals')
                factory = simulink.sim.internal.bind.SignalBindingFactoryManager.Instance.SignalBindingFactory;
            elseif isa(objectToBind, 'matlab.ui.scope.TimeScope')
                factory = simulink.sim.internal.bind.ScopeBindingFactory;
            elseif isa(objectToBind, 'simulink.sim.Variables')
                factory = simulink.sim.internal.bind.VariablesBindingFactory;
            else
                factory = matlab.lang.internal.bind.DefaultBindingFactory; 
            end
            
        end
    end
end

