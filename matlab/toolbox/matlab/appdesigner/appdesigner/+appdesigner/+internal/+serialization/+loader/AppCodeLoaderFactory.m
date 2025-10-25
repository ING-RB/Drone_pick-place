classdef AppCodeLoaderFactory < handle
    %APPCODELOADERFACTORY A factory to instantiate the correct loaders based on
    %the version of the app being loaded

    % Copyright 2021 The MathWorks, Inc.

    methods

        function loader = createLoader(~, appCodeData, mlappVersion)
            % mlappVersion is 1 if the app is in the old serialization
            % format or 2 if its in the new format
            import appdesigner.internal.serialization.app.AppVersion;

            if strcmp(mlappVersion, AppVersion.MLAPPVersionOne)
                % the app is an MLAPP Version 1 app meaning its 16a-17b

                % the Version1CodeLoader will read the data in the old format
                % and upgrade the data to the new format
                loader = appdesigner.internal.serialization.loader.Version1CodeLoader(appCodeData);

            elseif (strcmp(mlappVersion,AppVersion.MLAPPVersionTwo))
                % mlapp Version 2 means its an 18a app or greater

                % the Version2CodeLoader will read the data in the new format
                loader = appdesigner.internal.serialization.loader.Version2CodeLoader(appCodeData);
            else
                % MLAPPDeserializer has a validation for the mlapp version,
                % so we should never run into here, but just for safety.
                loader = [];
            end

        end
    end
end
