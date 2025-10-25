function bdata = datetimeDiff(adata,varargin)
%DATETIMEDIFF Difference and approximate derivative for datetime doubledouble data.

%   Copyright 2014-2020 The MathWorks, Inc.

if nargin < 2
    diff_adata = diff(adata);
else
    diff_adata = diff(adata,varargin{:});
end
bdata = real(matlab.internal.datetime.datetimeAdd(real(diff_adata),imag(diff_adata)));
