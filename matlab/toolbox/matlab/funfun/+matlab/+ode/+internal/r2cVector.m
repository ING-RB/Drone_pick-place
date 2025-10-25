function y = r2cVector(y)
% Produce the complex vector from real interleaved form.
% Assumes y is real column vector and numel(y) is even. Same as r2cArray
% but with no reshape.

%    Copyright 2024 MathWorks, Inc.

y = typecast(y,'like',complex(y));
