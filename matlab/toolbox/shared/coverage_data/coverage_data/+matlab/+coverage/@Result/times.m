% * Return the intersection between two coverage results
%
%   LHS * RHS returns the set intersection between two matlab.coverage.Result objects.
%   The returned matlab.coverage.Result object contains only the coverage satisfied
%   by both operands. Use this operator to determine if there is overlapping coverage
%   between the results.
%
%   See also: matlab.coverage.Result.plus, matlab.coverage.Result.minus,
%             matlab.coverage.Result.mtimes
%

%   Copyright 2022 The MathWorks, Inc.

function res = times(lhs, rhs)

arguments
    lhs (:,1) matlab.coverage.Result
    rhs (:,1) matlab.coverage.Result
end

res = matlab.coverage.Result.performOp(lhs, rhs, '*');
