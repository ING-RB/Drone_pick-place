function b = missingLike(a, prototype)
%MISSINGLIKE Create a missing value like the prototype.
%   This function is unsupported and might change or be removed without notice
%   in a future version.
%
%   B = MISSINGLIKE(A, PROTOTYPE) returns a type-specific missing value like the
%   PROTOTYPE (same class and properties) with the size of A.
%
%   See also CREATEARRAY, MATLAB.INTERNAL.DATATYPES.DEFAULTARRAYLIKE

%   Copyright 2023 The MathWorks, Inc.

try
    % Use assignment to convert missing to the target class, so that
    % class can do what it thinks is right. Preserves properties that
    % impact behaviors such as concatenation.
    prototype(1,1) = missing; % class may not support linear indexing
catch
    % No telling what error could happen, throw a generic error msg.
    throwAsCaller(MException(message('MATLAB:invalidConversion', class(prototype), 'missing')));
end
b = repmat(prototype(1,1), size(a));
end