function u = upperbound(T) %#codegen
% UPPERBOUND Upper bound of the range of an embedded.numerictype object
%     U = upperbound(A) returns the upper bound of the range of an
%     embedded.numerictype object.
%     If L = lowerbound(A) and U = upperbound(A) then [L, U] = range(A). 
%  
%     See also embedded.numerictype/lowerbound, embedded.numerictype/range,
%     embedded.fi/upperbound

%     Copyright 2017-2018 The MathWorks, Inc.
    if isscalingunspecified(T)
        error(message('fixed:numerictype:scalingRequired', 'UPPERBOUND'));
    end
    u = upperbound(fi([],T));
end