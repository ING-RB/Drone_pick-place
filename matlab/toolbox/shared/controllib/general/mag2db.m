function ydb = mag2db(y) %#codegen
%MAG2DB  Magnitude to dB conversion.
%
%   YDB = MAG2DB(Y) converts magnitude data Y into dB values.
%   Negative values of Y are mapped to NaN.
%
%   See also DB2MAG.

%   Copyright 1986-2021 The MathWorks, Inc.
if isempty(coder.target)
   y(y<0) = NaN;
   ydb = 20*log10(y);
else
   ydb = coder.internal.sxfun(mfilename,@mag2dbScalar,y);
end

function ydb = mag2dbScalar(y)
% mag2db for scalar y.
if y<0
   ydb = nan('like',y);
else
   ydb = 20*log10(y);
end