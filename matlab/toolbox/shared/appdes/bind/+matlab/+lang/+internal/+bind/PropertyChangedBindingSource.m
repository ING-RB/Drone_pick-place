classdef PropertyChangedBindingSource < matlab.lang.internal.bind.BindingSource
    %PropertyChangedBindingSource A BindingSource 

    % Copyright 2023 The MathWorks, Inc.
    
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
                obj.SourcePropertyListener = addlistener(obj.Binding.Source, 'BindablePropertyChanged', @obj.handlePropertyChanged);
            end
        end

        function removeListeners(obj)
            if obj.isvalid
                delete(obj.SourcePropertyListener);
            end
        end

        function handlePropertyChanged(obj, src, event)
            
            % Property Translation
            % TODO: find a new home for this so that it scales better            
            propertyName = event.Property;
            if(strcmp(propertyName, 'PrivateValue'))
                propertyName = 'Value';
            elseif(strcmp(propertyName, 'PrivateSelectedIndex'))
                propertyName = 'Value';
            end
            
            if(~(strcmp(propertyName, obj.Binding.SourceParameter)))
               return; 
            end
            newValue = src.(obj.Binding.SourceParameter);
            obj.SendDataFcn(newValue);
        end
    end
end

