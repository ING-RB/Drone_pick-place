  function result = writePlainTextAppFile(path, fileContent, screenshotMode, screenshotPath)
    %WRITEPLAINTEXTAPPFILE Writes text content of M app to file

    % Copyright 2024 The MathWorks, Inc.

    try
        try
            thumbnailSection = appdesigner.internal.application.AppThumbnailUtils.createThumbnailAppendixSectionStr(path, screenshotMode, screenshotPath);
            fileContent = append(fileContent, newline, newline, thumbnailSection);
        catch
            % Failure to create thumbnail shouldn't prevent the rest of the
            % app to be written
        end

        expectedCount = length(fileContent);

        [fID,err] = fopen(path,'w', 'n', 'UTF-8');

        if (~isempty(err))
            errID = 'appdesigner.internal.application.WRITEPLAINTEXTAPPFILE:fopen';
            errMsg = err;
            throw(MException(errID, errMsg));
        end

        count = fwrite(fID, fileContent);

        fclose(fID);

        if count ~= expectedCount
            errID = 'appdesigner.internal.application.WRITEPLAINTEXTAPPFILE:unexpected count';
            errMsg = 'Text writen to file did not match expected length.';
            throw(MException(errID, errMsg));
        end

        appdesigner.internal.application.warmAppCache(path);

        result.FullFileName = path;
        result.Name = 'saveAppResult';
        result.Status = 'success';

    catch me
        result.FullFileName = path;
        result.Name = 'saveAppResult';
        result.Status = 'error';
        result.Message = me.message;
        result.ErrorID = me.identifier;
    end

end
