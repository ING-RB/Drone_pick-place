function NAN = interpNaN(x)
%MATLAB Code Generation Private Function
%   Returns coder.internal.nan('like',x), except that if x is complex, the
%   imaginary part is also nan.

%   Copyright 2020-2022 The MathWorks, Inc.

%#codegen

coder.inline('always');
RNAN = cast(coder.internal.nan,'like',real(x));
if isreal(x)
    NAN = RNAN;
else
    NAN = complex(RNAN,RNAN);
end
