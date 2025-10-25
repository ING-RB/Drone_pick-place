classdef AppInstantiatorFactory
    %APPINSTANTIATORFACTORY Factory used to determine and create the
    %correct RunInstantiator implementation
    
    % Copyright 2021-2024, MathWorks Inc.
    
    methods (Static)
        function instantiator = createInstantiator (appModel)
            import appdesigner.internal.serialization.app.AppTypes;
            import appdesigner.internal.serialization.FileFormat;
            import appdesigner.internal.serialization.util.getFileFormatByExtension;
            import appdesigner.internal.apprun.UserComponentInstantiator;
            import appdesigner.internal.apprun.PlainTextAppInstantiator;
            import appdesigner.internal.apprun.AppInstantiator;

            switch appModel.MetadataModel.AppType
                case AppTypes.UserComponentApp
                    instantiator = UserComponentInstantiator(appModel);
                otherwise
                    filepath = appModel.FullFileName;
                    if strcmp(getFileFormatByExtension(filepath), FileFormat.Text)
                        instantiator = PlainTextAppInstantiator(appModel);
                    else
                        instantiator = AppInstantiator(appModel);
                    end
            end
        end
    end
end
