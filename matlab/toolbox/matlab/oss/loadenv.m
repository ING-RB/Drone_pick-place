function out = loadenv(filename,opts)
arguments
    filename {mustBeTextScalar,mustBeNonzeroLengthText}
    opts.OverwriteEnvironmentVariable (1,1) logical {mustBeNumericOrLogical} = true
    opts.ExpandVariables (1,1) logical {mustBeNumericOrLogical} = true
    opts.Encoding(1,1) string {mustBeTextScalar} = "UTF-8"
    opts.FileType (1,1) string {mustBeMember(opts.FileType,["auto","env"])}
end

try
    nargoutchk(0,1);
    % User has not supplied FileType N-V pair.
    if ~isfield(opts,"FileType")
        opts.FileType = "auto";
        opts.ExplicitFileType = false;
    else
        opts.ExplicitFileType = true;
    end

    loadEnvObj = matlab.oss.internal.LoadEnv(filename,opts);
    if nargout == 1
        out = loadEnvObj.validateAndExecute(true);
    else
        loadEnvObj.validateAndExecute(false);
    end
catch ME
    throw(ME)
end
end

% Copyright 2022-2023 The MathWorks, Inc.