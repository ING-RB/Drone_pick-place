classdef PlainTextDeserializer < appdesigner.internal.serialization.deserializer.interface.Deserializer
    % PLAINTEXTDESERIALIZER

    properties (Access = private)
        FileName
        FileContent
        Metadata

        AppendixParser appdesigner.internal.serialization.AppAppendixParser
        CodeParser appdesigner.internal.serialization.PlainTextCodeParser
    end

    properties(SetAccess = private)
        % Array of warnings - populated after getAppData() is called

        % #fix - plain-text m app version
        Warnings appdesigner.internal.serialization.validator.MLAPPWarning = ...
            appdesigner.internal.serialization.validator.MLAPPWarning.empty()
    end

    methods

        function obj = PlainTextDeserializer(fullFileName, validators)
            obj.FileName = fullFileName;
            obj.Validators = validators;

            obj.initFromFile();
        end

        function appData = getAppData(obj)
            % Get data for loading an app from plain-text app file

            obj.Metadata = obj.getAppMetadata();

            [rawAppData, ~] = obj.readAppDesignerData();

            factory = appdesigner.internal.serialization.loader.AppLoaderFactory();

            % TODO - Reconcile Loaders w/ Metadata
            loader = factory.createLoader(...
                rawAppData,...
                obj.Metadata.MATLABRelease,...
                obj.Metadata.MLAPPVersion,...
                obj.Metadata.RequiredProducts,...
                obj.readMATLABCodeText(),...
                obj.FileName);

            appData = loader.load();

            try
                obj.validateAppData(obj.Metadata, appData);

            catch me
                delete(appData.components.UIFigure);

                % Validator provides appropriate error messages
                rethrow(me);
            end


            % store the UIfigure and children components so they can be
            % reused on load.  The key is its fullFilename, the data to be
            % stored is the UIFigure
            componentProvider = appdesigner.internal.serialization.util.ComponentProvider.instance();
            componentProvider.setUIFigure(obj.FileName, appData.components.UIFigure);

            % Aggregate any warnings that happened with validators
            for i = 1:numel(obj.Validators)
                obj.Warnings = [obj.Warnings obj.Validators{i}.Warnings];
            end
        end

        function appCodeData = getAppCodeData(obj)
            % TODO
        end

        function appMetadata = getAppMetadata(obj)
            appMetadataReader = appdesigner.internal.serialization.MAppMetadataReader(obj.FileName);
            appMetadata = appMetadataReader.readMetadata();

            % TODO: M-app should use its own versioning scheme (2025b work)
            appMetadata.MLAPPVersion = '2';
            
        end

    end

    methods (Access = private)
        function metadata = validateMetaData(obj, metadata)
            % #fix - plain-text app metadata validation - replace with new API(s)

            for i = 1:numel(obj.Validators)
                obj.Validators{i}.validateMetaData(metadata);
            end

            appMetadataModel = appdesigner.internal.model.MetadataModel();

            % Any sets that fail will be ignored as to not disrupt the loading
            % process.
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
            for i = 1:numel(obj.Validators)
                obj.Validators{i}.validateAppData(metadata, appData);
            end
        end

        function initFromFile(obj)
            if isempty(obj.FileContent) || isempty(obj.AppendixParser)
                try
                    obj.FileContent = appdesigner.internal.cacheservice.readAppFile(char(obj.FileName));
                    obj.CodeParser = appdesigner.internal.serialization.PlainTextCodeParser(obj.FileContent);
                    obj.AppendixParser = appdesigner.internal.serialization.AppAppendixParser(obj.FileName, obj.FileContent);
                catch me
                    throwAsCaller(me);
                end

                if isempty(obj.FileContent)
                    me = appdesigner.internal.artifactgenerator.exception.AppAppendixMissingException(obj.FileName);
                    throw(me);
                end

            end

        end

        function codeText = readMATLABCodeText(obj)
            obj.initFromFile();

            appendixIndex = strfind(obj.FileContent, "%[appendix]");

            if isempty(appendixIndex)
                % TODO - consider throwing appendix-missing exception?
                codeText = obj.FileContent;
            else
                codeText = obj.FileContent(1:strfind(obj.FileContent, appendixIndex - 1));
            end
            
        end

        function [appData, appFormatVersion] = readAppDesignerData(obj)
            obj.initFromFile();

            [appData.components.UIFigure, callbackInfo] = appdesigner.internal.application.initMAppComponentsForLoad(obj.FileName);

            startupName = obj.AppendixParser.getStartUpName();

            isSingleton = obj.AppendixParser.isSingleton();

            appData.code = obj.CodeParser.parseCodeData(callbackInfo, startupName, isSingleton);

            % TODO - blank until metadata APIs
            appData.appData = appdesigner.internal.serialization.app.AppData([], [], []);

            appData.runConfigurations = obj.AppendixParser.getAppDesignerRunConfig();

            % TODO - get this from appendix
            appFormatVersion = '1.0';

        end
    end

end
