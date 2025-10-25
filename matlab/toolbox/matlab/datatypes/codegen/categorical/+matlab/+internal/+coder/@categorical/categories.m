%#codegen
function l = categories(a,varargin)
%CATEGORIES Get a list of a categorical array's categories.

%   Copyright 2018-2023 The MathWorks, Inc.

catNames = a.categoryNames;

if nargin > 1
    pnames = {'OutputType'};
    poptions = struct('CaseSensitivity',false, 'PartialMatching','unique', 'StructExpand',false);
    supplied = coder.internal.parseParameterInputs(pnames,poptions,varargin{:});
    outputType = convertStringsToChars(coder.internal.getParameterValue(supplied.OutputType,{},varargin{:}));

    isScalarText = (ischar(outputType) && isrow(outputType)) || (isstring(outputType) && isscalar(outputType));
    coder.internal.assert(isScalarText,'MATLAB:categorical:CodegenInvalidCategoryOutputType'); % not even text
    coder.internal.assert(coder.internal.isConst(outputType),'MATLAB:categorical:nonConstOption'); % must be const
    
    %choices = ["categorical" "string" "char"];
    choices = {'categorical' 'char'};
    choiceNum = find(strncmpi(outputType,choices,max(strlength(outputType),1)));
    coder.internal.assert(isscalar(choiceNum),'MATLAB:categorical:CodegenInvalidCategoryOutputType');
    if choiceNum == 1 % "categorical"
        l = fastCtor(a,(1:length(catNames))');
    %elseif choiceNum == 2 % "string"
    %    l = string(catNames);
    else % "char"
        l = catNames
    end
else
    l = catNames;
end