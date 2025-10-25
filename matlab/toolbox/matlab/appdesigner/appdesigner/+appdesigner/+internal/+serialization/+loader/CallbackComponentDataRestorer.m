classdef CallbackComponentDataRestorer < appdesigner.internal.serialization.loader.interface.DecoratorLoader
    %CallbackComponentDataRestorer A decorator class that restores the callback data
    
      % Copyright 2018 The MathWorks, Inc.
      
    methods
        
        function obj = CallbackComponentDataRestorer(loader)
            obj@appdesigner.internal.serialization.loader.interface.DecoratorLoader(loader);
        end
        
        function appData = load(obj)
            appData = obj.Loader.load();
            if ( isfield(appData.code,'Callbacks'))
                appData.code.Callbacks = ...
                    appdesigner.internal.serialization.util.restoreCallbackComponentData(...
                    appData.components.UIFigure,appData.code.Callbacks);
            end
        end
        
    end
end

