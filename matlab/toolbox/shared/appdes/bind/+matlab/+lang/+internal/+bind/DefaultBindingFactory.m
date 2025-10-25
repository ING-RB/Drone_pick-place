classdef DefaultBindingFactory < matlab.lang.internal.bind.BindingFactory
    %DEFAULTBINDINGFACTORY Binding factory for generic MATLAB objects that
    %have public/SetObservable properties and public methods.

    %   Copyright 2022 The MathWorks, Inc.

    methods

        function bindingSource = createBindingSource(~, binding)

            mc = metaclass(binding.Source);
            props = mc.PropertyList;
            propNames = string({props.Name});

            idx = find(propNames==binding.SourceParameter);

            if(isa(binding.Source, 'matlab.ui.control.WebComponent'))
                % "PropertyChanged"
                bindingSource = matlab.lang.internal.bind.PropertyChangedBindingSource;
            
            elseif ~isempty(idx) && idx > 0 && props(idx).SetObservable && props(idx).GetAccess == "public"
                bindingSource = matlab.lang.internal.bind.SetObservableBindingSource;
            else
                error(message('MATLAB:bind:invalidSourceParameter'));
            end
        end

        function bindingDestination = createBindingDestination(~, binding)

            if isprop(binding.Destination, binding.DestinationParameter)
                if isa(binding.Destination, 'matlab.ui.control.Label')
                    bindingDestination = matlab.lang.internal.bind.StringPropertyBindingDestination;
                else
                    bindingDestination = matlab.lang.internal.bind.PropertyBindingDestination;
                end
            elseif ismethod(binding.Destination, binding.DestinationParameter)
                bindingDestination = matlab.lang.internal.bind.MethodBindingDestination;
            else
                error(message('MATLAB:bind:invalidDestinationParameter'));
                    
            end
        end
    end
end

