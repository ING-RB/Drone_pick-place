function [a,b] = arithUtil(a,b) %#codegen
%ARITHUTIL Convert a pair of values into datetimes in order to perform arithmetic.
%   [A,B] = ARITHUTIL(A,B) returns datetimes corresponding to A and B. If
%   one of the inputs is a string or char array, it is converted into a
%   datetime by treating it as a date string.

%   Copyright 2014-2022 The MathWorks, Inc.

coder.internal.errorIf(matlab.internal.coder.datatypes.isText(a) || matlab.internal.coder.datatypes.isText(b), 'MATLAB:datetime:TextConstructionCodegen');

if isa(a,'datetime') && isa(b,'datetime')
    checkCompatibleTZ(a.tz,b.tz);
end
% Inputs that are not datetimes or strings pass through to the caller
% and are handled there.
