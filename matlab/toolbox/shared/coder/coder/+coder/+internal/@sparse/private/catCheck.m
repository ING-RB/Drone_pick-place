function [ceg, cnnz, cnrows, cncols] = catCheck(dim,strictEmpty,varargin)
%MATLAB Code Generation Private Function

% Helper function used in cat, horzcat, vertcat for sparse. Do error checks and
% return size information for the output as well as a full output example
% scalar, ceg.
% 
% When strictEmpty is true, enforce that the only empty exempt from size checks
% is a 0-by-0 empty. Otherwise, all empties are exempt in the style of horzcat
% and vertcat.

%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen
narginchk(3,Inf);
coder.internal.prefer_const(dim,strictEmpty);
coder.internal.assert(dim == 1 || dim == 2, 'Coder:builtins:Explicit', 'Internal error: Dim must be 1 or 2');

if dim == 1
    fixedDim = coder.internal.indexInt(2);
    overflowType = 'rows';
else
    fixedDim = coder.internal.indexInt(1);
    overflowType = 'columns';
end
cnfixeddim = intSize(varargin{1},fixedDim);
foundSize = false;
nargs = coder.internal.indexInt(numel(varargin));
egargs = cell(1,nargs);
allEmpty = true;
coder.unroll();
for k = 1:nargs
    coder.internal.assert(ismatrix(varargin{k}), ...
                          'Coder:toolbox:SparseConcatenation2D');
    if strictEmpty
        isAcceptableEmpty = isequal(coder.internal.indexInt(size(varargin{k})),[ZERO,ZERO]);
        allEmpty = allEmpty & isempty(varargin{k});
    else
        isAcceptableEmpty = isempty(varargin{k});
        allEmpty = allEmpty & isAcceptableEmpty;
    end
    nrowsk = intSize(varargin{k},fixedDim);
    coder.internal.assert(k == 1 || isAcceptableEmpty || ~foundSize || nrowsk == cnfixeddim, ...
                          'Coder:toolbox:ConcatenationDimensionMismatch',fixedDim,k,cnfixeddim);
    if ~isAcceptableEmpty && ~foundSize
        foundSize = true;
        cnfixeddim = nrowsk;
    end
    if issparse(varargin{k})
        egargs{k} = coder.internal.scalarEg(varargin{k}.d);
    else
        egargs{k} = coder.internal.scalarEg(varargin{k});
    end
end
% Use horzcat or vertcat to get the overall type rather than
% coder.internal.scalarEg since the rules are different
if dim == 1
    ceg = vertcat(egargs{:});
else
    ceg = horzcat(egargs{:});
end

coder.internal.assert(isa(ceg,'double') || isa(ceg,'single') || islogical(ceg), ...
                      'Coder:toolbox:SparseConcatenationUnsupportedType', class(ceg));

% Compute output size and nnz
cnnz = ZERO;
cnvardim = ZERO;
coder.unroll();
for k = 1:nargs
    if allEmpty || ~isempty(varargin{k})
        cnnz = addOrAssert(cnnz , coder.internal.indexInt(nnz(varargin{k})), 'nonzeros');
        cnvardim = addOrAssert(cnvardim , intSize(varargin{k},dim), overflowType);
    end
end

if dim == 1
    cnrows = cnvardim;
    cncols = cnfixeddim;
else
    cnrows = cnfixeddim;
    cncols = cnvardim;
end

%--------------------------------------------------------------------------

function n = intSize(x,varargin)
coder.inline('always');
coder.internal.prefer_const(varargin);
n = coder.internal.indexInt(size(x,varargin{:}));

%--------------------------------------------------------------------------

function a = addOrAssert(a,b,type)
    MAX = intmax(coder.internal.indexIntClass);
    coder.internal.errorIf(a > (MAX - b), 'Coder:toolbox:SparseCatTooBig', type);
    a=a+b;
