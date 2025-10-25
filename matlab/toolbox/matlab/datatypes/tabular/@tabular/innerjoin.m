function [c,il,ir] = innerjoin(a,b,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

narginchk(2,inf);
if ~istabular(a) || ~istabular(b)
    error(message('MATLAB:table:join:InvalidInput'));
end

type = 'inner';
keepOneCopy = [];
pnames = {'Keys' 'LeftKeys' 'RightKeys' 'LeftVariables' 'RightVariables'};
dflts =  {   []         []          []              []               [] };
[keys,leftKeys,rightKeys,leftVars,rightVars,supplied] ...
         = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
supplied.KeepOneCopy = 0;
    
[leftVars,rightVars,leftVarDim,rightVarDim,leftKeyVals,rightKeyVals,leftKeys,rightKeys,c_metaDim] ...
    = tabular.joinUtil(a,b,type,inputname(1),inputname(2), ...
                       keys,leftKeys,rightKeys,leftVars,rightVars,keepOneCopy,supplied);

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
