classdef AppLoaderFactory < handle
    %APPLOADERFACTORY A factory to instantiate the correct loaders based on
    %the version of the app being loaded

    % Copyright 2017-2024 The MathWorks, Inc.

    methods

        function loader = createLoader(~, appData, matlabReleaseOfApp, mlappVersion, requiredProducts, codeText, fullFileName)
            % matlabReleaseOfApp is R2016a, R2016b, etc
            % mlappVersion is 1 if the app is in the old serialization
            % format or 2 if its in the new format
            import appdesigner.internal.serialization.util.*;
            import appdesigner.internal.serialization.app.AppVersion;

            if strcmp(mlappVersion, AppVersion.MLAPPVersionOne)
                % the app is an MLAPP Version 1 app meaning its 16a-17b or
                % 18a apps that were created before the new format was
                % submitted

                % the Version1Loader will read the data in the old format
                % and upgrade the data to the new format
                loader = appdesigner.internal.serialization.loader.Version1Loader(appData);

                is16a = ReleaseUtil.is16aRelease(matlabReleaseOfApp);
                is16b = ReleaseUtil.is16bRelease(matlabReleaseOfApp);

                if(is16a)
                    % remove the SerializationID property from the components if one exists
                    loader = appdesigner.internal.serialization.loader.SerializationIdRemover(loader);

                    % add a pixel to the postion of each component
                    loader = appdesigner.internal.serialization.loader.PositionAdjuster(loader);

                elseif (is16b)
                    % The SerializationIDRemover will remove the
                    % SerializationId property from each component if it exists
                    loader = appdesigner.internal.serialization.loader.SerializationIdRemover(loader);
                end

                if (is16a || is16b)
                    loader = appdesigner.internal.serialization.loader.AutoResizeChildrenSynchronizer(loader);
                end

            elseif (strcmp(mlappVersion,AppVersion.MLAPPVersionTwo))
                % mlapp Version 2 means its an 18a app or greater

                % the Version2Loader will read the data in the new format
                loader = appdesigner.internal.serialization.loader.Version2Loader(appData);

                if (ReleaseUtil.isLaterThanCurrentRelease(matlabReleaseOfApp) || ...
                        ~isempty(requiredProducts))
                    % Handles scenarios where we might be loading
                    % components that don't exist (FWC) / aren't licensed

                    % The UnsupportedComponentRemover will loop over the
                    % components and remove those that are unknown to the
                    % release
                    loader = appdesigner.internal.serialization.loader.UnsupportedComponentRemover(loader);
                end


                %restore the callback's component data.  This must be done
                %after the unsupported components are removed.
                loader = appdesigner.internal.serialization.loader.CallbackComponentDataRestorer(loader);

                if (ReleaseUtil.isLaterThanCurrentRelease(matlabReleaseOfApp)|| ...
                        ~isempty(requiredProducts))
                    % Handles scenarios where we might be loading
                    % components that don't exist (FWC) / arent' licensed

                    % The UnsupportedCallbackRemover will make callbacks
                    % orphan if its component data points to unknown
                    % components or unknown callback property
                    loader = appdesigner.internal.serialization.loader.UnsupportedCallbackRemover(loader);
                end

                loader = appdesigner.internal.serialization.loader.ImageLoader(loader, fullFileName);

				loader = appdesigner.internal.serialization.loader.CodeFormattingParser(loader, codeText);

                loader = appdesigner.internal.serialization.loader.HelpCommentsParser(loader, codeText);

                % Run the Mode Adjuster Loader only if app is saved in versions earlier then R2025a.
                % Once the app is loaded in R2025a or later, the Mode Adjuster will reset the modes &
                % from then this loader is not required to run.
                if (~isempty(matlabReleaseOfApp) && ReleaseUtil.isEarlierThan(matlabReleaseOfApp, 'R2025a'))
                    loader = appdesigner.internal.serialization.loader.ModeAdjuster(loader);
                end

            else
                % MLAPPDeserializer has a validation for the mlapp version,
                % so we should never run into here, but just for safety.
                loader = [];
            end

        end
    end
end
