function s = genericLike(eg,varargin)
%MATLAB Code Generation Private Method

%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen
coder.internal.prefer_const(eg,varargin);
nargs = numel(varargin);
coder.internal.assert(nargs <= 2, ...
                      'MATLAB:zeros:unsupportedNdSparse');
switch nargs
  case 0
    s = coder.internal.sparse(1,1,eg);
    return
  case 1
    if coder.internal.isConst(isscalar(varargin{1})) && isscalar(varargin{1})
        sm = coder.internal.checkAndSaturateExpandSize(varargin{:});
        sn = sm;
    else
        sz = full(varargin{1});
        coder.internal.assert(isrow(sz), ...
                              'MATLAB:matrix:nonRealInput');
        coder.internal.assert(numel(sz) == 2, ...
                              'MATLAB:zeros:unsupportedNdSparse');
        sm = coder.internal.checkAndSaturateExpandSize(sz(1));
        sn = coder.internal.checkAndSaturateExpandSize(sz(2));
    end
  otherwise
    sm = coder.internal.checkAndSaturateExpandSize(varargin{1});
    sn = coder.internal.checkAndSaturateExpandSize(varargin{2});
end
s = coder.internal.sparse();
ns = sm*sn;
s.m = sm;
s.n = sn;
s.colidx = ones(coder.internal.ignoreRange(sn+1),ONE,'like',ONE);
numalloc = max2(ns,ONE);
if eg ~= zeros('like',eg)
    % Fill in the values
    s.d = eml_expand(eg,[coder.internal.ignoreRange(numalloc),ONE]);
    s.colidx(1) = ONE;
    s.rowidx = ones(coder.internal.ignoreRange(numalloc),ONE,'like',ONE);
    for c = 1:sn
        ridx = s.colidx(c);
        rstop = ridx+sm;
        s.colidx(c+1) = rstop;
        row = ONE;
        while (ridx < rstop)
            s.rowidx(ridx) = row;
            row = row+1;
            ridx = ridx+1;
        end
    end
else
    s.d = eml_expand(eg,[coder.internal.ignoreRange(ONE),ONE]);
    s.rowidx = ones(coder.internal.ignoreRange(ONE),ONE,'like',ONE);
    numalloc = ONE;
end
s.maxnz = numalloc;
s.matlabCodegenUserReadableName = makeUserReadableName(s);

%--------------------------------------------------------------------------
