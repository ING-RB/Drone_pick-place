% This function is unsupported and might change or be removed without notice
% in a future version.

% Copyright 2023 The MathWorks, Inc
function generateDOCXReportUsingTestSuite(results,suite,varargin)

import matlab.unittest.internal.TestElementModifier.assignTestElement;

modifiedResults = assignTestElement(results,suite);
generateDOCXReport(modifiedResults,varargin{:});

end