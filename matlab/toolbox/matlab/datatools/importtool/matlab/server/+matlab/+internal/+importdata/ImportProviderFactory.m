% This class is unsupported and might change or be removed without notice in a
% future version.

% This class provides functionality for Import Data.

% Copyright 2020-2023 The MathWorks, Inc.

classdef ImportProviderFactory
    methods(Static)

        function provider = getProvider(filename, fileType)
            % Return the provider for for the given filename.  Optional second
            % argument can be the filetype (in a format as finfo returns, like
            % 'audio', 'im', 'video'), or the file extension.

            arguments
                filename (1,1) string {mustBeFile}
                fileType (1,1) string = "unknown";
            end

            % Determine the file type
            if strcmp(fileType, "unknown")
                fileType = matlab.internal.importdata.ImportProviderFactory.getFileType(filename);
            end

            [imByExt, imByType] = matlab.internal.commonimport.DataImporters.getDataImporters();
            provider = [];
            clsName = [];

            if isKey(imByExt, fileType)
                % If the filetype is found by extension, use it
                clsName = imByExt(fileType);
            elseif isKey(imByType, fileType)
                % Otherwise if the filetype is found by type, use it
                clsName = imByType(fileType);
            end

            if any(contains(superclasses(clsName), "matlab.internal.importdata.ImportProvider"))
                % Create an instance of the provider, and set it up for use in the Import Data
                % workflow
                provider = feval(clsName, filename);

                provider.ResolveVariableNames = true;
                provider.SupportsResultDisplay = false;

                [~, p] = matlab.internal.commonimport.DataImporters.getSupportsSkippingDialog();
                if isKey(p, fileType)
                    provider.SupportsSkippingDialog = strcmp(p(fileType), "true");
                end
            end
        end

        function t = getFileType(filename)
            % Return the file type for the given file, by using the finfo
            % function.  (There may be other special extension checks in the
            % future)

            arguments
                filename (1,1) string {mustBeFile}
            end

            t = strings(0);
            if strlength(filename) > 0 && exist(filename, "file") == 2
                t = finfo(char(filename));

                % Additional check for video formats
                if strcmp(t, "unknown")
                    vf = VideoReader.getFileFormats;
                    [~, ~, ext] = fileparts(filename);
                    ext = extractAfter(ext, ".");
                    isVideoFormat = arrayfun(@(x) strcmp(x.Extension, ext), vf);
                    if any(isVideoFormat)
                        t = "video";
                    end
                end
            end
        end

        function s = getAllProviderTypes()
            % Return all known provider types (which implement the
            % ImportProvider abstract class)

            c = internal.findSubClasses('matlab.internal.importdata', 'matlab.internal.importdata.ImportProvider');
            s = string(cellfun(@(x) x.Name, c, "UniformOutput", false));
        end
    end
end
