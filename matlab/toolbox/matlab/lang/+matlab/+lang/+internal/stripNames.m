function stripNames(inputFile, outputFileOrDirectory, opts)
%

%   Copyright 2022-2023 The MathWorks, Inc.
    arguments
        inputFile  (1,1) string {mustNotBeIRI, mustBeFile, mustHaveMExtension}
        outputFileOrDirectory (1,1) string {mustNotBeIRI}
        opts.ExcludeNames (:,1) string {mustBeVarnames} = []
        opts.ExcludeNamesFromStrings (1,1) logical = true
        opts.ExcludeArguments (1,1) logical = true
        opts.InOrder (1,1) logical = false
    end

    builtin("_mcheck", inputFile);

    outputFileOrDirectory = validateOrNormalizeOutput(outputFileOrDirectory, inputFile);

    if (opts.InOrder)
        orderArgString = 'natural';
    else
        orderArgString = 'shuffled';
    end

    builtin("_stripNames", char(inputFile), ...
            char(outputFileOrDirectory), ...
            cellstr(opts.ExcludeNames), ...
            opts.ExcludeNamesFromStrings, ...
            opts.ExcludeArguments, ...
            orderArgString);
end

function mustNotBeIRI(filename)
    if matlab.io.internal.vfs.validators.isIRI(filename)
        throwAsCaller(MException("MATLAB:obfuscateNames:IRINotSupported", ...
                                 message("MATLAB:obfuscateNames:IRINotSupported")));
    end
end

function mustHaveMExtension(filename)
    [~, ~, ext] = fileparts(filename);
    if ext ~= ".m"
        throwAsCaller(MException("MATLAB:obfuscateNames:UnsupportedExtension", ...
                                 message("MATLAB:obfuscateNames:UnsupportedExtension")));
    end
end

function mustBeVarnames(names)
    for name = names'
        if ~isvarname(name)
            throwAsCaller(MException("MATLAB:obfuscateNames:InvalidArgument", ...
                                     message("MATLAB:obfuscateNames:InvalidArgument", name)));
        end
    end
end

function outputFileOrDirectory = validateOrNormalizeOutput(outputFileOrDirectory, inputFile)
    if isfolder(outputFileOrDirectory)
        [~, inputFileName, inputFileExt] = fileparts(inputFile);
        outputFileOrDirectory = fullfile(outputFileOrDirectory, append(inputFileName, inputFileExt));
    else
        mustHaveMExtension(outputFileOrDirectory);
    end

end
