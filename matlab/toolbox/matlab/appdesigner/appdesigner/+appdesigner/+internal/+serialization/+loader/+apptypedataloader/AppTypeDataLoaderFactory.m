classdef AppTypeDataLoaderFactory < handle
    %APPTYPEDATALOADERFACTORY Determines based on appType what
    %editable code block loader to instantiate.
    
    % Copyright 2021, MathWorks Inc.
    
    methods (Static)
        function loader = createAppTypeDataLoader (appType)
            import appdesigner.internal.serialization.app.AppTypes;
            
            switch (appType)
                case AppTypes.UserComponentApp
                    loader = appdesigner.internal.serialization.loader.apptypedataloader.ComponentDataLoader;
                otherwise
                    loader = appdesigner.internal.serialization.loader.apptypedataloader.AppDataLoader;
            end
        end
    end
end
