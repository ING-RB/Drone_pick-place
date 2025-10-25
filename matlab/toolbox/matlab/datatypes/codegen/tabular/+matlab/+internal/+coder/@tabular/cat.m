function t = cat(dim,varargin)  %#codegen
%CAT Concatenate tables.
%   T = CAT(DIM, T1, T2, ...) concatenates the tables T1, T2, ... along
%   dimension DIM by calling the TABLE/HORZCAT or TABLE/VERTCAT method.
%   DIM must be 1 or 2.
%
%   See also HORZCAT, VERTCAT.

%   Copyright 2019 The MathWorks, Inc.
coder.internal.prefer_const(dim);
coder.internal.assert(coder.internal.isConst(dim), 'MATLAB:table:cat:NonconstDim');
coder.internal.assert(isequal(dim,1) || isequal(dim,2), 'MATLAB:table:cat:InvalidDim');
if dim == 1
    t = vertcat(varargin{:});
elseif dim == 2
    t = horzcat(varargin{:});
end
