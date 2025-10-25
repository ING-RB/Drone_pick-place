function A = r2cArray(A)
% Produce the complex array from real interleaved form. Assumes A is real
% and size(A,1) is even. Each column of A is assumed to represent a complex
% vector in real form. Use r2cVector for the same operation but without
% reshapes.

%    Copyright 2024 MathWorks, Inc.

sz = size(A);
sz(1) = sz(1)/2;
A = reshape(typecast(A(:),'like',complex(A)),sz);
