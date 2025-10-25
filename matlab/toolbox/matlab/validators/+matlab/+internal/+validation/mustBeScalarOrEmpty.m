function mustBeScalarOrEmpty(A)
% MUSTBESCALAROREMPTY is for internal use only and may be removed or
% modified at any time

% MUSTBESCALAROREMPTY Validate that size of value is scalar or empty; otherwise issue an error
%   MUSTBESCALAROREMPTY(A) issues an error if A is not a scalar or empty.
%   MATLAB calls isscalar(A) to determine if A is a scalar and calls
%   isempty(A) to determine if A is empty.
%
%   See also: isscalar, isempty
        
%   Copyright 2019-2020 The MathWorks, Inc.

    if ~isscalar(A) && ~isempty(A)
        errorID = 'MATLAB:validators:mustBeScalarOrEmpty';
        E = MException(errorID, message(errorID).getString);
        throw(E);
    end
end
