function [aData,bData,prototype] = compareUtil(a,b) %#codegen
%COMPAREUTIL Convert datetimes into doubledouble values that can be compared directly.
%   [ADATA,BDATA,PROTOTYPE] = COMPAREUTIL(A,B) returns doubledouble values
%   corresponding to A and B in ADATA and BDATA respectively and a
%   PROTOTYPE datetime, which has the same metadata properties as the
%   datetime object occurring first in the input arguments. If one of the
%   inputs is a string or char array, it is converted into a value by
%   treating it as a text representation of a datetime.

%   Copyright 2019-2023 The MathWorks, Inc.

coder.internal.prefer_const(a,b);

coder.internal.errorIf(matlab.internal.coder.datatypes.isText(a) || matlab.internal.coder.datatypes.isText(b) ...
    ,'MATLAB:datetime:TextConstructionCodegen');
coder.internal.errorIf(isa(a,'duration') || isa(b,'duration'),'MATLAB:datetime:CompareTimeOfDay');

coder.internal.assert(isa(a,'datetime') && isa(b,'datetime'),'MATLAB:datetime:InvalidComparison',class(a),class(b))

% Two datetime inputs must either have or not have a time zone.
checkCompatibleTZ(a.tz,b.tz);

% Both inputs must (by now) be datetime.
aData = a.data;
bData = b.data;

if nargout > 2
    prototype = matlab.internal.coder.datetime(matlab.internal.coder.datatypes.uninitialized);
    prototype.fmt = a.fmt;
    prototype.tz = a.tz;
end
