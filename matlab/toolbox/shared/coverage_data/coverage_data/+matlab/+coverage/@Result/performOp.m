%

%   Copyright 2022 The MathWorks, Inc.

function res = performOp(lhs, rhs, op)
%RESULT/PERFORMOP   Implement "+", "-" and "*" on results

arguments
    lhs (:,1) matlab.coverage.Result
    rhs (:,1) matlab.coverage.Result
    op (1,1) char
end

% Trivial case
if isempty(rhs)
    res = lhs;
    return
end

% Remove invalid data
lhs(~lhs.valid()) = [];
rhs(~rhs.valid()) = [];

if isempty(rhs)
    res = lhs;
    return
elseif isempty(lhs)
    res = rhs;
    return
end

% Compute some keys for matching the lhs and rhs
lhsKeys = strings(1, numel(lhs));
for ii = 1:numel(lhs)
    lhsKeys(ii) = lhs(ii).getKey();
end
rhsKeys = strings(1, numel(rhs));
for ii = 1:numel(rhs)
    rhsKeys(ii) = rhs(ii).getKey();
end

iKeys = intersect(lhsKeys, rhsKeys, 'stable');

res = repmat(matlab.coverage.Result(), [numel(iKeys), 1]);

[~, lhsIdx] = ismember(iKeys, lhsKeys);
[~, rhsIdx] = ismember(iKeys, rhsKeys);
for idx = 1:numel(iKeys)
    % Perform consistency checking
    % Disable for now (checkCompatiblity() only checks the execution mode
    % and the selection that is performed above guarantees that both
    % result objects share the same execution mode).
    %checkCompatibility(lhs(lhsIdx), rhs(rhsIdx));

    % Perform the operation
    res(idx) = matlab.coverage.Result.createDerivedData(lhs(lhsIdx(idx)), rhs(rhsIdx(idx)), op);
end

% Add the results that are not in common
if op ~= '*'
    [~, ilhsKeys, irhsKeys] = setxor(lhsKeys, rhsKeys, 'stable');
    if ~isempty(ilhsKeys)
        res = [res; lhs(ilhsKeys)];
    end
    if op ~= '-' && ~isempty(irhsKeys)
        res = [res; rhs(irhsKeys)];
    end
end
