function varargout = setxor(a, b, varargin)
%SETXOR Set union.
%   OUT = SETXOR(A,B)
%   OUT = SETXOR(A,B,"sorted")
%   OUT = SETXOR(A,B,"rows",...)
%   OUT = SETXOR(A,B,...,"rows")
%
%   [OUT,IA,IB] = SETXOR(...)
%
%   Limitations:
%   1. 'stable' flag is not supported.
%   2. 'legacy' flag is not supported.
%   3. Inputs of type 'char' are not supported.
%   4. Ordinal categorical arrays are not supported.
%
%   See also SETXOR, TALL.

%   Copyright 2019-2023 The MathWorks, Inc.

% Validate inputs and process flags.
narginchk(2,4);
nargoutchk(0,3);
adaptorA = matlab.bigdata.internal.adaptors.getAdaptor(a);
adaptorB = matlab.bigdata.internal.adaptors.getAdaptor(b);

flags = parseSetfunInputs(a, b, adaptorA, max(1, nargout), mfilename, varargin{:});

% Use common implementation in setfunCommon to get the set of unique
% elements in A and B.
[tOut, isRowVector] = setfunCommon(a, b, adaptorA, adaptorB, max(1, nargout), mfilename, flags);

% Extract data from the common implementation of set functions
% Find exclusive-or between A and B. It returns elements in either A or
% B but not in both.
conditionFcn = @(ia, ib) (ia > 0 & ib == 0) | (ib > 0 & ia == 0);
[varargout{1:max(1, nargout)}] = extractSetfunResult(tOut, conditionFcn);
% Keep indices of existing elements in A or B.
if nargout > 1
    varargout{2} = filterslices(varargout{2} > 0, varargout{2});
    if nargout > 2
        varargout{3} = filterslices(varargout{3} > 0, varargout{3});
    end
end

% Transpose first output if both inputs A and B are row vectors
varargout{1} = changeSetfunRowVector(varargout{1}, isRowVector);

% Update adaptor for c
adaptorA = resetSizeInformation(adaptorA);
adaptorB = resetSizeInformation(adaptorB);
varargout{1}.Adaptor = matlab.bigdata.internal.adaptors.combineAdaptors(1, {adaptorA, adaptorB});

end