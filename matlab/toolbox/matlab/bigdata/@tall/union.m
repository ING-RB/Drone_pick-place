function varargout = union(a, b, varargin)
%UNION Set union.
%   OUT = UNION(A,B)
%   OUT = UNION(A,B,"sorted") 
%   OUT = UNION(A,B,"rows",...)
%   OUT = UNION(A,B,...,"rows")
%
%   [OUT,IA,IB] = UNION(...)  
%   
%   Limitations:
%   1. 'stable' flag is not supported.
%   2. 'legacy' flag is not supported.
%   3. Inputs of type 'char' are not supported.
%   4. Ordinal categorical arrays are not supported.
%
%   See also UNION, TALL.

%   Copyright 2018-2023 The MathWorks, Inc.

% Validate inputs and process flags.
narginchk(2,4);
nargoutchk(0,3);
adaptorA = matlab.bigdata.internal.adaptors.getAdaptor(a);
adaptorB = matlab.bigdata.internal.adaptors.getAdaptor(b);

flags = parseSetfunInputs(a, b, adaptorA, max(1, nargout), mfilename, varargin{:});

% Use common implementation in setfunCommon to get the set of unique
% elements in A and B.
[tOut, isRowVector] = setfunCommon(a, b, adaptorA, adaptorB, max(1, nargout), mfilename, flags);

% Extract data from the common implementation of set functions and find
% the union of A and B.
if nargout > 1
    [c, ia, ib] = extractSetfunResult(tOut);
    % Return indices in A
    idx = ia > 0;
    varargout{2} = filterslices(idx, ia);
    if nargout > 2
        % Return indices in B. Only those that appear in B but not in A.
        idx = ib > 0 & ia == 0;
        varargout{3} = filterslices(idx, ib);
    end
else
    % In this case, tOut only contains C.
    c = subsref(tOut, substruct('.', 'C'));
end
varargout{1} = c;

% Transpose first output if both inputs A and B are row vectors
varargout{1} = changeSetfunRowVector(varargout{1}, isRowVector);

% Update adaptor for c
adaptorA = resetSizeInformation(adaptorA);
adaptorB = resetSizeInformation(adaptorB);
varargout{1}.Adaptor = matlab.bigdata.internal.adaptors.combineAdaptors(1, {adaptorA, adaptorB});

end
