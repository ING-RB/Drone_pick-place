function code = addCellStrToCode(code,values,isIndented)
% addCellStrToCode: Helper for performing tasks in a Live Script
% This function takes a cellstr and adds it to code as a string array
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2019-2022 The MathWorks, Inc.

if nargin < 3
    isIndented = false;
end

if isempty(values)
    % add empty array
    code = matlab.internal.dataui.addCharToCode(code,'[]',isIndented);
elseif numel(values) == 1
    % add one element string array
    code = matlab.internal.dataui.addCharToCode(code,matlab.internal.dataui.cleanVarName(values{1}),isIndented);
else
    % start array
    code = matlab.internal.dataui.addCharToCode(code,['[' matlab.internal.dataui.cleanVarName(values{1}) ','],isIndented);
    for idx = 2:numel(values)
        % add string elements into array
        code = matlab.internal.dataui.addCharToCode(code,[matlab.internal.dataui.cleanVarName(values{idx}) ','],isIndented);
    end
    % remove final comma and close array
    code = [code(1:end-1) ']'];
end
end