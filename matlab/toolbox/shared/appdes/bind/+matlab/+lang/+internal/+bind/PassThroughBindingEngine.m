classdef PassThroughBindingEngine < matlab.lang.internal.bind.BindingEngine
    %NONSTREAMINGBINDINGENGINE A binding engine that directly passes the
    %data from a BindingSource to a BindingDestination after passing
    %through a ConversionFcn if specified.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Access=protected)
        Binding
        BindingSource
        BindingDestination        
        DataToSet
    end

    methods

        function write(obj, data)            
            obj.BindingDestination.setData(data);
        end

        function start(obj, binding, bindingSource, bindingDestination)
            obj.Binding = binding;
            obj.BindingSource = bindingSource;
            obj.BindingDestination = bindingDestination;            

            obj.BindingDestination.start(binding);
            obj.BindingSource.start(binding, @obj.write);
        end

        function stop(obj, binding, bindingSource, bindingDestination)
            obj.Binding = binding;
            obj.BindingSource = bindingSource;
            obj.BindingDestination = bindingDestination;    

            obj.BindingSource.stop(binding);
            obj.BindingDestination.stop(binding);
        end
    end
end

