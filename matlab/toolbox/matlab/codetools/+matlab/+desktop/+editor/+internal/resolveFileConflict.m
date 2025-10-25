function resolveFileConflict(rtcId, fileOnDisk, temporaryFile)
%matlab.desktop.editor.internal.resolveFileConflict Opens a merge tool to compare and merge two files.
%   matlab.desktop.editor.internal.resolveFileConflict(RTCID, FILEONDISK, TEMPORARYFILE) opens a merge tool for the editor
%   identified by RTCID. It compares and merges two versions of a file specified by FILEONDISK and
%   TEMPORARYFILE. FILEONDISK is the absolute path of the file opened in the editor, and TEMPORARYFILE
%   is the absolute path of the temporary file, which contains the unsaved contents of the editor.
%
%   Note: This function is unsupported and might change or be removed without notice in a future version.

%   Copyright 2023 The MathWorks, Inc.

    arguments
        rtcId {mustBeTextScalar, mustBeNonzeroLengthText}
        fileOnDisk {mustBeFile}
        temporaryFile {mustBeFile}
    end
    rtcId = convertCharsToStrings(rtcId);

    mlock
    persistent mergeTools;

    if isempty(mergeTools)
        mergeTools = dictionary;
    elseif isKey(mergeTools, rtcId)
        uuid = mergeTools(rtcId);
        mergeTools(rtcId) = [];
        % Erase will close and reopen merge tool which will update the contents and bring the new tool to top.
        comparisons.internal.appstore.erase(uuid);
    end

    [~, filename, ext] = fileparts(fileOnDisk);
    import comparisons.internal.makeFileSource;
    fs1 = makeFileSource(fileOnDisk, Title=[filename ext], TitleLabel=getString(message('MATLAB:Editor:Document:ExternalVersionTitle')));
    fs2 = makeFileSource(temporaryFile, Title=[filename ext], TitleLabel=getString(message('MATLAB:Editor:Document:EditorVersionTitle')));
    mergeTool = comparisons.internal.gui.compare( ...
        fs1, ...
        fs2, ...
        comparisons.internal.makeTwoWayOptions( ...
            EnableSwapSides=false, ...
            MergeConfig=comparisons.internal.merge.MergeIntoTarget( ...
                fs1.Path, @mergeCompleteCallback ...
            ) ...
        ) ...
    );
    mergeTools(rtcId) = mergeTool.getUUID();
    comparisons.internal.appstore.register(mergeTool, @() closeCallback(mergeTools(rtcId)));

    function mergeCompleteCallback
        connector.ensureServiceOn;
        message.publish(strcat("/editor/merge/status/", rtcId), "merge_complete");
    end

    function closeCallback(uuid)
        if ~isKey(mergeTools, rtcId) || ~strcmp(mergeTools(rtcId), uuid)
            return;
        end
        mergeTools(rtcId) = [];
        delete(temporaryFile);
    end
end
