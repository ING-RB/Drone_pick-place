% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality accessing the matlab.import extension
% points.

% Copyright 2022-2024 The MathWorks, Inc.

classdef DataImporters < handle
    methods(Static)
        % Returns two dictionaries, containing the data importers (which
        % define "importUI"), by file extension ("fileExtensions") and file
        % type ("fileTypeCategory").
        function [byExtension, byType] = getDataImporters()
            persistent ext;
            persistent type;

            if isempty(ext) 
                [byExtension, byType] = matlab.internal.commonimport.DataImporters.getImporters("importUI", "importFileFunction");
                ext = byExtension;
                type = byType;
            else
                byExtension = ext;
                byType = type;
            end
        end

        % Returns two dictionaries, containing the live task data importers
        % (which define "importLiveTask"), by file extension
        % ("fileExtensions") and file type ("fileTypeCategory").
        function [byExtension, byType] = getLiveTaskDataImporters()
            persistent ext;
            persistent type;

            if isempty(ext) 
            [byExtension, byType] = matlab.internal.commonimport.DataImporters.getImporters("importLiveTask");
                ext = byExtension;
                type = byType;
            else
                byExtension = ext;
                byType = type;
            end
        end

        % Returns two dictionaries, containing the data importer functions
        % (specified by "importFileFunction"), by file extension
        % ("fileExtensions") and file type ("fileTypeCategory").
        function [byExtension, byType] = getImportFileFunctions()
            persistent ext;
            persistent type;

            if isempty(ext) 
            [byExtension, byType] = matlab.internal.commonimport.DataImporters.getImporters("importFileFunction");
                ext = byExtension;
                type = byType;
            else
                byExtension = ext;
                byType = type;
            end
        end

        % Returns two dictionaries, containing the output arguments for
        % import functions (specified by "importFileFunctionOutputs"), by
        % file extension ("fileExtensions") and file type
        % ("fileTypeCategory")
        function [byExtension, byType] = getImportFileFunctionOutputArgs()
            persistent ext;
            persistent type;

            if isempty(ext) 
            [byExtension, byType] = matlab.internal.commonimport.DataImporters.getImporters("importFileFunctionOutputs");
                ext = byExtension;
                type = byType;
            else
                byExtension = ext;
                byType = type;
            end
        end

        % Returns two dictionaries, containing the
        % supportsDontShowPreference setting of whether skipping the import
        % dialog is supported, by file extension ("fileExtensions") and
        % file type ("fileTypeCategory")
        function [byExtension, byType] = getSupportsSkippingDialog()
            persistent ext;
            persistent type;

            if isempty(ext) 
            [byExtension, byType] = matlab.internal.commonimport.DataImporters.getImporters("supportsDontShowPreference", strings(0), true);
                ext = byExtension;
                type = byType;
            else
                byExtension = ext;
                byType = type;
            end
        end

        % Returns the filter to use for uigetfile, which includes all of
        % the file extensions defined by argument extensions.  By default
        % this is the file extensions for which an "importUI" or
        % "importFileFunction" is defined.  This uses the
        % ImportableFileExtension.getImportToolFileChooserDropDownInfo
        % method as its starting point.
        function filter = getUIGetFileFilter(extensions)
            arguments
                extensions = matlab.internal.commonimport.DataImporters.getDataImporters;
            end

            fileExtDesc = {};
            fileExtList = {};

            % Go through the extensions and labels, and build up cell
            % arrays with them, combining common labels together.
            labels = matlab.internal.commonimport.DataImporters.getDataImporterLabels;
            k = keys(extensions);
            for idx = 1:length(k)
                ext = k(idx);
                if isKey(labels, ext)
                    desc = char(labels(ext)); %#ok<*AGROW>
                else
                    desc = char(ext);
                end

                match = contains(fileExtDesc, desc);
                if any(match)
                    % append the file extension to an existing label
                    currExt = fileExtList{match};
                    if ~iscell(currExt) 
                        currExt = {currExt};
                    end
                    currExt{end + 1} = char("." + ext);
                    fileExtList{match} = sort(currExt);
                else
                    % add the label and extension
                    fileExtDesc{end + 1} = desc;
                    fileExtList{end + 1} = {char("." + ext)};
                end
            end

            % Sort the lists by display name description
            [~, sortIdx] = sort(lower(fileExtDesc));
            fileExtDesc = fileExtDesc(sortIdx);
            fileExtList = fileExtList(sortIdx);

            % Add the 'All Files' entry in
            fileExtDesc{end + 1} = getString(message('MATLAB:codetools:uiimport:AllFilesStr'));
            fileExtList{end + 1} = {'.*'};

            % Create the filter in the format used by uigetfile
            fileExtListExpanded = string(cellfun(@(x) "*" + strjoin(x, '; *'), fileExtList, "UniformOutput", false));
            filter = [fileExtListExpanded', string(fileExtDesc)'];

            % join all the formats together, and add in an option for
            % "Recognized Data Files" at the top, so this is selected by
            % default.  Sort and remove duplicates from the list also.
            allFormats = strjoin(filter(1:end-1,1), ";");
            s = unique(strtrim(split(allFormats, ";")));
            filter = [strjoin(s, "; "), getString(message('MATLAB:codetools:uiimport:RecognizedDataFilesStr')); filter];
        end
    end

    properties(Constant)
        SCHEMA_VERSION = "1.0.0";
    end

    methods(Static, Hidden)
        function [byExtension, byType] = getImporters(prop1, prop2, allowLogicalVals)
            arguments
                prop1 (1,1) string;
                prop2 string = strings(0);
                allowLogicalVals (1,1) logical = false;
            end

            byExtension = dictionary(strings(0), strings(0));
            byType = dictionary(strings(0), strings(0));

            % Find all of the extension points for matlab_import
            extPntSpec = matlab.internal.regfwk.ResourceSpecification;
            extPntSpec.ResourceName = "matlab.import";
            metadatas = matlab.internal.regfwk.getResourceList(extPntSpec);

            % Loop through each of the extension points
            for idx = 1:length(metadatas)
                metadata = metadatas(idx).resourcesFileContents;

                % Verify the version is correct.  The extension point
                % should include the schema to be valid.
                schemaVersion = "";
                if isfield(metadata, "schemaVersion")
                    schemaVersion = metadata.schemaVersion;
                    metadata = rmfield(metadata, "schemaVersion");
                end
                if ~strcmp(schemaVersion, matlab.internal.commonimport.DataImporters.SCHEMA_VERSION)
                    error("unsupported version");
                end

                % Traverse each of the file types specified by this
                % extension point, and pull out the requested content
                f = fieldnames(metadata);
                for jdx = 1:length(f)
                    importerDef = metadata.(f{jdx});

                    % fileExtensions must be specified
                    fExt = importerDef.fileExtensions;
                    if ~iscell(fExt)
                        ex = lasterror; %#ok<*LERR>
                        try
                            % fileExtensions could be a MATLAB function,
                            % eval it to see if that's the case
                            fExt = eval(fExt);
                        catch
                            fExt = {fExt};
                        end
                        lasterror(ex);
                    end

                    % fileTypeCategory is optional.  Use it if specified,
                    % otherwise use the fileExtensions value.
                    if isfield(importerDef, "fileTypeCategory")
                        fType = importerDef.fileTypeCategory;
                        if ~iscell(fType)
                            fType = {fType};
                        end
                    else
                        fType = fExt;
                    end

                    if isfield(importerDef, prop1) && (allowLogicalVals || (~allowLogicalVals && ~islogical(importerDef.(prop1))))
                        importClass = importerDef.(prop1);
                    elseif ~isempty(prop2) && ~isequal(prop1, prop2) && isfield(importerDef, prop2)
                        importClass = importerDef.(prop2);
                    else
                        importClass = strings(0);
                    end

                    if ~isempty(importClass)
                        for kdx = 1:length(fType)
                            byType(fType(kdx)) = importClass;
                        end

                        for kdx = 1:length(fExt)
                            byExtension(fExt(kdx)) = importClass;
                        end
                    end
                end
            end
        end

        % Returns the labels to use for given file types.
        function [byExtension, byType] = getDataImporterLabels()
            [byExtension, byType] = matlab.internal.commonimport.DataImporters.getImporters("fileTypeLabel");

            k = keys(byExtension);
            for idx = 1:length(k)
                key = k(idx);
                try
                    if contains(byExtension(key), ":")
                        byExtension(key) = getString(message(byExtension(key)));
                    end
                catch
                end
            end

            k = keys(byType);
            for idx = 1:length(k)
                key = k(idx);
                try
                    if contains(byType(key), ":")
                        byType(key) = getString(message(byType(key)));
                    end
                catch
                end
            end
        end
    end
end
