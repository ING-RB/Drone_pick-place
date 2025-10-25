function mustBeFileOrCoverageFormat(value, sourceType)
% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2024 The MathWorks, Inc.

arguments
    value
    sourceType (1,1) matlab.buildtool.internal.tasks.CoverageSourceType = matlab.buildtool.internal.tasks.CoverageSourceType.None
end

import matlab.buildtool.internal.tasks.CoverageSourceType

if sourceType == CoverageSourceType.None
    services = matlab.buildtool.internal.services.coverage.CoverageResultsService.empty(1,0);
elseif sourceType == CoverageSourceType.Code
    services = matlab.buildtool.internal.tasks.codeCoverageResultsServices;
elseif sourceType == CoverageSourceType.Model
    services = matlab.buildtool.internal.tasks.modelCoverageResultsServices;
end
supportedFormats = [services(:).CoverageFormatClass];

if ~isa(value, "matlab.buildtool.io.File") && ...
        ~isConvertibleToFile(value) && ...
        ~isa(value, "matlab.unittest.plugins.codecoverage.CoverageFormat")
    throwAsCaller(MException(...
        message("MATLAB:buildtool:TestTask:mustBeFileOrCoverageFormat", ...
        "matlab.buildtool.io.File", sprintf("\t'%s'\n", supportedFormats))));
end
end

function tf = isConvertibleToFile(value)
tf = false;
try
    matlab.buildtool.io.File(value);
    tf = true;
catch
end
end