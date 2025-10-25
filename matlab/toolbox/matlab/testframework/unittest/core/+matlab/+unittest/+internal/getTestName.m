function name = getTestName(parentName, testName, parameterization)
%

% Copyright 2016-2023 The MathWorks, Inc.

import matlab.unittest.internal.getParameterNameString;

[classSetupParams, methodSetupParams, testParams] = parameterization.filterByType;

classSetupParamsStr  = getParameterNameString(classSetupParams, '[', ']');
methodSetupParamsStr = getParameterNameString(methodSetupParams, '[', ']');
testParamsStr        = getParameterNameString(testParams, '(', ')');

if strlength(parentName) > 0 || strlength(classSetupParamsStr) > 0
    paramSep = '/';
else
    paramSep = '';
end

name = [parentName, classSetupParamsStr, paramSep, ...
    methodSetupParamsStr, testName, testParamsStr];
end
