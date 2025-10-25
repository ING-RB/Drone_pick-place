classdef (Abstract) BindingEngine < handle
    %BINDINGENGINE Interface for a binding engine

    % Copyright 2022 The MathWorks, Inc.

    methods (Abstract)
        start(obj, binding, bindingSource, bindingDestination)
        stop(obj, binding, bindingSource, bindingDestination)
    end
end

