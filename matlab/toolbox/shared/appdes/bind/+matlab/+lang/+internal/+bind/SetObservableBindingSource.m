classdef SetObservableBindingSource < matlab.lang.internal.bind.BindingSource
    %SetObservableBindingSource A BindingSource for source objects that
    %have a SetOvervable=true property that is being bound to.

    % Copyright 2022 The MathWorks, Inc.
    
    properties (Access = private)
        SourcePropertyListener
        Binding
        SendDataFcn
    end

    methods

        function start(obj, binding, sendDataFcn)
            obj.Binding = binding;
            obj.SendDataFcn = sendDataFcn;
            addListeners(obj);
            obj.SendDataFcn(obj.Binding.Source.(obj.Binding.SourceParameter));
        end

        function stop(obj, ~)
            obj.Binding = [];
            obj.removeListeners();
        end

        function delete(obj)
            obj.stop(obj.Binding);
        end
    end

    methods (Access = private)

        function addListeners(obj)
            if isempty(obj.SourcePropertyListener)
                obj.SourcePropertyListener = addlistener(...
                    obj.Binding.Source, ...
                    obj.Binding.SourceParameter, ...
                    'PostSet', @obj.handleSourcePropertyPostSet ...
                    );
            end
        end

        function removeListeners(obj)
            if obj.isvalid
                delete(obj.SourcePropertyListener);
            end
        end

        function handleSourcePropertyPostSet(obj, ~, event)
            newValue = event.AffectedObject.(obj.Binding.SourceParameter);
            obj.SendDataFcn(newValue);
        end
    end
end

