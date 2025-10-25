classdef AcceptsReadableFilename < matlab.io.internal.FunctionInterface ...
        & matlab.io.internal.functions.AcceptsWebOptions
    %ACCEPTSFILENAME An interface for functions which accept a filename.

    % Copyright 2018-2024 The MathWorks, Inc.
    properties (Required, Dependent)
        Filename;
    end

    properties (SetAccess = private)
        Extension = '';
        FilenameValidated  = '';
    end

    properties (Dependent)
        InputFilename
        LocalFileName
    end

    properties (Access = protected)
        RemoteToLocal
    end

    methods
        function val = get.InputFilename(obj)
            val = obj.RemoteToLocal.OriginalName;
        end

        function val = get.LocalFileName(obj)
            val = obj.RemoteToLocal.createLocalCopy();
        end

        function val = get.Filename(obj)
            import matlab.io.internal.filesystem.tempfile.TempCompressed;
            val = obj.FilenameValidated;
            exts = TempCompressed.SupportedExtensions;
            % If we can read this as a file, don't use a local version.
            if ~(isfile(val) && ~endsWith(val,exts))
                val = obj.LocalFileName;
            end
        end

        function obj = set.Filename(obj,filename)
            import matlab.io.internal.vfs.validators.hasIriPrefix
            import matlab.io.internal.filesystem.tempfile.*
            import matlab.io.internal.common.validators.*
            import matlab.io.internal.filesystem.isAbsolutePathNoIO

            persistent containerExts
            if isempty(containerExts)
                containerExts = [TempContainer.SupportedExtensions,TempCompressed.SupportedExtensions];
            end

            filename = convertStringsToChars(filename);
            if ~ischar(filename) || isempty(filename)
                error(message('MATLAB:textio:textio:InvalidStringProperty','"filename"'));
            end

            if isGoogleSheet(filename)
                % use Google Drive APIs to determine whether this Google
                % spreadsheet exists
                try
                    googlesheetID = extractGoogleSheetIDFromURL(filename);
                    matlab.io.internal.spreadsheet.fileAttributesForGoogleSheet(googlesheetID);
                catch ME
                    rethrow(ME);
                end
                obj.FilenameValidated = filename;
                obj.RemoteToLocal = GoogleSheetWrapper(filename);
                return
            end

            args = struct();
            if ~isempty(obj.WebOptions)
                args.WebOptions = obj.WebOptions;
            end
            args.OriginalName = filename;
            if ispc && ~hasIriPrefix(filename)
                filename = replace(filename,"/","\");
            end


            if ~isAbsolutePathNoIO(filename) && contains(filename, containerExts+filesep)
                % Need to do path Lookup on the "zip" file if it exists
                pathComponents = split(filename,filesep);
                firstContainerIdx = find(endsWith(pathComponents(:),containerExts),1);
                firstContainer = join(pathComponents(1:firstContainerIdx),filesep);
                [~,~,obj.Extension] = fileparts(pathComponents{end});

                resolvedName = obj.validateFilename(firstContainer);
                obj.FilenameValidated = join([resolvedName{1};pathComponents(firstContainerIdx+1:end)],filesep);
            elseif ~hasIriPrefix(filename) && ~isNestedZip(filename)
                % Local File
                obj.FilenameValidated = obj.validateFilename(filename);
                [~,~,obj.Extension] = fileparts(obj.FilenameValidated);
            else
                obj.FilenameValidated = filename;
                if startsWith(filename,"http",IgnoreCase=true)
                    path = matlab.io.internal.filesystem.pathObject(filename,Type="auto");
                    if strlength(path.Extension) > 0
                        obj.Extension = path.Extension;
                    else
                        obj.Extension = ".txt";
                    end
                else
                    [~,~,obj.Extension] = fileparts(filename);
                end
            end

            if any(obj.Extension == TempCompressed.SupportedExtensions)
                % Replace .gz with the other extension
                components = split(obj.FilenameValidated,filesep);
                fn = extractBefore(components(end),TempCompressed.SupportedExtensions);
                [~,~,obj.Extension] = fileparts(fn);
            end

            obj.RemoteToLocal = tempFileFactory(obj.FilenameValidated,args);
            obj.FilenameValidated = obj.RemoteToLocal.ResolvedName;
            if ismissing(obj.Extension)
                obj.Extension = "";
            end
           

        end

        function fn = validateFilename(obj,filename)
            import matlab.io.internal.filesystem.resolvePath
            res = resolvePath(filename);
            if res.Type == "None"
                if obj.LegacyFilenameValidation 
                    fn = legacyFilenameValidation(obj,filename);
                    return
                end
                error(message('MATLAB:textio:textio:FileNotFound', string(filename)));
            end
            fn = res.ResolvedPath;
        end

        function fn = legacyFilenameValidation(obj,filename)
            import matlab.io.internal.filesystem.resolvePath

            [~,~,ext] = fileparts(filename);
            if strlength(ext) == 0
                extsToCheck = obj.getExtensions();
                for ext = extsToCheck
                    res = resolvePath(filename + ext);
                    if res.Type ~= "None"
                        fn = res.ResolvedPath;
                        return
                    end
                end
            end
            error(message('MATLAB:textio:textio:FileNotFound', string(filename)));
        end
    end

    methods (Abstract)
        exts = getExtensions(obj);
    end

    properties (Access = protected)
        % Enable legacy read<type> filename validation behavior by default.
        %
        % When LegacyFilenameValidation = true,
        % AcceptsReadableFilename will append recognized
        % file extensions (from matlab.io.internal.FileExtensions.<Format>Extensions,
        % where <Format> is based on the value of "FileType")
        % to the provided filename and will read any matching filenames on the
        % MATLAB path, even if the matching filename is not exactly the same as
        % the filename that was provided.
        %
        % ------------
        % For example:
        % ------------
        %
        % FileType = "text"
        % Filename = "foo"
        % Candidates = "foo.csv", "foo.txt", "foo.dat", ...
        %
        LegacyFilenameValidation = true;
    end
end

function tf = isNestedZip(filename)
zip_exts = matlab.io.internal.filesystem.tempfile.TempContainer.SupportedExtensions;
gz_exts = matlab.io.internal.filesystem.tempfile.TempCompressed.SupportedExtensions;
tf = contains(filename, zip_exts + filesep) || endsWith(filename,gz_exts);
end
