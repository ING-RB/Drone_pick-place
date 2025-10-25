classdef MLAPPDeserializer < appdesigner.internal.serialization.deserializer.interface.Deserializer
    % MLAPPDeserializer   A class that deserializes (loads the app)

    %
    % Copyright 2017-2021 The MathWorks, Inc.
    %

    properties (Access = private)
        FileReader;
        Metadata;
        FullFileName;
        MLAPPValidators;
    end

    properties(SetAccess = private)
        % Array of warnings
        %
        % This is populated after getAppData() is called
        Warnings appdesigner.internal.serialization.validator.MLAPPWarning = ...
        appdesigner.internal.serialization.validator.MLAPPWarning.empty()
    end

    methods

        function obj = MLAPPDeserializer(fullFileName, validators)
            obj.FullFileName = fullFileName;
            obj.FileReader =  appdesigner.internal.serialization.FileReader(fullFileName);
            obj.MLAPPValidators = validators;
        end

        function appData = getAppData(obj)
             % Get app data of an app file

            obj.Metadata = obj.getAppMetadata();

            % Load the data from disk.  After it is loaded, we will:
            % - Inspect the data to determine its format
            % - Set the proper MLAPPVersion value in the metadata
            % - Validate the metadata to ensure we can understand the
            %    format of the file
            % - Pass the app data and metadata to the AppLoaderFactory to
            %    create the proper chain of loaders
            %
            % When it's possible to use the 'matfile' function to inspect
            % the contents of a MAT-file without loading it, we can move
            % the file reading code back into Version1Loader /
            % Version2Loader.  See g2191903 for more info.
            [rawAppData, mlappVersion] = obj.FileReader.readAppDesignerData();

            obj.Metadata.MLAPPVersion = mlappVersion;

            try
                % Validate the MLAPP file metadata. If it's not valid, error
                % will be thrown, for example, AppType is not supported,
                % minimum supported MATLAB Release does not meet, MLAPPVersion
                % is not known, etc.
                obj.Metadata = obj.validateMetaData(obj.Metadata);
            catch me
                % Clean up loaded data, if it has the delete method
                if ishandle(rawAppData.components.UIFigure)
                    delete(rawAppData.components.UIFigure);
                elseif ishandle(rawAppData.UIFigure)
                    delete(rawAppData.UIFigure);
                end
                rethrow(me);
            end

            % instantiate a factory to create the loader
            factory = appdesigner.internal.serialization.loader.AppLoaderFactory();
            loader = factory.createLoader(...
				rawAppData,...
				obj.Metadata.MATLABRelease,...
				obj.Metadata.MLAPPVersion,...
				obj.Metadata.RequiredProducts,...
				obj.FileReader.readMATLABCodeText(),...
                obj.FullFileName);

            % load the data
            appData = loader.load();

            % Validate the MLAPP file appdata. If it's not valid, error
            % will be thrown
            try
                % Load data from the App file
                obj.validateAppData(obj.Metadata, appData);
            catch me
                % Clean up loaded data
                delete(appData.components.UIFigure);
                % Rethrow the exception because validator provides appropriate error messages
                rethrow(me);
            end


            % store the UIfigure and children components so they can be
            % reused on load.  The key is its fullFilename, the data to be
            % stored is the UIFigure
            componentProvider = appdesigner.internal.serialization.util.ComponentProvider.instance();
            componentProvider.setUIFigure(obj.FullFileName,appData.components.UIFigure);

            % Aggregate any warnings that happened with validators
            for i = 1:numel(obj.MLAPPValidators)
                obj.Warnings = [obj.Warnings obj.MLAPPValidators{i}.Warnings];
            end
        end

        function appCodeData = getAppCodeData(obj)
            obj.Metadata = obj.getAppMetadata();

            % Load the code data from disk.  After it is loaded, we will:
            % - Inspect the data to determine its format
            % - Set the proper MLAPPVersion value in the metadata
            % - Validate the metadata to ensure we can understand the
            %    format of the file
            % - Pass the app data and metadata to the AppLoaderFactory to
            %    create the proper chain of loaders
            [rawAppCodeData, mlappVersion] = obj.FileReader.readAppCodeData();

            obj.Metadata.MLAPPVersion = mlappVersion;

            % Validate the MLAPP file metadata. If it's not valid, error
            % will be thrown, for example, AppType is not supported,
            % minimum supported MATLAB Release does not meet, MLAPPVersion
            % is not known, etc.
            obj.Metadata = obj.validateMetaData(obj.Metadata);

            % instantiate a factory to create the loader
            factory = appdesigner.internal.serialization.loader.AppCodeLoaderFactory();
            loader = factory.createLoader(rawAppCodeData, obj.Metadata.MLAPPVersion);

            % load the data
            appCodeData = loader.load();
        end

        function appMetadata = getAppMetadata(obj)
            % Get app metadata of an app file

            if ( ~isempty(obj.Metadata ))
                appMetadata = obj.Metadata;
            else
                try
                    % Load data from the App file
                    appMetadata = readAppMetadata(obj.FileReader);
                catch me
                    % Rethrow the exception because FileReader provides appropriate error messages
                    rethrow(me);
                end
            end
        end

    end

    methods (Access = private)
        function metadata = validateMetaData(obj, metadata)
            for i = 1:numel(obj.MLAPPValidators)
                obj.MLAPPValidators{i}.validateMetaData(metadata);
            end
            
            appMetadataModel = appdesigner.internal.model.MetadataModel();
    
            % Metadata is valid, so now fill in missing fields.
            % Any sets that fail will be ignored as to not disrupt the loading
            % process.  The loading code is robust to incorrect metadata.
            try
                set(appMetadataModel, metadata);
            catch
            metadataFields = fieldnames(metadata);
                for idx = 1:length(metadataFields)
                    fieldName = metadataFields{idx};
                    try
                        set(appMetadataModel, fieldName, metadata.(fieldName));
                    catch
                    end
                end
            end
            
            metadata = appdesigner.internal.serialization.util.convertMetadataModelToStruct(appMetadataModel);
        end

        function validateAppData(obj, metadata, appData)
            for i = 1:numel(obj.MLAPPValidators)
                obj.MLAPPValidators{i}.validateAppData(metadata, appData);
            end
        end

    end
end
