function tf = isScalarText(rhs, opts)
%ISSCALARTEXT Returns true if rhs is a scalar string, char row vector, or
% 0x0 char vector.

% Copyright 2023 The MathWorks, Inc.

    arguments
        rhs
        opts.AcceptMissingString(1, 1) logical = false
    end

    tf = false;
    if isstring(rhs)
        tf = isscalar(rhs) && ismissing(rhs) == opts.AcceptMissingString;
    elseif ischar(rhs)
        tf = isrow(rhs) || (isempty(rhs) && ismatrix(rhs) && ~isvector(rhs));
    end
end
