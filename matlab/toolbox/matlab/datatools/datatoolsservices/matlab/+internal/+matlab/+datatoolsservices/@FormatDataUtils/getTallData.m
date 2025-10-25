% Determine the secondary information for tall variables, using the getArrayInfo
% information

% Copyright 2015-2023 The MathWorks, Inc.

function [secondaryType, secondaryStatus] = getTallData(vardata)
    tallInfo = matlab.bigdata.internal.util.getArrayInfo(vardata);

    if isempty(tallInfo.Class)
        secondaryType = '';
    else
        secondaryType = tallInfo.Class;
    end

    if tallInfo.Gathered
        secondaryStatus = '';
    else
        secondaryStatus = getString(message(...
            'MATLAB:codetools:variableeditor:Unevaluated'));
    end
end
