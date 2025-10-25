%

%   Copyright 2022 The MathWorks, Inc.

function resObj = createDerivedData(lhsObj, rhsObj, op)

arguments
    lhsObj (1,1) matlab.coverage.Result
    rhsObj (1,1) matlab.coverage.Result
    op (1,1) char
end

% Perform the operation on code coverage data
if nargin == 3 && ischar(op)
    % LHS and RHS can have the same checksum but can have different
    % instrumentation settings, then need to align the coverage
    [lhsObj, rhsObj] = alignCoverageCollectorDataMetrics(lhsObj, rhsObj);
    codeCovData = codeinstrum.internal.codecov.CodeCovData.performOp(lhsObj.CodeCovData, rhsObj.CodeCovData, op);
    resObj = matlab.coverage.Result(codeCovData);
else
    resObj = matlab.coverage.Result();
end

% Perform the operation on the settings and some properties
resObj.IsDerivedData = true;

%% ------------------------------------------------------------------------
function [lhsObj, rhsObj] = alignCoverageCollectorDataMetrics(lhsObj, rhsObj)
% Get the code coverage data of each operand
lhsCodeCovDataImpl = lhsObj.CodeCovData.CodeCovDataImpl;
rhsCodeCovDataImpl = rhsObj.CodeCovData.CodeCovDataImpl;

% Compute the set of enabled metrics and find the metrics in common
lhsCodeTr = lhsCodeCovDataImpl.CodeTr;
rhsCodeTr = rhsCodeCovDataImpl.CodeTr;
if (lhsCodeTr == rhsCodeTr) || (lhsObj.ExecutionMode ~= "MATLAB")
    return
end
lhsSet = lhsCodeTr.Root.metrics.toArray();
rhsSet = rhsCodeTr.Root.metrics.toArray();
lhsNotInRhs = find(~ismember(lhsSet, rhsSet));
rhsNotInLhs = find(~ismember(rhsSet, lhsSet));
if (numel(lhsNotInRhs) > 0) && (numel(rhsNotInLhs) > 0)
    % One operand must have its metrics included into the other
    error(message("MATLAB:coverage:result:CheckIncompCovMetrics"));
end

% Align the operand that has less metrics
if numel(lhsNotInRhs) > 0
    % The LHS has more metrics
    alignedCovDataImpl = matlab.coverage.internal.alignCodeCoverageData(rhsCodeCovDataImpl, lhsCodeCovDataImpl);
    rhsObj.CodeCovData.updateImpl(alignedCovDataImpl);
elseif numel(rhsNotInLhs) > 0
    % The RHS has more metrics
    alignedCovDataImpl = matlab.coverage.internal.alignCodeCoverageData(lhsCodeCovDataImpl, rhsCodeCovDataImpl);
    lhsObj.CodeCovData.updateImpl(alignedCovDataImpl);
end

% LocalWords:  MCDC
