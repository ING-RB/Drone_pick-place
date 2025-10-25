function file = resolveFileToSourceFile(source)
% This function is undocumented and may change in a future release.

% Resolve file to valid source file.

%  Copyright 2022-2024 The MathWorks, Inc.

import matlab.unittest.internal.fileResolver;
import matlab.unittest.internal.coverage.supportedCoverageSourceExtensions;
    
source = string(fileResolver(source)); % Get absolute path to file
if ~endsWith(source,supportedCoverageSourceExtensions())
    error(message('MATLAB:unittest:CodeCoveragePlugin:InvalidFileType',source));
end
file = source;
end

