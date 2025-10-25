function name = getLegacyTestName(parentName, testName, parameterization)
%

% Copyright 2022 The MathWorks, Inc.

[classSetupParams, methodSetupParams, testParams] = parameterization.filterByType;

classSetupParamsStr  = getLegacyParameterNameString(classSetupParams, '[', ']');
methodSetupParamsStr = getLegacyParameterNameString(methodSetupParams, '[', ']');
testParamsStr        = getLegacyParameterNameString(testParams, '(', ')');

name = [parentName, classSetupParamsStr, '/', ...
    methodSetupParamsStr, testName, testParamsStr];
end

function str = getLegacyParameterNameString(params, leftBracket, rightBracket)
if isempty(params)
    str = '';
    return;
end

propNames = {params.Property};
paramLegacyNames = {params.LegacyName};
extMask = [params.External];
extDelimiter = {'', '#ext'};

numParams = numel(propNames);
propAndParamNames = cell(1,numParams);
for idx = 1:numParams
    propAndParamNames{idx} = [propNames{idx} '=' paramLegacyNames{idx} extDelimiter{extMask(idx)+1}];
end

str = [leftBracket, char(string(propAndParamNames).join(",")), rightBracket];
end
