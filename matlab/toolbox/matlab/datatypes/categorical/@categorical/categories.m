function l = categories(a,varargin)
%

%   Copyright 2013-2024 The MathWorks, Inc.

import matlab.internal.datatypes.getChoice

l = a.categoryNames;
if nargin > 1
    pnames = {'OutputType'};
    dflts =  {'char'      };
    outputType = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});

    choices = ["categorical" "string" "char"];
    choiceNum = getChoice(outputType,choices,'MATLAB:categorical:InvalidCategoryOutputType');

    if choiceNum == 1 % "categorical"
        l = fastCtor(a,(1:length(l))');
    elseif choiceNum == 2 % "string"
        l = string(l);
    else % "char"
        % leave l as is
    end
end
