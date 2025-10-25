function u = lowerbound(T) %#codegen
% LOWERBOUND Lower bound of the range of an embedded.numerictype object
%     L = lowerbound(A) returns the lower bound of the range of an
%     embedded.numerictype object.
%     If L = lowerbound(A) and U = upperbound(A) then [L, U] = range(A). 
%  
%     See also embedded.numerictype/upperbound, embedded.numerictype/range,
%     embedded.fi/lowerbound

%     Copyright 2017-2018 The MathWorks, Inc.
    if isscalingunspecified(T)
        error(message('fixed:numerictype:scalingRequired', 'LOWERBOUND'));
    end
    u = lowerbound(fi([],T));
end