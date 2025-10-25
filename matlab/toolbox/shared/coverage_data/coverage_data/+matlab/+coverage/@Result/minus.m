% - Return the set difference between two coverage results
%
%   LHS - RHS returns the set difference between two matlab.coverage.Result objects.
%   The returned matlab.coverage.Result object contains the coverage outcomes that are
%   satisfied by the left operand LHS, but not the right operand RHS. Use this operator
%   to determine how much additional coverage is attributed to a specific result.
%
%   See also: matlab.coverage.Result.plus, matlab.coverage.Result.times,
%             matlab.coverage.Result.mtimes
%

%   Copyright 2022 The MathWorks, Inc.

function res = minus(lhs, rhs)

arguments
    lhs (:,1) matlab.coverage.Result
    rhs (:,1) matlab.coverage.Result
end

res = matlab.coverage.Result.performOp(lhs, rhs, '-');
