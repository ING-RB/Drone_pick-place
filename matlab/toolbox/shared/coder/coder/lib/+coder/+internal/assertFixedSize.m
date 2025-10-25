function assertFixedSize(idx,varargin)
%MATLAB Code Generation Private Function

%    coder.internal.assertFixedSize(IDX,A,B,C, ...) will issue an error at
%    code generation time if any input A, B, C, ... indexed by IDX is not
%    fixed-size.

% Copyright 2008-2019 The MathWorks, Inc.
%#codegen

if ~coder.target('MATLAB')
    coder.internal.prefer_const(idx);
    coder.unroll;
    for k = 1:numel(idx)
        coder.internal.assert( ...
            coder.internal.isConst(size(varargin{idx(k)})), ...
            'Coder:toolbox:NoVarSizeInputs',int32(idx(k)));
    end
end