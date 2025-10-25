function [c,il,ir] = innerjoin(a,b,varargin) %#codegen
%INNERJOIN Inner join between two tables or two timetables.

%   Copyright 2020-2023 The MathWorks, Inc.

narginchk(2,inf);
coder.internal.assert(istabular(a) && istabular(b),'MATLAB:table:join:InvalidInput');

type = 'inner';
keepOneCopy = [];
mergeKeys = [];
pnames = {'Keys' 'LeftKeys' 'RightKeys' 'LeftVariables' 'RightVariables'};
poptions = struct('CaseSensitivity', false, ...
                  'PartialMatching', 'unique', ...
                  'StructExpand',    false);
supplied = coder.internal.parseParameterInputs(pnames, poptions, varargin{:});
supplied.KeepOneCopy = 0;

keys        = coder.internal.getParameterValue(supplied.Keys,           [], varargin{:});
leftKeys    = coder.internal.getParameterValue(supplied.LeftKeys,       [], varargin{:});
rightKeys   = coder.internal.getParameterValue(supplied.RightKeys,      [], varargin{:});
leftVars    = coder.internal.getParameterValue(supplied.LeftVariables,  [], varargin{:});
rightVars   = coder.internal.getParameterValue(supplied.RightVariables, [], varargin{:});

coder.internal.assert(coder.internal.isConst(keys),        'MATLAB:table:join:NonConstantArg', 'Keys');
coder.internal.assert(coder.internal.isConst(leftKeys),    'MATLAB:table:join:NonConstantArg', 'LeftKeys');
coder.internal.assert(coder.internal.isConst(rightKeys),   'MATLAB:table:join:NonConstantArg', 'RightKeys');
coder.internal.assert(coder.internal.isConst(leftVars),    'MATLAB:table:join:NonConstantArg', 'LeftVariables');
coder.internal.assert(coder.internal.isConst(rightVars),   'MATLAB:table:join:NonConstantArg', 'RightVariables');
    
[leftVars,rightVars,leftVarDim,rightVarDim,leftKeyVals,rightKeyVals,leftKeys,rightKeys,c_metaDim] ...
    = tabular.joinUtil(a,b,type,'','', ...
                       keys,leftKeys,rightKeys,leftVars,rightVars,keepOneCopy,mergeKeys,supplied);

% For an inner join, the key values are equal (up to type) between left and
% right inputs, so if neither leftVariables nor rightVariables are provided,
% only one copy of the keys, from the left input, are returned in the output.
% The key pairs are not merged per se, but their properties are merged
% right-into-left. If either leftVariables or rightVariables are provided, they
% indicate exactly which key variables are returned in the output, possibly both
% copies, and their properties are not merged.
mergeKeyProps = ~supplied.LeftVariables && ~supplied.RightVariables;

leftOuter = false;
rightOuter = false;
[c,il,ir] = tabular.joinInnerOuter(a,b,leftOuter,rightOuter,leftKeyVals,rightKeyVals, ...
                                   leftVars,rightVars,leftKeys,rightKeys,leftVarDim,rightVarDim, ...
                                   mergeKeyProps,c_metaDim);
