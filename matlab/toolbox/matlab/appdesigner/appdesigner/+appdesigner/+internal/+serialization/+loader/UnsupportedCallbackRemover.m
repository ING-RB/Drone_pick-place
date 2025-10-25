classdef UnsupportedCallbackRemover < appdesigner.internal.serialization.loader.interface.DecoratorLoader
    %UNSUPPORTEDCALLBACKREMOVER A decorator class that removes unknown callbacks from the app
    
    % Copyright 2017-2023 The MathWorks, Inc.
    
    methods
        
        function obj = UnsupportedCallbackRemover(loader)
            obj@appdesigner.internal.serialization.loader.interface.DecoratorLoader(loader);
        end
        
        function appData = load(obj)
            appData = obj.Loader.load();
            
            if ( isfield(appData.code,'Callbacks'))
                appData.code.Callbacks = obj.removeUnsupportedCallbacks(appData.components.UIFigure, appData.code.Callbacks);
            end
        end
        
    end
    
    methods (Access='private')

        function callbacks = removeUnsupportedCallbacks(obj, uifigure, callbacks)
            % Removes ComponentData for callbacks in the following
            % scenarios
            %    1) The component associated with the callback does not
            %    exist in the current release
            %    2) The component associated with the callback is not
            %    supported (i.e. it does not exist in the component adapter
            %    map and is not a user authored component)
            %    3) The component exists and is supported but the callback
            %    property for the component does not exist in the current
            %    release.

            if ~isempty(callbacks)

                adapterMap = appdesigner.internal.application.getComponentAdapterMap();

                components = obj.getComponents(uifigure);

                for i = 1:length(callbacks)
                    componentData = callbacks(i).ComponentData;

                    for j = length(componentData):-1:1

                        comp = getComponentFromCodeName(obj, components, componentData(j).CodeName);

                        if isempty(comp)
                            callbacks(i).ComponentData(j) = [];
                        elseif ~adapterMap.isKey(componentData(j).ComponentType)
                            % External user components (excluding
                            % internally authored user components that have
                            % their own adapter) won't exist in the adapter
                            % map because they share a generic adapter.
                            % Don't remove callback data in this case. If a
                            % external user component is not supported, it
                            % will be removed as part of the load and the
                            % callback data will be removed in the above if
                            % condition (see g2985879).
                            if ~isa(comp, 'matlab.ui.componentcontainer.ComponentContainer')
                                callbacks(i).ComponentData(j) = [];
                            end
                        else
                            type = componentData(j).ComponentType;
                            prop = componentData(j).CallbackPropertyName;
                            supportedProps = obj.getSupportedProps(comp, type);
                            if(~any(strcmp(prop, supportedProps)) || ~strcmp(get(comp, prop), callbacks(i).Name))
                                callbacks(i).ComponentData(j) = [];
                            end
                        end
                    end
                end
            end
        end
        
        function components = getComponents(~, uifigure)
            components = findall(uifigure, '-property', 'DesignTimeProperties');
        end  
        
        function component = getComponentFromCodeName(~, components, codeName)
            component = [];
            for i = 1:length(components)
                if strcmp(components(i).DesignTimeProperties.CodeName, codeName)
                    component = components(i);
                    break;
                end
            end
        end
        
        function supportedProps = getSupportedProps(~, comp, type)
            adapterMap = appdesigner.internal.application.getComponentAdapterMap();
            adapter = eval(adapterMap(type));
            supportedProps = adapter.getCodeGenPropertyNames(comp);
        end
    end
end

