function B = sorti(A,varargin)
% Sort text case-insensitive.

%   Copyright 2020 The MathWorks, Inc.

assert(isvector(A));

% Sort the lower-cased text, and then within blocks of equal rows, sort
% case-sensitively. This puts both A and a before both B and b, but puts A
% before a.
B = A(:);
[~,ind] = sortrows([upper(B) B], varargin{:});
B = reshape(B(ind),size(A));
