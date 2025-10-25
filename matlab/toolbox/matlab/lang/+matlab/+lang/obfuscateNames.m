function obfuscateNames(inputFile, outputFileOrDirectory, opts)
%

%   Copyright 2023-2024 The MathWorks, Inc.

    arguments
        inputFile (1,1) string {mustNotBeIRI, mustBeFile, mustBeValidFilename}
        outputFileOrDirectory (1,1) string {mustNotBeIRI}
        opts.PreserveNames (:,1) string {mustBeValidVariableName} = string.empty;
        opts.PreserveNamesFromLiterals (1,1) logical = true;
        opts.PreserveArguments (1,1) logical = true;
        opts.Renaming (1,1) string = "random";
    end

    outputFileOrDirectory = validateOrNormalizeOutput(outputFileOrDirectory, inputFile);
    opts.Renaming = validatestring(opts.Renaming, ["natural", "random"]);

    try
        builtin("_mcheck", inputFile);

        builtin("_stripNames", char(inputFile), ...
                char(outputFileOrDirectory), ...
                cellstr(opts.PreserveNames), ...
                opts.PreserveNamesFromLiterals, ...
                opts.PreserveArguments, ...
                opts.Renaming);
    catch ex
        ex.throw
    end
end

function mustNotBeIRI(filename)
    if matlab.io.internal.vfs.validators.isIRI(filename)
        throw(MException("MATLAB:obfuscateNames:IRINotSupported", ...
                         message("MATLAB:obfuscateNames:IRINotSupported")));
    end
end

function mustBeValidFilename(filename)
    [~, name, ext] = fileparts(filename);
    if strlength(name) == 0
        throw(MException("MATLAB:obfuscateNames:InvalidFilename", ...
                         message("MATLAB:obfuscateNames:InvalidFilename")));
    end
    if ~matches(ext, '.m')
        throw(MException("MATLAB:obfuscateNames:UnsupportedExtension", ...
                         message("MATLAB:obfuscateNames:UnsupportedExtension")));
    end
end

function outputFileOrDirectory = validateOrNormalizeOutput(outputFileOrDirectory, inputFile)
    if isfolder(outputFileOrDirectory)
        [~, inputFileName, inputFileExt] = fileparts(inputFile);
        outputFileOrDirectory = fullfile(outputFileOrDirectory, append(inputFileName, inputFileExt));
    else
        mustBeValidFilename(outputFileOrDirectory);
    end

end
