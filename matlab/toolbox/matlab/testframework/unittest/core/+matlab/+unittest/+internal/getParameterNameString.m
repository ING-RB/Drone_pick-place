function str = getParameterNameString(params, leftBracket, rightBracket)
%

% Copyright 2016-2020 The MathWorks, Inc.

if isempty(params)
    str = '';
    return;
end

propNames = {params.Property};
paramNames = {params.Name};
extMask = [params.External];
extDelimiter = {'', '#ext'};

numParams = numel(propNames);
propAndParamNames = cell(1,numParams);
for idx = 1:numParams
    propAndParamNames{idx} = [propNames{idx} '=' paramNames{idx} extDelimiter{extMask(idx)+1}];
end

str = [leftBracket, char(string(propAndParamNames).join(",")), rightBracket];
end
