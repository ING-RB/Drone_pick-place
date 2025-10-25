classdef RunningInstanceCloserFactory
    %RUNNINGINSTANCECLOSERFACTORY Factory entry point for creating
    %strategized implementations of closing app instances started from
    %design time
    
    % Copyright 2021, MathWorks Inc.
    
    methods (Static)
        function closer = createCloser(appType, runningInstance)
            import appdesigner.internal.serialization.app.AppTypes;

            switch appType
                case AppTypes.StandardApp
                    closer = appdesigner.internal.appcloser.AppInstanceCloser(runningInstance);
                case AppTypes.ResponsiveApp
                    closer = appdesigner.internal.appcloser.AppInstanceCloser(runningInstance);
                case AppTypes.UserComponentApp
                    closer = appdesigner.internal.appcloser.UserComponentInstanceCloser(runningInstance);
            end
        end
    end
end
