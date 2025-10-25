function varargout = setdiff(a, b, varargin)
%SETDIFF Set difference.
%   OUT = SETDIFF(A,B)
%   OUT = SETDIFF(A,B,"sorted")
%   OUT = SETDIFF(A,B,"rows",...)
%   OUT = SETDIFF(A,B,...,"rows")
%
%   [OUT,IA] = SETDIFF(...)
%
%   Limitations:
%   1. 'stable' flag is not supported.
%   2. 'legacy' flag is not supported.
%   3. Inputs of type 'char' are not supported.
%   4. Ordinal categorical arrays are not supported.
%
%   See also SETDIFF, TALL.

%   Copyright 2019-2023 The MathWorks, Inc.

% Validate inputs and process flags.
narginchk(2,4);
nargoutchk(0,2);

adaptorA = matlab.bigdata.internal.adaptors.getAdaptor(a);
adaptorB = matlab.bigdata.internal.adaptors.getAdaptor(b);

flags = parseSetfunInputs(a, b, adaptorA, max(1, nargout), mfilename, varargin{:});

% When A and B are numeric, the first ouput type of setdiff must be of the
% same type of A. We cast B so setfunCommon returns the expected type. If
% any of them is a strong type, vertcat logic within setfunCommon deals
% with type conversion.
classA = tall.getClass(a);
classB = tall.getClass(b);
isNotStrongA = ~ismember(classA, matlab.bigdata.internal.adaptors.getStrongTypes);
isNotStrongB = ~ismember(classB, matlab.bigdata.internal.adaptors.getStrongTypes);
if (isNotStrongA && isNotStrongB && ~strcmp(classA, classB))
    if (istall(b))
        b = elementfun(@(x) cast(x, classA), b);
    else
        b = cast(b, classA);
    end
    adaptor = matlab.bigdata.internal.adaptors.getAdaptorForType(classA);
    adaptorB = copySizeInformation(adaptor, adaptorB);
    adaptorC = adaptorA;
else
    adaptorC = matlab.bigdata.internal.adaptors.combineAdaptors(1, ...
        {resetSizeInformation(adaptorA), resetSizeInformation(adaptorB)});
end

% Use common implementation in setfunCommon to get the set of unique
% elements in A and B.
[tOut, ~, isARowVector] = setfunCommon(a, b, adaptorA, adaptorB, max(1, nargout), mfilename, flags);

% Extract data from the common implementation of set functions and find
% setdiff of A and B. Setdiff returns the elements of A
% that are not present in B.
conditionFcn = @(ia, ib) ia > 0 & ib == 0;
[varargout{1:max(1, nargout)}] = extractSetfunResult(tOut, conditionFcn);

% Transpose first output if A is a row vector. This rule is only for
% setdiff.
varargout{1} = changeSetfunRowVector(varargout{1}, isARowVector);

% Update adaptor for c
varargout{1}.Adaptor = resetSizeInformation(adaptorC);

end