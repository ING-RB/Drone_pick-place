function c = spcat(dim,ceg,cnnz,cnrows,cncols,varargin)
%MATLAB Code Generation Private Method

% Implementation of concatenation for sparse matrices. Supports a mix of sparse
% and full matrices. The dim argument must be either 1 or 2 since we only
% support sparse matrices.
%
% Other input values can be retrieved from a call to catCheck. The trailing
% varargin should be the matrices to be concatenated.

%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen
coder.internal.prefer_const(dim,ceg,cnnz,cnrows,cncols);
coder.internal.assert(dim == 1 || dim == 2, 'Coder:builtins:Explicit', 'Internal error: Dim must be 1 or 2');
if dim == 1
    % vertcat
    c = dovertcat(ceg,cnnz,cnrows,cncols,varargin{:});
else
    % horzcat
    c = dohorzcat(ceg,cnnz,cnrows,cncols,varargin{:});
end

%--------------------------------------------------------------------------

function c = dohorzcat(ceg,cnnz,cnrows,cncols,varargin)
coder.internal.prefer_const(ceg,cnnz,cnrows,cncols);
c = coder.internal.sparse.spallocLike(cnrows,cncols,cnnz,ceg);
nzCount = ZERO;
ccolidx = ONE;
nargs = coder.internal.indexInt(numel(varargin));
coder.unroll();
for k = 1:nargs
    if isempty(varargin{k})
        continue
    end
    if issparse(varargin{k})
        cidx = nzCount;
        nnzk = nnzInt(varargin{k});
        for idx = ONE:nnzk
            cidx = cidx+1;
            c.rowidx(cidx) = varargin{k}.rowidx(idx);
            c.d(cidx) = varargin{k}.d(idx);
        end
        for col = ONE:varargin{k}.n
            ccolidx = ccolidx+1;
            c.colidx(ccolidx) = varargin{k}.colidx(col+1) + nzCount;
        end
        nzCount = nzCount+nnzInt(varargin{k});
    else
        % TODO: Row major
        nrowk = intSize(varargin{k},1);
        ncolk = intSize(varargin{k},2);
        cidx = nzCount+1;
        for col = 1:ncolk
            for row = 1:nrowk
                dk = varargin{k}(row,col);
                if dk ~= zeros('like',dk)
                    c.rowidx(cidx) = row;
                    c.d(cidx) = dk;
                    cidx = cidx+1;
                end
            end
            ccolidx = ccolidx+1;
            c.colidx(ccolidx) = cidx;
        end
        nzCount = cidx-1;
    end
end

%--------------------------------------------------------------------------

function c = dovertcat(ceg,cnnz,cnrows,cncols,varargin)
coder.internal.prefer_const(ceg,cnnz,cnrows,cncols);
c = coder.internal.sparse.spallocLike(cnrows,cncols,cnnz,ceg);
nzCount = ZERO;
nargs = coder.internal.indexInt(numel(varargin));
emptyflag = false(1,nargs);
coder.unroll();
for k = 1:nargs
    emptyflag(k) = isempty(varargin{k});
end
for ccol = 1:c.n
    crowoffs = ZERO;
    coder.unroll();
    for k = 1:nargs
        if emptyflag(k)
            continue
        end
        if issparse(varargin{k})
            cidx = nzCount;
            kpstart = varargin{k}.colidx(ccol);
            kpend = varargin{k}.colidx(ccol+1)-1;
            for kp = kpstart:kpend
                cidx = cidx+1;
                r = varargin{k}.rowidx(kp);
                c.rowidx(cidx) = r+crowoffs;
                c.d(cidx) = varargin{k}.d(kp);
            end
            nzCount = nzCount+(kpend-kpstart+1);
            crowoffs = crowoffs + varargin{k}.m;
        else
            % TODO: Row major
            nrowk = intSize(varargin{k},1);
            cidx = nzCount;
            for row = 1:nrowk
                dk = varargin{k}(row,ccol);
                if dk ~= zeros('like',dk)
                    cidx = cidx+1;
                    c.rowidx(cidx) = row+crowoffs;
                    c.d(cidx) = dk;
                end
            end
            nzCount = cidx;
            crowoffs = crowoffs + nrowk;
        end
    end
    c.colidx(ccol+1) = nzCount+1;
end

%--------------------------------------------------------------------------

function n = intSize(x,varargin)
coder.inline('always');
coder.internal.prefer_const(varargin);
n = coder.internal.indexInt(size(x,varargin{:}));

%--------------------------------------------------------------------------
