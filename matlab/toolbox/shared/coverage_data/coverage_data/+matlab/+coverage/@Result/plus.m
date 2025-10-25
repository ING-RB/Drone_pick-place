% + Return the union of two coverage results
%
%   LHS + RHS returns the set union of two matlab.coverage.Result objects.
%   The returned matlab.coverage.Result object contains the total aggregated coverage
%   that are covered by the left operand LHS and the right operand RHS.
%
%   See also: matlab.coverage.Result.minus, matlab.coverage.Result.times,
%             matlab.coverage.Result.mtimes
%

%   Copyright 2022 The MathWorks, Inc.

function res = plus(lhs, rhs)

arguments
    lhs (:,1) matlab.coverage.Result
    rhs (:,1) matlab.coverage.Result
end

res = matlab.coverage.Result.performOp(lhs, rhs, '+');
