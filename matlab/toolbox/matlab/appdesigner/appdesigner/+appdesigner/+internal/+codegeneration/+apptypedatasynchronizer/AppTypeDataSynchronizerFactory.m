classdef AppTypeDataSynchronizerFactory
    %APPTYPEDATASYNCHRONIZERFACTORY Depending on app type, responsible for
    %returning the correct synchronizer used by code data controller

    % Copyright 2021, Mathworks Inc.

    methods (Static)
        function synchronizer = createAppTypeDataSynchronizer(appType)
            import appdesigner.internal.serialization.app.AppTypes;

            switch (appType)
                case AppTypes.UserComponentApp
                    synchronizer = appdesigner.internal.codegeneration.apptypedatasynchronizer.ComponentDataSynchronizer;
                otherwise
                    synchronizer = appdesigner.internal.codegeneration.apptypedatasynchronizer.AppDataSynchronizer;
            end
        end
    end
end
