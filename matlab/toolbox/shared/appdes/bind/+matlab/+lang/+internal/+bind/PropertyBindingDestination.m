classdef PropertyBindingDestination < matlab.lang.internal.bind.BindingDestination
    %PROPERTYBINDINGDESTINATION A BindingDestination that is used for
    %destination objects that have a public property that is being bound to.

    % Copyright 2022 The MathWorks, Inc.

    properties (Access=private)
        Binding
    end

    methods        
        function setData(obj, varargin)
            % Handle case where an active source might still try to push
            % data to the destination
            if ~isempty(obj.Binding)
                obj.Binding.Destination.(obj.Binding.DestinationParameter) = varargin{1};
            end
        end

        function start(obj, binding)
            obj.Binding = binding;
        end

        function stop(obj, ~)
            obj.Binding = [];
        end
    end
end

