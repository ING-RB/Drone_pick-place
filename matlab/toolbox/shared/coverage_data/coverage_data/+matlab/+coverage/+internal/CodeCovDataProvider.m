%

% Copyright 2022 The MathWorks, Inc.

classdef CodeCovDataProvider

    methods (Abstract)
        cvds = getCodeCovData(this)
    end
end
