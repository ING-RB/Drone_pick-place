function y = c2rVector(z)
% Produce the interleaved real form for a complex vector z. The input z may
% be a row vector, but the output y is always a column vector.

%    Copyright 2024 MathWorks, Inc.

y = typecast(complex(z(:)),'like',real(z));
