classdef (Abstract) BindingFactory < handle
    %BINDINGENGINEFACTORY Factory class for creating binding implementations
    %   Binding extension points can implement this factory to define how
    %   to create a BindingSource, a BindingDestination, and a
    %   BindingEngine for a particular class
    
    %   Copyright 2022 The MathWorks, Inc.

    methods

        function bindingSource = createBindingSource(obj, binding) %#ok<*INUSD>

            bindingSource = [];
        end

        function bindingDestination = createBindingDestination(obj, binding)

            bindingDestination = [];
        end

        function bindingEngine = createBindingEngine(obj, binding, bindingSource, bindingDestination)

            bindingEngine = matlab.lang.internal.bind.PassThroughBindingEngine;
        end
    end
end

