classdef MethodBindingDestination < matlab.lang.internal.bind.BindingDestination
    %METHODBINDINGDESTINATION A BindingDestination that is used for
    %destination objects that have a public method that is being bound to

    %   Copyright 2022 The MathWorks, Inc.

    properties (Access=private)
        Binding
    end

    methods 

        function setData(obj, varargin)
            feval(obj.Binding.DestinationParameter, obj.Binding.Destination, varargin{:});
        end

        function start(obj, binding)
            obj.Binding = binding;
        end

        function stop(obj, ~)
            obj.Binding = [];
        end
    end
end

