function loadOutcome = saveAppCode(srcFilepath, dstFilePath, updatedCodeText, updatedCodeData, isUseOriginalClassName)   
    % SAVEAPPCODE Facade API for App Designer Comparision side saving 
    % diff/merge result to a mlapp file
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    % Assume save will be successful
    loadOutcome.Status = 'success';
    
    try
        % Use a deserializer to get the App Code Data only
        [loadedCodeData, loadedCompatiblityData, loadedMetaData] = appdesigner.internal.comparison.getAppData(srcFilepath);
        
        % Update code data which has been changed from the client merging tool
        updatedCodeDataFileds = fieldnames(updatedCodeData);
        for ix = 1:numel(updatedCodeDataFileds)
            fieldName = updatedCodeDataFileds{ix};
            loadedCodeData.(fieldName) = updatedCodeData.(fieldName);
        end

        if ~strcmp(srcFilepath, dstFilePath)
            % if it's not to overwrite the same file, make a copy to preseve 
            % data that is not in the memory, for instance, screenshot.
            fileWriter = appdesigner.internal.serialization.FileWriter(dstFilePath);
            fileWriter.copyAppFromFile(srcFilepath);
        end

        % Create the serializer without UIFigure
        serializer = appdesigner.internal.serialization.MLAPPSerializer(dstFilePath, []);

        % set data on the Serializer to be serialized: MatlabCodeText,
        % Metadata, Groups, EditableCode, Callback, StartupCallbacks.
        

        % use original ClassName for source control workflow e.g. save conflicts
        % otherwise use file name as ClassName
        if isUseOriginalClassName
            serializer.MatlabCodeText = updatedCodeText; 
            serializer.ClassName = loadedCodeData.ClassName;
        else
            % Use MLAPP exporter to ensure class name and constructor to be
            % updated when the new file name is different from the orignal one
            exporter = appdesigner.internal.serialization.converter.MLAPPExporter(dstFilePath, struct('originalName', loadedCodeData.ClassName));
            serializer.MatlabCodeText = exporter.getGeneratedCode(updatedCodeText);
        end
        
        % create MetadataModel for meta data to set on serializer
        metaDataModel = appdesigner.internal.model.MetadataModel();
        % override AppType when it is different than standard
        metaDataModel.AppType = loadedMetaData.AppType;
        % override metadata with fields in new compatibility data
        metaDataModelFields = fieldnames(loadedCompatiblityData);
        for ix = 1:numel(metaDataModelFields)
            metaFeildName = metaDataModelFields{ix};
            if isprop(metaDataModel, metaFeildName)
                metaDataModel.(metaFeildName) = loadedCompatiblityData.(metaFeildName);
            end
        end
        serializer.Metadata  = metaDataModel;

        % use a field list to filter eligible MLAPPSerializer fields on loadedCodeData
        fieldListToSerialize = serializer.SerializableCodeDataProperties;

        codeDataToSave = loadedCodeData;
        codeDataFields = fieldnames(codeDataToSave);
        for ix = 1:numel(codeDataFields)
            codeField = codeDataFields{ix};
            if strcmp('Callbacks', codeField) && isfield(codeDataToSave.(codeField), 'ComponentData')
                % Old version has ComponentData in callback, but for new version we should not save it
                % This seems a serializaton bug in App Designer. Will talk to Kyle.
                serializer.(codeField) = rmfield(codeDataToSave.(codeField), 'ComponentData');
            elseif any(strcmp(fieldListToSerialize, codeField))
                serializer.(codeField) = codeDataToSave.(codeField);
            end
        end

        % Update only the app code data
        serializer.updateAppCodeData()
    catch me
        % Error Message
        loadOutcome.Message = me.message;
        loadOutcome.Status = 'error';
        loadOutcome.ErrorID = me.identifier;
    end
end