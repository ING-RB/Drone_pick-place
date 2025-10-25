function resolvedFilename = resolveConfigurationFilename(configFilename)
%resolveConfigurationFilename    resolve configuration input filename to absolute file path.
%   resolvedFilename = resolveConfigurationFilename(configFilename)
%   takes the filename and uses dir function to find and resolve the
%   absolute path.
%   The input configFilename must have been validated with
%   mustBeNonzeroLengthText, mustBeTextScalar validators.
%   This function is unsupported and might change or be removed without
%   notice in a future version.

%   Copyright 2022 The MathWorks, Inc.

    if configFilename == "active" || configFilename == "factory"
        resolvedFilename = configFilename;
        return;
    end
    configDir = dir(configFilename);
    if ~isempty(configDir)
        resolvedFilename = [configDir.folder filesep configDir.name];
    else
        error(message('MATLAB:codeanalyzer:FileNotFound', configFilename));
    end
end
