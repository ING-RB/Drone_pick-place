function nout = end(this,k,n)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen
coder.inline('always');
switch k
  case 1
    if n == 1
        nout = numel(this);
    else
        nout = double(this.m);
    end
  case 2
    nout = double(this.n);
  otherwise
    nout = double(ONE);
end

%--------------------------------------------------------------------------
