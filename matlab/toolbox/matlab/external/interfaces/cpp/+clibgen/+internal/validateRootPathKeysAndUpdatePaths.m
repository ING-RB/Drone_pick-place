function parsedResults = validateRootPathKeysAndUpdatePaths(parser, headers)
% Validate and update RootPath keys

%   Copyright 2024 The MathWorks, Inc.

    parsedResults = parser.Results;
    rootpaths = dictionary(string([]),string([]));
    if isfield(parsedResults, "RootPaths")
        rootpaths = parsedResults.RootPaths;
    end
    [deferred, headersAbsolute] = isValidationDeferred(headers,'InterfaceGenerationFiles');
    if deferred
        clibgen.internal.validateHeaders(parser, headersAbsolute);
    end
    parsedResults.HeaderFilesRelative = string(headers);
    parsedResults.HeaderFiles = headersAbsolute;

    [deferred, librariesAbsolute] = isValidationDeferred(parsedResults.Libraries,'Libraries');
    if deferred
        clibgen.internal.validateLibName(librariesAbsolute);
    end
    parsedResults.LibrariesRelative = string(parsedResults.Libraries);
    parsedResults.Libraries = librariesAbsolute;

    [deferred, includePathAbsolute] = isValidationDeferred(parsedResults.IncludePath,'IncludePath');
    if deferred
        clibgen.internal.validateUserIncludePath(includePathAbsolute);
    end
    parsedResults.IncludePathRelative = string(parsedResults.IncludePath);
    parsedResults.IncludePath = includePathAbsolute;

    [deferred, outputFolderAbsolute] = isValidationDeferred(parsedResults.OutputFolder,'OutputFolder');
    if deferred
        clibgen.internal.validateOutputDir(outputFolderAbsolute);
    end
    parsedResults.OutputFolderRelative = string(parsedResults.OutputFolder);
    parsedResults.OutputFolder = outputFolderAbsolute;

    [deferred, supportingSourceFilesAbsolute] = isValidationDeferred(parsedResults.SupportingSourceFiles,'SupportingSourceFiles');
    if deferred
        clibgen.internal.validateSourceFile(supportingSourceFilesAbsolute);
    end
    parsedResults.SupportingSourceFilesRelative = string(parsedResults.SupportingSourceFiles);
    parsedResults.SupportingSourceFiles = supportingSourceFilesAbsolute;

    parsedResults.RootPathKeys   = keys(rootpaths)';
    parsedResults.RootPathValues = rootpaths.values';

        function [deferred, paths] = isValidationDeferred(paths,option)
        deferred = false;
        if isempty(paths)
            return;
        end
        rootpathIndices = find(startsWith(paths, "<"));
        if ~isempty(rootpathIndices)
            % at least one path seems to refer to a 'RootPaths' key
            for idx = rootpathIndices
                if count(paths(idx),">") ~= 1
                    error(message('MATLAB:CPP:InvalidRootPathKeySyntax',paths(idx),option));
                end
                key = extractBetween(paths(idx),"<",">");
                if ~isvarname(key)
                    error(message('MATLAB:CPP:InvalidRootPathKey',key,option));
                elseif ~isConfigured(rootpaths) || ~isKey(rootpaths,key)
                    error(message('MATLAB:CPP:SpecifyRootPathOption',key,option));
                else
                    paths(idx) = replace(paths(idx),strcat("<",key,">"),rootpaths(key));
                end
            end
            deferred = true;
        end
    end
end
