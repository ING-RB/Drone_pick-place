classdef (InferiorClasses = {...
        ?coder.internal.anonymous_function... spfun
        ?coder.internal.nested_function... spfun
        ?coder.internal.string... isa, plus, etc.
        }) sparse...
       < matlab.mixin.internal.indexing.Paren...
       & coder.internal.Builtin ...
       & coder.mixin.internal.indexing.ParenAssign % ...
       % & coder.internal.UseColonObjInParenMethods ...
   
    %MATLAB Code Generation Private Class

    %   Copyright 2016-2024 The MathWorks, Inc.
    %#codegen
    properties
        d      % data - zeros squeezed out on entry and exit
        colidx % offsets into d and rowidx
        rowidx % row indices - sorted per column
        m      % number of rows
        n      % number of columns
        maxnz  % allocated size of d and rowidx
    end
    methods
        function this = sparse(ridx,cidx,y,m,n,nzmaxval)
            coder.internal.allowHalfInputs; 
            if ~coder.target('MATLAB')
                coder.internal.assert(coder.areUnboundedVariableSizedArraysSupported, ...
                    'Coder:toolbox:SparseNeedsMalloc', 'IfNotConst', 'Fail');                
            end
            % Internal default constructor to allow mutated copies
            if nargin == 0
                return
            end
            narginchk(1,6);
            if nargin == 1
                % sparse(x)
                x = ridx;
                if issparse(x)
                    coder.inline('always')
                    this = x;
                else
                    coder.internal.errorIf(ischar(x), ...
                                           'MATLAB:sparse:charConversion');
                    coder.internal.assert(isAllowedSparseClass(x), ...
                                          'Coder:toolbox:unsupportedClass','sparse',class(x));
                    coder.internal.assert(ismatrix(x), 'Coder:toolbox:InvalidSparseDimensions');
                    mInt = coder.internal.indexInt(size(x,1));
                    nInt = coder.internal.indexInt(size(x,2));
                    assertValidSize(mInt);
                    assertValidSize(nInt);
                    nnzInt = coder.internal.indexInt(nnz(x));
                    this.m = mInt;
                    this.n = nInt;
                    numalloc = max2(nnzInt,ONE);
                    if overAllocateNZMAX()
                        numalloc = numalloc + 10;
                    end
                    this.maxnz = numalloc;
                    this.d = zeros(coder.internal.ignoreRange(numalloc),1,'like',x);
                    this.colidx = zeros(coder.internal.ignoreRange(this.n+1),1,'like',ONE);
                    this.colidx(1) = ONE;
                    this.rowidx = zeros(coder.internal.ignoreRange(numalloc),1,'like',ONE);
                    this.rowidx(1) = ONE;
                    ctr = ONE;
                    for col = 1:nInt
                        for row = 1:mInt
                            xrc = x(row,col);
                            if xrc ~= 0
                                this.rowidx(ctr) = row;
                                this.d(ctr) = xrc;
                                ctr = ctr+1;
                            end
                        end
                        this.colidx(col+1) = ctr;
                    end
                end
                this.matlabCodegenUserReadableName = makeUserReadableName(this);
                coder.internal.sparse.sanityCheck(this);
                return
            end
            if nargin == 2 || (nargin == 3 && coder.internal.isCharOrScalarString(y))
                % sparse(m,n) and sparse(m,n,typename)
                coder.internal.prefer_const(ridx,cidx);
                if nargin == 2
                    y = "double";
                end
                coder.mustBeConst(y, 'Coder:toolbox:OptionStringsMustBeConstant');
                coder.internal.assert(coder.internal.sparse.isAllowedSparseClass(y,false), ...
                    'MATLAB:sparse:invalidTypename');
                assertValidSize(ridx);
                assertValidSize(cidx);

                this.m = coder.internal.indexInt(full(ridx));
                this.n = coder.internal.indexInt(full(cidx));
                this.d = zeros(coder.internal.ignoreRange(ONE),1,y);
                this.colidx = ones(coder.internal.ignoreRange(this.n+1),1,'like',ONE);
                this.rowidx = ones(coder.internal.ignoreRange(ONE),ONE,'like',this.colidx);
                this.maxnz = ONE;
                this.matlabCodegenUserReadableName = makeUserReadableName(this);
                coder.internal.sparse.sanityCheck(this);
                return
            end
            coder.internal.assert(ismatrix(cidx) && ismatrix(ridx) && ismatrix(y), ...
                                  'Coder:toolbox:SparseConstructor2D');
            nc = coder.internal.indexInt(numel(cidx));
            scalarc = coder.internal.isConst(isscalar(cidx)) && isscalar(cidx);
            nr = coder.internal.indexInt(numel(ridx));
            scalarr = coder.internal.isConst(isscalar(ridx)) && isscalar(ridx);
            ny = coder.internal.indexInt(numel(y));
            scalary = coder.internal.isConst(isscalar(y)) && isscalar(y);
            if ~scalarc
                numnz = nc;
            elseif ~scalarr
                numnz = nr;
            else
                numnz = ny;
            end
            coder.internal.assert((scalarc || nc == numnz) && ...
                                  (scalarr || nr == numnz) && ...
                                  (scalary || ny == numnz), ...
                                  'MATLAB:samelen');
            % Data vector must be scalar or same size as one of cidx, ridx
            coder.internal.assert(scalary || ny == nc || ny == nr, ...
                                  'MATLAB:samelen');

            ridxInt = assertValidIndexArg(ridx);
            cidxInt = assertValidIndexArg(cidx);
            coder.internal.errorIf(ischar(y), ...
                                   'MATLAB:sparse:charConstructor');
            coder.internal.assert(isAllowedSparseClass(y), ...
                                  'Coder:toolbox:unsupportedClass','sparse',class(y));
            sortedIndices = coder.nullcopy(zeros(numnz,ONE,'like',ONE));
            for k = 1:numnz
                sortedIndices(k) = k;
            end
            sorty = true;
            if scalarc && scalarr
                % Nothing to do and we don't need to sort y
                sorty = false;
            elseif scalarc && ~scalarr
                [sortedIndices,ridxInt] = locSortidx(sortedIndices,ridxInt);
            elseif ~scalarc && scalarr
                [sortedIndices,cidxInt] = locSortidx(sortedIndices,cidxInt);
            else
                [sortedIndices,cidxInt,ridxInt] = locSortrows(sortedIndices,cidxInt,ridxInt);
            end
            if nargin > 3
                narginchk(5,Inf)
                assertValidSize(m);
                assertValidSize(n);
                this.m = coder.internal.indexInt(full(m));
                this.n = coder.internal.indexInt(full(n));
                if ~isempty(ridxInt)
                    maxr = max(ridxInt);
                    coder.internal.assert(maxr <= this.m, ...
                                          'Coder:builtins:IndexOutOfBounds',maxr,ONE,this.m);
                end
                if ~isempty(cidxInt)
                    maxc = cidxInt(end);
                    coder.internal.assert(maxc <= this.n, ...
                                          'Coder:builtins:IndexOutOfBounds',maxc,ONE,this.n);
                end
            else
                if isempty(ridxInt) || isempty(cidxInt)
                    thism = ZERO;
                    thisn = ZERO;
                else
                    if coder.internal.isConst(ridx)
                        thism = coder.const(coder.internal.indexInt(max(ridx(:))));
                    else
                        thism = max(ridxInt);
                    end
                    if coder.internal.isConst(cidx)
                        thisn = coder.const(coder.internal.indexInt(max(cidx(:))));
                    else
                        thisn = cidxInt(end);
                    end
                end
                this.m = thism;
                this.n = thisn;
            end
            if nargin > 5
                assertValidSize(nzmaxval);
                nzmaxvalFull = full(nzmaxval);
                coder.internal.assert(cast(ny,'like',nzmaxvalFull) <= nzmaxvalFull, ...
                                      'Coder:toolbox:SparseNzmaxTooSmall');
                coder.internal.assert(nzmaxvalFull >= nr && nzmaxvalFull >= nc && nzmaxvalFull >= ny, ...
                                      'Coder:toolbox:SparseNzmaxTooSmall');
                nzint = coder.internal.indexInt(nzmaxvalFull);
            else
                nzint = numnz;
            end
            numalloc = max2(nzint,ONE);
            if overAllocateNZMAX()
                numalloc = numalloc + 10;
            end
            yf = full(y);
            this.d = zeros(coder.internal.ignoreRange(numalloc),ONE,'like',yf);
            this.maxnz = numalloc;
            this.colidx = zeros(coder.internal.ignoreRange(this.n+1),1,'like',ONE);
            this.colidx(1) = ONE;
            this.rowidx = zeros(coder.internal.ignoreRange(numalloc),1,'like',ONE);
            cptr = ONE;
            for c = ONE:this.n
                while (cptr <= numnz && coder.internal.scalexpSubsref(cidxInt,cptr) == c)
                    this.rowidx(cptr) = coder.internal.scalexpSubsref(ridxInt,cptr);
                    cptr = cptr + 1;
                end
                this.colidx(c+1) = cptr;
            end
            if scalary
                for k = 1:numnz
                    this.d(k) = yf;
                end
            elseif sorty
                for k = 1:numnz
                    this.d(k) = yf(sortedIndices(k));
                end
            else
                for k = 1:numnz
                    this.d(k) = yf(k);
                end
            end
            % Use function form here since we've disabled dotParenReference
            skipDuplCheck = false;
            this = fillIn(this,skipDuplCheck);
            this.matlabCodegenUserReadableName = makeUserReadableName(this);
            coder.internal.sparse.sanityCheck(this);
        end
        disp(this);
        varargout = size(this, varargin);
        y = length(this);
        nout = end(this,k,n);
        s = parenReference1D(this,linidx);
        s = parenReference2D(this,r,c);
        c = mtimes(a,b)
        c = horzcat(varargin);
        c = vertcat(varargin);
        c = cat(varargin);
        y = allOrAny(op,x,dim);
        function y = numel(this)
            coder.inline('always');
            [~,overflow] = coder.internal.bigProduct(this.m,this.n,true);
            coder.internal.errorIf(overflow~=0, 'Coder:toolbox:SparseNumelTooBig');
            y = double(this.m*this.n);
        end
        function s = parenReference(this, varargin)
            coder.internal.assert(nargin > 1, 'MATLAB:SparseSubLimitTwoDims');
            coder.internal.assert(nargin < 4, 'MATLAB:ndFullOnly');
            for k = coder.unroll(1:numel(varargin))
                coder.internal.assert(~islogical(varargin{k}), ...
                                      'Coder:toolbox:SparseLogicalIndexingNotSupported');
            end
            if nargin == 2
                s = parenReference1D(this, varargin{:});
            else
                s = parenReference2D(this, varargin{:});
            end
            coder.internal.sparse.sanityCheck(s);
        end
        function this = parenAssign(this, rhs, varargin)
            coder.internal.errorIf(islogical(this) && ~isreal(rhs), 'MATLAB:nologicalcomplex');
            coder.internal.assert(nargin < 5, 'MATLAB:ndFullOnly');
            for k = coder.unroll(1:numel(varargin))
                coder.internal.assert(~islogical(varargin{k}), ...
                                      'Coder:toolbox:SparseLogicalIndexingNotSupported');
            end
            if nargin == 3
                this = parenAssign1D(this, rhs, varargin{:});
            else
                this = parenAssign2D(this, rhs, varargin{:});
            end
            coder.internal.sparse.sanityCheck(this);
        end
        this = parenAssign1D(this,rhs,linidx);
        this = parenAssign2D(this,rhs,r,c);

        function y = full(this)
            y = zeros(size(this),'like',this.d);
            for c = 1:this.n
                cend = this.colidx(c+1)-1;
                for idx = this.colidx(c):cend
                    y(this.rowidx(idx), c) = this.d(idx);
                end
            end
        end
        function s = rem(a,b)
           coder.internal.implicitExpansionBuiltin;
           s = binOp(a,b,'rem', @firstSparse) ;
           coder.internal.sparse.sanityCheck(s);
        end
        function s = mod(a,b)
            coder.internal.implicitExpansionBuiltin;
           s = binOp(a,b,'mod', @firstSparse) ;
           coder.internal.sparse.sanityCheck(s);
        end
        function s = plus(a,b)
            coder.internal.implicitExpansionBuiltin;
            s = binOp(a,b,'plus',@bothSparse);
            coder.internal.sparse.sanityCheck(s);
        end
        function s = minus(a,b)
            coder.internal.implicitExpansionBuiltin;
            s = binOp(a,b,'minus',@bothSparse);
            coder.internal.sparse.sanityCheck(s);
        end
        function s = times(a,b)
            coder.internal.implicitExpansionBuiltin;
            s = binOp(a,b,'times');
            coder.internal.sparse.sanityCheck(s);
        end
        function s = rdivide(a,b)
            coder.internal.implicitExpansionBuiltin;
            s = binOp(a,b,'rdivide',@sparseAOrFullB);
            coder.internal.sparse.sanityCheck(s);
        end
        function s = ldivide(a,b)
            coder.internal.implicitExpansionBuiltin;
            s = binOp(b,a,'rdivide',@sparseAOrFullB);
            coder.internal.sparse.sanityCheck(s);
        end
        function s = lt(a,b)
            coder.internal.implicitExpansionBuiltin;
            s = binOp(a,b,'lt');
            coder.internal.sparse.sanityCheck(s);
        end
        function s = gt(a,b)
            coder.internal.implicitExpansionBuiltin;
            s = binOp(a,b,'gt');
            coder.internal.sparse.sanityCheck(s);
        end
        function s = ne(a,b)
            coder.internal.implicitExpansionBuiltin;
            s = binOp(a,b,'ne');
            coder.internal.sparse.sanityCheck(s);
        end
        function s = le(a,b)
            coder.internal.implicitExpansionBuiltin;
            s = binOp(a,b,'le');
            coder.internal.sparse.sanityCheck(s);
        end
        function s = ge(a,b)
            coder.internal.implicitExpansionBuiltin;
            s = binOp(a,b,'ge');
            coder.internal.sparse.sanityCheck(s);
        end
        function s = eq(a,b)
            coder.internal.implicitExpansionBuiltin;
            s = binOp(a,b,'eq');
            coder.internal.sparse.sanityCheck(s);
        end
        function s = or(a,b)
            coder.internal.implicitExpansionBuiltin;
            coder.internal.assert(isreal(a) && isreal(b), ...
                                  'MATLAB:andOrXor:operandsNotReal');
            s = binOp(a,b,'or',@bothSparse);
            coder.internal.sparse.sanityCheck(s);
        end
        function s = and(a,b)
            coder.internal.implicitExpansionBuiltin;
            coder.internal.assert(isreal(a) && isreal(b), ...
                                  'MATLAB:andOrXor:operandsNotReal');
            s = binOp(a,b,'and');
            coder.internal.sparse.sanityCheck(s);
        end
        function s = abs(a)
            s = spfunImpl(@abs, a);
            coder.internal.sparse.sanityCheck(s);
        end
        function s = isinf(a)
            s = spfunImpl(@isinf, a);
            coder.internal.sparse.sanityCheck(s);
        end
        function s = isnan(a)
            s = spfunImpl(@isnan, a);
            coder.internal.sparse.sanityCheck(s);
        end

        function y = isfinite(this)
            y = true(size(this));
            for c = 1:this.n
                cend = this.colidx(c+1)-1;
                for idx = this.colidx(c):cend
                    y(this.rowidx(idx), c) = isfinite(this.d(idx));
                end
            end
        end
        y = not(this);
        function y = spones(this)
            singleSparseIn = matlab.internal.feature('SingleSparse') && isa(this.d, 'single');
            if singleSparseIn
                y = coder.internal.sparse.spalloc(this.m, this.n, this.nzmax, 'single');
            else
                y = coder.internal.sparse.spalloc(this.m, this.n, this.nzmax, 'double');
            end
            y.rowidx = this.rowidx;
            y.colidx = this.colidx;
            if singleSparseIn
                y.d = ones(nnzInt(this),1,'single');
            else
                y.d = ones(nnzInt(this),1,'double');
            end
            y.matlabCodegenUserReadableName = makeUserReadableName(y);
            coder.internal.sparse.sanityCheck(this);
        end
        function y = transpose(this)
            y = locTranspose(this,false);
            coder.internal.sparse.sanityCheck(this);
        end
        function b = permute(a, order)
            coder.internal.prefer_const(order);
            coder.internal.sparse.validatePermuteOrder(order);
            % Consider only the first two dimensions as
            % all other dimensions are singleton for sparse.
            ONE = coder.internal.indexInt(1);
            TWO = coder.internal.indexInt(2);
            if order(ONE) == TWO && order(TWO) == ONE
                % Permute results in a transpose as the first two
                % dims are switched, b = transpose(a).
                ml = a.n;
                nl = a.m;
            else
                % Only 2D sparse matrices are supported.
                coder.internal.assert(order(ONE) == ONE && order(TWO) == TWO, ...
                    'MATLAB:permute:sparseNDmatrix');
                % No-op, b = a.
                ml = a.m;
                nl = a.n;
            end
            b = coder.internal.sparse([],[],zeros(0,'like',a.d),ml,nl,nnzInt(a)); 
            if order(ONE) == TWO && order(TWO) == ONE
                b = locTranspose(a,false,b);
            else
                b.d = a.d;
                b.colidx = a.colidx;
                b.rowidx = a.rowidx;
            end
        end
        function a = ipermute(b, order)
            coder.internal.prefer_const(order);
            coder.internal.sparse.validatePermuteOrder(order);
            inverseorder = coder.nullcopy(order); 
            coder.unroll(coder.internal.isConst(order)); % If possible, const-fold the order.
            for k = 1:numel(order)
                inverseorder(order(k)) = k;
            end
            a = permute(b,inverseorder);
        end
        function y = ctranspose(this)
            y = locTranspose(this,true);
            coder.internal.sparse.sanityCheck(this);
        end
        function y = pagetranspose(this)
            y = transpose(this);
        end
        function y = pagectranspose(this)
            y = ctranspose(this); 
        end
        function n = nnz(this)
            coder.inline('always');
            n = double(nnzInt(this));
        end
        function n = nzmax(this)
            n = double(this.maxnz);
        end
        function y = nonzeros(this)
            nz = nnzInt(this);
            y = this.d((1:nz),1);
        end
        function p = isa(this,varargin)
            p = isa(this.d,varargin{:});
        end
        function p = isobject(~)
            p = false;
        end
        function p = isfloat(this)
            p = isfloat(this.d);
        end
        function p = islogical(this)
            p = islogical(this.d);
        end
        function p = isnumeric(this)
            p = isfloat(this.d);
        end
        function p = isreal(this)
            p = isreal(this.d);
        end
        function p = issparse(~)
            p = true;
        end
        function p = isvector(this)
            p = this.m == ONE || this.n == ONE;
        end
        function c = class(this)
            c = class(this.d);
        end
        function p = isempty(this)
            p = this.m == 0 || this.n == 0;
        end
        function y = imag(this)
            y = spfunImpl(@imag,this);
        end
        function y = real(this)
            y = spfunImpl(@real,this);
        end
        function p = isscalar(this)
            p = this.m == ONE && this.n == ONE;
        end
        function t = spfunImpl(fun,s)
           coder.internal.assert(isa(fun,'function_handle'), ...
                      'Coder:toolbox:unsupportedClass', ...
                      mfilename, class(fun));
           nzs = coder.internal.ignoreRange(nnzInt(s));
           tmpd = fun(s.d(1:nzs,1));
           coder.internal.assert((coder.internal.isConst(isscalar(tmpd)) && isscalar(tmpd)) || ...
               coder.internal.indexInt(numel(tmpd)) == nnzInt(s), 'MATLAB:samelen');
           t = coder.internal.sparse.spallocLike(s.m,s.n,nzs,tmpd);
           t.rowidx(1:nzs) = s.rowidx(1:nzs);
           t.colidx = s.colidx;
           for k = 1:nzs
               t.d(k) = coder.internal.scalexpSubsref(tmpd,k);
           end
           t = fillIn(t);
           coder.internal.sparse.sanityCheck(t);
        end
        function y = logical(this)
            if islogical(this)
                coder.inline('always'); %#ok<UNRCH>
                y = this;
                return
            end
            coder.internal.assert(isreal(this), 'MATLAB:nologicalcomplex');
            nalloc = coder.internal.ignoreRange(max2(nnzInt(this),ONE));
            y = coder.internal.sparse.spallocLike(this.m, this.n, nalloc, true);
            y.rowidx = this.rowidx(1:nalloc,1);
            y.colidx = this.colidx;
            y.d = logical(this.d(1:nalloc,1));
            coder.internal.sparse.sanityCheck(y);
        end
        function y = double(this)
            if isa(this,'double')
                coder.inline('always');
                y = this;
                return
            end
            nalloc = max2(nnzInt(this),ONE);
            y = coder.internal.sparse.spallocLike(this.m, this.n, nalloc, double(this.d(1)));
            y.rowidx = this.rowidx(1:nalloc,1);
            y.colidx = this.colidx;
            y.d(1:nalloc) = double(this.d(1:nalloc,1));
            coder.internal.sparse.sanityCheck(y);
        end
        function y = single(this)
            coder.internal.assert(matlab.internal.feature("SingleSparse")==int32(1), ...
                'MATLAB:unimplementedSparseType');
            if isa(this,'single')
                coder.inline('always');
                y = this;
                return
            end
            nalloc = max2(nnzInt(this),ONE);
            y = coder.internal.sparse.spallocLike(this.m, this.n, nalloc, single(this.d(1)));
            y.rowidx = this.rowidx(1:nalloc,1);
            y.colidx = this.colidx;
            y.d(1:nalloc) = single(this.d(1:nalloc,1));
            coder.internal.sparse.sanityCheck(y);
        end
        function y = castLike(eg,toCast)
            %eg must be sparse for this function to be called
            coder.internal.userReadableName([]);
            castFcn = @(x)(cast(x, 'like', eg.d));
            if coder.internal.isBuiltInNumeric(toCast) || islogical(toCast) || ischar(toCast)
                if issparse(eg) == issparse(toCast) && ...
                        isreal(eg) == isreal(toCast) && ...
                        strcmp(class(eg),class(toCast))
                    % Nothing to do
                    y = toCast;
                else
                    y = spfun(castFcn, toCast); % Internally, spfun requires find to work.
                end
            else
                y = sparse(castFcn(toCast));
            end
            coder.internal.sparse.sanityCheck(y);
        end
        function y = zerosLike(this,varargin)
            coder.internal.prefer_const(varargin);
            y = coder.internal.sparse.genericLike(zeros('like',this.d),varargin{:});
            coder.internal.sparse.sanityCheck(y);
        end
        function y = onesLike(this,varargin)
            coder.internal.prefer_const(varargin);
            y = coder.internal.sparse.genericLike(ones('like',this.d),varargin{:});
            coder.internal.sparse.sanityCheck(y);
        end
        function y = nanLike(this,varargin)
            coder.internal.prefer_const(varargin);
            coder.internal.assert(isfloat(this.d), 'MATLAB:NaN:invalidInputClass');
            y = coder.internal.sparse.genericLike(nan('like',this.d),varargin{:});
            coder.internal.sparse.sanityCheck(y);
        end
        function y = infLike(this,varargin)
            coder.internal.prefer_const(varargin);
            coder.internal.assert(isfloat(this.d), 'MATLAB:Inf:invalidInputClass');
            y = coder.internal.sparse.genericLike(inf('like',this.d),varargin{:});
            coder.internal.sparse.sanityCheck(y);
        end
        function y = trueLike(this,varargin)
            coder.internal.prefer_const(varargin);
            coder.internal.assert(islogical(this.d), 'MATLAB:True:invalidInputClass');
            y = coder.internal.sparse.genericLike(true,varargin{:});
            coder.internal.sparse.sanityCheck(y);
        end
        function y = falseLike(this,varargin)
            coder.internal.prefer_const(varargin);
            coder.internal.assert(islogical(this.d), 'MATLAB:False:invalidInputClass');
            y = coder.internal.sparse.genericLike(false,varargin{:});
            coder.internal.sparse.sanityCheck(y);
        end
        function this = uminus(this)
            this.d = -this.d;
            coder.internal.sparse.sanityCheck(this);
        end
        function assert(c, varargin)
            narginchk(1,Inf);
            scalarc = coder.internal.isConst(isscalar(c)) && isscalar(c);
            coder.internal.assert(islogical(c) && scalarc, ...
                                  'MATLAB:assertion:LogicalScalar');
            if ~coder.target('MATLAB') && eml_ambiguous_types
                % We'll actually process this later
                return
            end
            if issparse(c)
                assert(full(c), varargin{:});
            else
                coder.internal.assert(c, 'Coder:toolbox:SparseAssertTrailing');
            end
        end

        %------- UNSUPPORTED BEGIN ----------------------------------------
        function [varargout] = conv(varargin)
            [varargout{1:nargout}] = functionNotSupported('conv');
        end
        function [varargout] = conv2(varargin)
            [varargout{1:nargout}] = functionNotSupported('conv2');
        end
        function [varargout] = convn(varargin)
            [varargout{1:nargout}] = functionNotSupported('convn');
        end
        function [varargout] = corrcoef(varargin)
            [varargout{1:nargout}] = functionNotSupported('corrcoef');
        end
        function [varargout] = cov(varargin)
            [varargout{1:nargout}] = functionNotSupported('cov');
        end
        function [varargout] = cummax(varargin)
            [varargout{1:nargout}] = functionNotSupported('cummax');
        end
        function [varargout] = cummin(varargin)
            [varargout{1:nargout}] = functionNotSupported('cummin');
        end
        function [varargout] = cumprod(varargin)
            [varargout{1:nargout}] = functionNotSupported('cumprod');
        end
        function [varargout] = cumsum(varargin)
            [varargout{1:nargout}] = functionNotSupported('cumsum');
        end
        function [varargout] = cumtrapz(varargin)
            [varargout{1:nargout}] = functionNotSupported('cumtrapz');
        end
        function [varargout] = deconv(varargin)
            [varargout{1:nargout}] = functionNotSupported('deconv');
        end
        function [varargout] = del2(varargin)
            [varargout{1:nargout}] = functionNotSupported('del2');
        end
        function [varargout] = detrend(varargin)
            [varargout{1:nargout}] = functionNotSupported('detrend');
        end
        function [varargout] = diff(varargin)
            [varargout{1:nargout}] = functionNotSupported('diff');
        end
        function [varargout] = fft(varargin)
            [varargout{1:nargout}] = functionNotSupported('fft');
        end
        function [varargout] = fft2(varargin)
            [varargout{1:nargout}] = functionNotSupported('fft2');
        end
        function [varargout] = fftn(varargin)
            [varargout{1:nargout}] = functionNotSupported('fftn');
        end
        function [varargout] = fftshift(varargin)
            [varargout{1:nargout}] = functionNotSupported('fftshift');
        end
        function [varargout] = fftw(varargin)
            [varargout{1:nargout}] = functionNotSupported('fftw');
        end
        function [varargout] = filloutliers(varargin)
            [varargout{1:nargout}] = functionNotSupported('filloutliers');
        end
        function [varargout] = filter(varargin)
            [varargout{1:nargout}] = functionNotSupported('filter');
        end
        function [varargout] = filter2(varargin)
            [varargout{1:nargout}] = functionNotSupported('filter2');
        end
        function [varargout] = gradient(varargin)
            [varargout{1:nargout}] = functionNotSupported('gradient');
        end
        function [varargout] = hist(varargin)
            [varargout{1:nargout}] = functionNotSupported('hist');
        end
        function [varargout] = histc(varargin)
            [varargout{1:nargout}] = functionNotSupported('histc');
        end
        function [varargout] = histcounts(varargin)
            [varargout{1:nargout}] = functionNotSupported('histcounts');
        end
        function [varargout] = ifft(varargin)
            [varargout{1:nargout}] = functionNotSupported('ifft');
        end
        function [varargout] = ifft2(varargin)
            [varargout{1:nargout}] = functionNotSupported('ifft2');
        end
        function [varargout] = ifftn(varargin)
            [varargout{1:nargout}] = functionNotSupported('ifftn');
        end
        function [varargout] = ifftshift(varargin)
            [varargout{1:nargout}] = functionNotSupported('ifftshift');
        end
        function [varargout] = isoutlier(varargin)
            [varargout{1:nargout}] = functionNotSupported('isoutlier');
        end
        function [varargout] = issorted(varargin)
            [varargout{1:nargout}] = functionNotSupported('issorted');
        end
        function [varargout] = issortedrows(varargin)
            [varargout{1:nargout}] = functionNotSupported('issortedrows');
        end
        function [varargout] = maxk(varargin)
            [varargout{1:nargout}] = functionNotSupported('maxk');
        end
        function [varargout] = mean(varargin)
            [varargout{1:nargout}] = functionNotSupported('mean');
        end
        function [varargout] = median(varargin)
            [varargout{1:nargout}] = functionNotSupported('median');
        end
        function [varargout] = mink(varargin)
            [varargout{1:nargout}] = functionNotSupported('mink');
        end
        function [varargout] = mode(varargin)
            [varargout{1:nargout}] = functionNotSupported('mode');
        end
        function [varargout] = movmad(varargin)
            [varargout{1:nargout}] = functionNotSupported('movmad');
        end
        function [varargout] = movmax(varargin)
            [varargout{1:nargout}] = functionNotSupported('movmax');
        end
        function [varargout] = movmean(varargin)
            [varargout{1:nargout}] = functionNotSupported('movmean');
        end
        function [varargout] = movmedian(varargin)
            [varargout{1:nargout}] = functionNotSupported('movmedian');
        end
        function [varargout] = movmin(varargin)
            [varargout{1:nargout}] = functionNotSupported('movmin');
        end
        function [varargout] = movprod(varargin)
            [varargout{1:nargout}] = functionNotSupported('movprod');
        end
        function [varargout] = movstd(varargin)
            [varargout{1:nargout}] = functionNotSupported('movstd');
        end
        function [varargout] = movsum(varargin)
            [varargout{1:nargout}] = functionNotSupported('movsum');
        end
        function [varargout] = movvar(varargin)
            [varargout{1:nargout}] = functionNotSupported('movvar');
        end
        function [varargout] = rescale(varargin)
            [varargout{1:nargout}] = functionNotSupported('rescale');
        end
        function [varargout] = sort(varargin)
            [varargout{1:nargout}] = functionNotSupported('sort');
        end
        function [varargout] = sortrows(varargin)
            [varargout{1:nargout}] = functionNotSupported('sortrows');
        end
        function [varargout] = std(varargin)
            [varargout{1:nargout}] = functionNotSupported('std');
        end
        function [varargout] = subspace(varargin)
            [varargout{1:nargout}] = functionNotSupported('subspace');
        end
        function [varargout] = trapz(varargin)
            [varargout{1:nargout}] = functionNotSupported('trapz');
        end
        function [varargout] = var(varargin)
            [varargout{1:nargout}] = functionNotSupported('var');
        end
        function [varargout] = enumeration(varargin)
            [varargout{1:nargout}] = functionNotSupported('enumeration');
        end
        function [varargout] = fieldnames(varargin)
            [varargout{1:nargout}] = functionNotSupported('fieldnames');
        end
        function [varargout] = isfield(varargin)
            [varargout{1:nargout}] = functionNotSupported('isfield');
        end
        function [varargout] = struct2cell(varargin)
            [varargout{1:nargout}] = functionNotSupported('struct2cell');
        end
        function [varargout] = structfun(varargin)
            [varargout{1:nargout}] = functionNotSupported('structfun');
        end
        function [varargout] = superiorfloat(varargin)
            [varargout{1:nargout}] = functionNotSupported('superiorfloat');
        end
        function [varargout] = swapbytes(varargin)
            [varargout{1:nargout}] = functionNotSupported('swapbytes');
        end
        function [varargout] = typecast(varargin)
            [varargout{1:nargout}] = functionNotSupported('typecast');
        end
        function [varargout] = angle(varargin)
            [varargout{1:nargout}] = functionNotSupported('angle');
        end
        function [varargout] = atan2(varargin)
            coder.internal.implicitExpansionBuiltin;
            [varargout{1:nargout}] = functionNotSupported('atan2');
        end
        function [varargout] = atan2d(varargin)
            [varargout{1:nargout}] = functionNotSupported('atan2d');
        end
        function [varargout] = cplxpair(varargin)
            [varargout{1:nargout}] = functionNotSupported('cplxpair');
        end
        function [varargout] = deg2rad(varargin)
            [varargout{1:nargout}] = functionNotSupported('deg2rad');
        end
        function [varargout] = hypot(varargin)
            coder.internal.implicitExpansionBuiltin;
            [varargout{1:nargout}] = functionNotSupported('hypot');
        end
        function [varargout] = log2(varargin)
            [varargout{1:nargout}] = functionNotSupported('log2');
        end
        function [varargout] = nthroot(varargin)
            [varargout{1:nargout}] = functionNotSupported('nthroot');
        end
        function [varargout] = pow2(varargin)
            [varargout{1:nargout}] = functionNotSupported('pow2');
        end
        function [varargout] = rad2deg(varargin)
            [varargout{1:nargout}] = functionNotSupported('rad2deg');
        end
        function [varargout] = realpow(varargin)
            [varargout{1:nargout}] = functionNotSupported('realpow');
        end
        function [varargout] = unwrap(varargin)
            [varargout{1:nargout}] = functionNotSupported('unwrap');
        end
        function [varargout] = blkdiag(varargin)
            [varargout{1:nargout}] = functionNotSupported('blkdiag');
        end
        function [varargout] = bsxfun(varargin)
            [varargout{1:nargout}] = functionNotSupported('bsxfun');
        end
        function [varargout] = circshift(varargin)
            [varargout{1:nargout}] = functionNotSupported('circshift');
        end
        function [varargout] = compan(varargin)
            [varargout{1:nargout}] = functionNotSupported('compan');
        end
        function [varargout] = eps(varargin)
            [varargout{1:nargout}] = functionNotSupported('eps');
        end
        function [varargout] = flintmax(varargin)
            [varargout{1:nargout}] = functionNotSupported('flintmax');
        end
        function [varargout] = flip(varargin)
            [varargout{1:nargout}] = functionNotSupported('flip');
        end
        function [varargout] = flipdim(varargin)
            [varargout{1:nargout}] = functionNotSupported('flipdim');
        end
        function [varargout] = freqspace(varargin)
            [varargout{1:nargout}] = functionNotSupported('freqspace');
        end
        function [varargout] = hadamard(varargin)
            [varargout{1:nargout}] = functionNotSupported('hadamard');
        end
        function [varargout] = hankel(varargin)
            [varargout{1:nargout}] = functionNotSupported('hankel');
        end
        function [varargout] = hilb(varargin)
            [varargout{1:nargout}] = functionNotSupported('hilb');
        end
        function [varargout] = ind2sub(varargin)
            [varargout{1:nargout}] = functionNotSupported('ind2sub');
        end
        function [varargout] = intmax(varargin)
            [varargout{1:nargout}] = functionNotSupported('intmax');
        end
        function [varargout] = intmin(varargin)
            [varargout{1:nargout}] = functionNotSupported('intmin');
        end
        function [varargout] = invhilb(varargin)
            [varargout{1:nargout}] = functionNotSupported('invhilb');
        end
        function [varargout] = linspace(varargin)
            [varargout{1:nargout}] = functionNotSupported('linspace');
        end
        function [varargout] = logspace(varargin)
            [varargout{1:nargout}] = functionNotSupported('logspace');
        end
        function [varargout] = magic(varargin)
            [varargout{1:nargout}] = functionNotSupported('magic');
        end
        function [varargout] = meshgrid(varargin)
            [varargout{1:nargout}] = functionNotSupported('meshgrid');
        end
        function [varargout] = ndgrid(varargin)
            [varargout{1:nargout}] = functionNotSupported('ndgrid');
        end
        function [varargout] = pascal(varargin)
            [varargout{1:nargout}] = functionNotSupported('pascal');
        end
        function [varargout] = realmax(varargin)
            [varargout{1:nargout}] = functionNotSupported('realmax');
        end
        function [varargout] = realmin(varargin)
            [varargout{1:nargout}] = functionNotSupported('realmin');
        end
        function [varargout] = repelem(varargin)
            [varargout{1:nargout}] = functionNotSupported('repelem');
        end
        function [varargout] = rosser(varargin)
            [varargout{1:nargout}] = functionNotSupported('rosser');
        end
        function [varargout] = rot90(varargin)
            [varargout{1:nargout}] = functionNotSupported('rot90');
        end
        function [varargout] = shiftdim(varargin)
            [varargout{1:nargout}] = functionNotSupported('shiftdim');
        end
        function [varargout] = squeeze(varargin)
            [varargout{1:nargout}] = functionNotSupported('squeeze');
        end
        function [varargout] = sub2ind(varargin)
            [varargout{1:nargout}] = functionNotSupported('sub2ind');
        end
        function [varargout] = toeplitz(varargin)
            [varargout{1:nargout}] = functionNotSupported('toeplitz');
        end
        function [varargout] = vander(varargin)
            [varargout{1:nargout}] = functionNotSupported('vander');
        end
        function [varargout] = wilkinson(varargin)
            [varargout{1:nargout}] = functionNotSupported('wilkinson');
        end
        function [varargout] = ode23(varargin)
            [varargout{1:nargout}] = functionNotSupported('ode23');
        end
        function [varargout] = ode45(varargin)
            [varargout{1:nargout}] = functionNotSupported('ode45');
        end
        function [varargout] = odeget(varargin)
            [varargout{1:nargout}] = functionNotSupported('odeget');
        end
        function [varargout] = odeprint(varargin)
            [varargout{1:nargout}] = functionNotSupported('odeprint');
        end
        function [varargout] = quad2d(varargin)
            [varargout{1:nargout}] = functionNotSupported('quad2d');
        end
        function [varargout] = quadgk(varargin)
            [varargout{1:nargout}] = functionNotSupported('quadgk');
        end
        function [varargout] = hsv2rgb(varargin)
            [varargout{1:nargout}] = functionNotSupported('hsv2rgb');
        end
        function [varargout] = imresize(varargin)
            [varargout{1:nargout}] = functionNotSupported('imresize');
        end
        function [varargout] = rgb2gray(varargin)
            [varargout{1:nargout}] = functionNotSupported('rgb2gray');
        end
        function [varargout] = rgb2hsv(varargin)
            [varargout{1:nargout}] = functionNotSupported('rgb2hsv');
        end
        function [varargout] = imread(varargin)
            [varargout{1:nargout}] = functionNotSupported('imread');
        end
        function [varargout] = fclose(varargin)
            [varargout{1:nargout}] = functionNotSupported('fclose');
        end
        function [varargout] = feof(varargin)
            [varargout{1:nargout}] = functionNotSupported('feof');
        end
        function [varargout] = fopen(varargin)
            [varargout{1:nargout}] = functionNotSupported('fopen');
        end
        function [varargout] = fprintf(varargin)
            [varargout{1:nargout}] = functionNotSupported('fprintf');
        end
        function [varargout] = fread(varargin)
            [varargout{1:nargout}] = functionNotSupported('fread');
        end
        function [varargout] = frewind(varargin)
            [varargout{1:nargout}] = functionNotSupported('frewind');
        end
        function [varargout] = fseek(varargin)
            [varargout{1:nargout}] = functionNotSupported('fseek');
        end
        function [varargout] = ftell(varargin)
            [varargout{1:nargout}] = functionNotSupported('ftell');
        end
        function [varargout] = fwrite(varargin)
            [varargout{1:nargout}] = functionNotSupported('fwrite');
        end
        function [varargout] = error(varargin)
            [varargout{1:nargout}] = functionNotSupported('error');
        end
        function [varargout] = nargchk(varargin)
            [varargout{1:nargout}] = functionNotSupported('nargchk');
        end
        function [varargout] = validatestring(varargin)
            [varargout{1:nargout}] = functionNotSupported('validatestring');
        end
        function [varargout] = cholupdate(varargin)
            [varargout{1:nargout}] = functionNotSupported('cholupdate');
        end
        function [varargout] = cond(varargin)
            [varargout{1:nargout}] = functionNotSupported('cond');
        end
        function [varargout] = det(varargin)
            [varargout{1:nargout}] = functionNotSupported('det');
        end
        function [varargout] = eig(varargin)
            [varargout{1:nargout}] = functionNotSupported('eig');
        end
        function [varargout] = expm(varargin)
            [varargout{1:nargout}] = functionNotSupported('expm');
        end
        function [varargout] = isbanded(varargin)
            [varargout{1:nargout}] = functionNotSupported('isbanded');
        end
        function [varargout] = linsolve(varargin)
            [varargout{1:nargout}] = functionNotSupported('linsolve');
        end
        function [varargout] = ltitr(varargin)
            [varargout{1:nargout}] = functionNotSupported('ltitr');
        end
        function [varargout] = lu(varargin)
            [varargout{1:nargout}] = functionNotSupported('lu');
        end
        function [varargout] = normest(varargin)
            [varargout{1:nargout}] = functionNotSupported('normest');
        end
        function [varargout] = null(varargin)
            [varargout{1:nargout}] = functionNotSupported('null');
        end
        function [varargout] = orth(varargin)
            [varargout{1:nargout}] = functionNotSupported('orth');
        end
        function [varargout] = pinv(varargin)
            [varargout{1:nargout}] = functionNotSupported('pinv');
        end
        function [varargout] = planerot(varargin)
            [varargout{1:nargout}] = functionNotSupported('planerot');
        end
        function [varargout] = polyeig(varargin)
            [varargout{1:nargout}] = functionNotSupported('polyeig');
        end
        function [varargout] = qr(varargin)
            [varargout{1:nargout}] = functionNotSupported('qr');
        end
        function [varargout] = rank(varargin)
            [varargout{1:nargout}] = functionNotSupported('rank');
        end
        function [varargout] = rcond(varargin)
            [varargout{1:nargout}] = functionNotSupported('rcond');
        end
        function [varargout] = rsf2csf(varargin)
            [varargout{1:nargout}] = functionNotSupported('rsf2csf');
        end
        function [varargout] = schur(varargin)
            [varargout{1:nargout}] = functionNotSupported('schur');
        end
        function [varargout] = sprintf(varargin)
            [varargout{1:nargout}] = functionNotSupported('sprintf');
        end
        function [varargout] = sqrtm(varargin)
            [varargout{1:nargout}] = functionNotSupported('sqrtm');
        end
        function [varargout] = svd(varargin)
            [varargout{1:nargout}] = functionNotSupported('svd');
        end
        function [varargout] = vecnorm(varargin)
            [varargout{1:nargout}] = functionNotSupported('vecnorm');
        end
        function [varargout] = bitand(varargin)
            coder.internal.implicitExpansionBuiltin;
            [varargout{1:nargout}] = functionNotSupported('bitand');
        end
        function [varargout] = bitcmp(varargin)
            [varargout{1:nargout}] = functionNotSupported('bitcmp');
        end
        function [varargout] = bitget(varargin)
            [varargout{1:nargout}] = functionNotSupported('bitget');
        end
        function [varargout] = bitor(varargin)
            coder.internal.implicitExpansionBuiltin;
            [varargout{1:nargout}] = functionNotSupported('bitor');
        end
        function [varargout] = bitset(varargin)
            [varargout{1:nargout}] = functionNotSupported('bitset');
        end
        function [varargout] = bitshift(varargin)
            [varargout{1:nargout}] = functionNotSupported('bitshift');
        end
        function [varargout] = bitxor(varargin)
            coder.internal.implicitExpansionBuiltin;
            [varargout{1:nargout}] = functionNotSupported('bitxor');
        end
        function [varargout] = colon(varargin)
            [varargout{1:nargout}] = functionNotSupported('colon');
        end
        function [varargout] = idivide(varargin)
            coder.internal.implicitExpansionBuiltin;
            [varargout{1:nargout}] = functionNotSupported('idivide');
        end
        function [varargout] = intersect(varargin)
            [varargout{1:nargout}] = functionNotSupported('intersect');
        end
        function [varargout] = ismember(varargin)
            [varargout{1:nargout}] = functionNotSupported('ismember');
        end
        function [varargout] = mpower(varargin)
            [varargout{1:nargout}] = functionNotSupported('mpower');
        end
        function [varargout] = mrdivide(varargin)
            [varargout{1:nargout}] = functionNotSupported('mrdivide');
        end
        function [varargout] = power(varargin)
            coder.internal.implicitExpansionBuiltin;
            [varargout{1:nargout}] = functionNotSupported('power');
        end
        function [varargout] = setdiff(varargin)
            [varargout{1:nargout}] = functionNotSupported('setdiff');
        end
        function [varargout] = setxor(varargin)
            [varargout{1:nargout}] = functionNotSupported('setxor');
        end
        function [varargout] = union(varargin)
            [varargout{1:nargout}] = functionNotSupported('union');
        end
        function [varargout] = unique(varargin)
            [varargout{1:nargout}] = functionNotSupported('unique');
        end
        function [varargout] = xor(varargin)
            coder.internal.implicitExpansionBuiltin;
            [varargout{1:nargout}] = functionNotSupported('xor');
        end
        function [varargout] = fminbnd(varargin)
            [varargout{1:nargout}] = functionNotSupported('fminbnd');
        end
        function [varargout] = fminsearch(varargin)
            [varargout{1:nargout}] = functionNotSupported('fminsearch');
        end
        function [varargout] = fzero(varargin)
            [varargout{1:nargout}] = functionNotSupported('fzero');
        end
        function [varargout] = lsqnonneg(varargin)
            [varargout{1:nargout}] = functionNotSupported('lsqnonneg');
        end
        function [varargout] = optimget(varargin)
            [varargout{1:nargout}] = functionNotSupported('optimget');
        end
        function [varargout] = optimset(varargin)
            [varargout{1:nargout}] = functionNotSupported('optimset');
        end
        function [varargout] = inpolygon(varargin)
            [varargout{1:nargout}] = functionNotSupported('inpolygon');
        end
        function [varargout] = interp1(varargin)
            [varargout{1:nargout}] = functionNotSupported('interp1');
        end
        function [varargout] = interp1q(varargin)
            [varargout{1:nargout}] = functionNotSupported('interp1q');
        end
        function [varargout] = interp2(varargin)
            [varargout{1:nargout}] = functionNotSupported('interp2');
        end
        function [varargout] = interp3(varargin)
            [varargout{1:nargout}] = functionNotSupported('interp3');
        end
        function [varargout] = interpn(varargin)
            [varargout{1:nargout}] = functionNotSupported('interpn');
        end
        function [varargout] = mkpp(varargin)
            [varargout{1:nargout}] = functionNotSupported('mkpp');
        end
        function [varargout] = padecoef(varargin)
            [varargout{1:nargout}] = functionNotSupported('padecoef');
        end
        function [varargout] = pchip(varargin)
            [varargout{1:nargout}] = functionNotSupported('pchip');
        end
        function [varargout] = poly(varargin)
            [varargout{1:nargout}] = functionNotSupported('poly');
        end
        function [varargout] = polyarea(varargin)
            [varargout{1:nargout}] = functionNotSupported('polyarea');
        end
        function [varargout] = polyder(varargin)
            [varargout{1:nargout}] = functionNotSupported('polyder');
        end
        function [varargout] = polyfit(varargin)
            [varargout{1:nargout}] = functionNotSupported('polyfit');
        end
        function [varargout] = polyint(varargin)
            [varargout{1:nargout}] = functionNotSupported('polyint');
        end
        function [varargout] = polyval(varargin)
            [varargout{1:nargout}] = functionNotSupported('polyval');
        end
        function [varargout] = polyvalm(varargin)
            [varargout{1:nargout}] = functionNotSupported('polyvalm');
        end
        function [varargout] = ppval(varargin)
            [varargout{1:nargout}] = functionNotSupported('ppval');
        end
        function [varargout] = pwch(varargin)
            [varargout{1:nargout}] = functionNotSupported('pwch');
        end
        function [varargout] = rectint(varargin)
            [varargout{1:nargout}] = functionNotSupported('rectint');
        end
        function [varargout] = roots(varargin)
            [varargout{1:nargout}] = functionNotSupported('roots');
        end
        function [varargout] = spline(varargin)
            [varargout{1:nargout}] = functionNotSupported('spline');
        end
        function [varargout] = unmkpp(varargin)
            [varargout{1:nargout}] = functionNotSupported('unmkpp');
        end
        function [varargout] = zp2tf(varargin)
            [varargout{1:nargout}] = functionNotSupported('zp2tf');
        end
        function [varargout] = randi(varargin)
            [varargout{1:nargout}] = functionNotSupported('randi');
        end
        function [varargout] = randperm(varargin)
            [varargout{1:nargout}] = functionNotSupported('randperm');
        end
        function [varargout] = rng(varargin)
            [varargout{1:nargout}] = functionNotSupported('rng');
        end
        function [varargout] = airy(varargin)
            [varargout{1:nargout}] = functionNotSupported('airy');
        end
        function [varargout] = besseli(varargin)
            [varargout{1:nargout}] = functionNotSupported('besseli');
        end
        function [varargout] = besselj(varargin)
            [varargout{1:nargout}] = functionNotSupported('besselj');
        end
        function [varargout] = beta(varargin)
            [varargout{1:nargout}] = functionNotSupported('beta');
        end
        function [varargout] = betainc(varargin)
            [varargout{1:nargout}] = functionNotSupported('betainc');
        end
        function [varargout] = betaincinv(varargin)
            [varargout{1:nargout}] = functionNotSupported('betaincinv');
        end
        function [varargout] = betaln(varargin)
            [varargout{1:nargout}] = functionNotSupported('betaln');
        end
        function [varargout] = cart2pol(varargin)
            [varargout{1:nargout}] = functionNotSupported('cart2pol');
        end
        function [varargout] = cart2sph(varargin)
            [varargout{1:nargout}] = functionNotSupported('cart2sph');
        end
        function [varargout] = cross(varargin)
            [varargout{1:nargout}] = functionNotSupported('cross');
        end
        function [varargout] = dot(varargin)
            [varargout{1:nargout}] = functionNotSupported('dot');
        end
        function [varargout] = ellipke(varargin)
            [varargout{1:nargout}] = functionNotSupported('ellipke');
        end
        function [varargout] = erf(varargin)
            [varargout{1:nargout}] = functionNotSupported('erf');
        end
        function [varargout] = erfc(varargin)
            [varargout{1:nargout}] = functionNotSupported('erfc');
        end
        function [varargout] = erfcinv(varargin)
            [varargout{1:nargout}] = functionNotSupported('erfcinv');
        end
        function [varargout] = erfcx(varargin)
            [varargout{1:nargout}] = functionNotSupported('erfcx');
        end
        function [varargout] = erfinv(varargin)
            [varargout{1:nargout}] = functionNotSupported('erfinv');
        end
        function [varargout] = expint(varargin)
            [varargout{1:nargout}] = functionNotSupported('expint');
        end
        function [varargout] = factor(varargin)
            [varargout{1:nargout}] = functionNotSupported('factor');
        end
        function [varargout] = gammainc(varargin)
            [varargout{1:nargout}] = functionNotSupported('gammainc');
        end
        function [varargout] = gammaincinv(varargin)
            [varargout{1:nargout}] = functionNotSupported('gammaincinv');
        end
        function [varargout] = gcd(varargin)
            [varargout{1:nargout}] = functionNotSupported('gcd');
        end
        function [varargout] = isprime(varargin)
            [varargout{1:nargout}] = functionNotSupported('isprime');
        end
        function [varargout] = lcm(varargin)
            [varargout{1:nargout}] = functionNotSupported('lcm');
        end
        function [varargout] = nchoosek(varargin)
            [varargout{1:nargout}] = functionNotSupported('nchoosek');
        end
        function [varargout] = pol2cart(varargin)
            [varargout{1:nargout}] = functionNotSupported('pol2cart');
        end
        function [varargout] = primes(varargin)
            [varargout{1:nargout}] = functionNotSupported('primes');
        end
        function [varargout] = psi(varargin)
            [varargout{1:nargout}] = functionNotSupported('psi');
        end
        function [varargout] = sph2cart(varargin)
            [varargout{1:nargout}] = functionNotSupported('sph2cart');
        end
        function [varargout] = bin2dec(varargin)
            [varargout{1:nargout}] = functionNotSupported('bin2dec');
        end
        function [varargout] = blanks(varargin)
            [varargout{1:nargout}] = functionNotSupported('blanks');
        end
        function [varargout] = contains(varargin)
            [varargout{1:nargout}] = functionNotSupported('contains');
        end
        function [varargout] = count(varargin)
            [varargout{1:nargout}] = functionNotSupported('count');
        end
        function [varargout] = deblank(varargin)
            [varargout{1:nargout}] = functionNotSupported('deblank');
        end
        function [varargout] = dec2bin(varargin)
            [varargout{1:nargout}] = functionNotSupported('dec2bin');
        end
        function [varargout] = dec2hex(varargin)
            [varargout{1:nargout}] = functionNotSupported('dec2hex');
        end
        function [varargout] = endsWith(varargin)
            [varargout{1:nargout}] = functionNotSupported('endsWith');
        end
        function [varargout] = erase(varargin)
            [varargout{1:nargout}] = functionNotSupported('erase');
        end
        function [varargout] = hex2dec(varargin)
            [varargout{1:nargout}] = functionNotSupported('hex2dec');
        end
        function [varargout] = hex2num(varargin)
            [varargout{1:nargout}] = functionNotSupported('hex2num');
        end
        function [varargout] = int2str(varargin)
            [varargout{1:nargout}] = functionNotSupported('int2str');
        end
        function [varargout] = isletter(varargin)
            [varargout{1:nargout}] = functionNotSupported('isletter');
        end
        function [varargout] = isspace(varargin)
            [varargout{1:nargout}] = functionNotSupported('isspace');
        end
        function [varargout] = isstrprop(varargin)
            [varargout{1:nargout}] = functionNotSupported('isstrprop');
        end
        function [varargout] = lower(varargin)
            [varargout{1:nargout}] = functionNotSupported('lower');
        end
        function [varargout] = num2hex(varargin)
            [varargout{1:nargout}] = functionNotSupported('num2hex');
        end
        function [varargout] = replace(varargin)
            [varargout{1:nargout}] = functionNotSupported('replace');
        end
        function [varargout] = reverse(varargin)
            [varargout{1:nargout}] = functionNotSupported('reverse');
        end
        function [varargout] = startsWith(varargin)
            [varargout{1:nargout}] = functionNotSupported('startsWith');
        end
        function [varargout] = str2double(varargin)
            [varargout{1:nargout}] = functionNotSupported('str2double');
        end
        function [varargout] = strfind(varargin)
            [varargout{1:nargout}] = functionNotSupported('strfind');
        end
        function [varargout] = strip(varargin)
            [varargout{1:nargout}] = functionNotSupported('strip');
        end
        function [varargout] = strjoin(varargin)
            [varargout{1:nargout}] = functionNotSupported('strjoin');
        end
        function [varargout] = strjust(varargin)
            [varargout{1:nargout}] = functionNotSupported('strjust');
        end
        function [varargout] = strlength(varargin)
            [varargout{1:nargout}] = functionNotSupported('strlength');
        end
        function [varargout] = strrep(varargin)
            [varargout{1:nargout}] = functionNotSupported('strrep');
        end
        function [varargout] = strtok(varargin)
            [varargout{1:nargout}] = functionNotSupported('strtok');
        end
        function [varargout] = strtrim(varargin)
            [varargout{1:nargout}] = functionNotSupported('strtrim');
        end
        function [varargout] = upper(varargin)
            [varargout{1:nargout}] = functionNotSupported('upper');
        end
        function [varargout] = mustBeMember(varargin)
            [varargout{1:nargout}] = functionNotSupported('mustBeMember');
        end
        function C = complex(a,b)
            coder.internal.errorIf(issparse(a), 'MATLAB:complex:invalidRealPartInput');
            coder.internal.errorIf(nargin==2 && issparse(b), 'MATLAB:complex:invalidImagPartInput');
            C = coder.internal.sparse(); %this line is unreachable, one of the inputs must be sparse;
        end
        %------- UNSUPPORTED END ------------------------------------------
        U = triu(A, k);
        L = tril(A, k);
        y = diag(this,k);
        K = kron(this,B);
        y = repmat(this, varargin);
        y = reshape(this, varargin);
        y = fliplr(this);
        y = flipud(this);
        bool = isdiag(A);
        bool = ishermitian(this, skewOption);
        bool = issymmetric(this, skewOption);
        n = norm(this,p);
        [l, u] = bandwidth(this, flag);
        bool = istril(this);
        bool = istriu(this);
        function [R, varargout] = chol(A, form, varargin) %#ok<STOUT>
            coder.internal.assert(size(A,1) == size(A,2), 'MATLAB:square');
            coder.internal.assert(isa(A.d, 'double') , 'Coder:sparfun:sparseDoubleChol');
            coder.internal.assert(nargin < 3  && nargout < 2, ...
            'Coder:toolbox:SparseCholSyntax');
            
            if nargin == 1
                upper = true;
            else
                coder.internal.assert( nargin == 1 ||...
                    strcmp(form, 'upper') || strcmp(form, 'lower'),...
                    'Coder:toolbox:SparseCholOption');
                if strcmp(form, 'upper')
                    upper = true;
                else% strcmp(form, 'lower')
                    upper = false;
                end
            end
            R = coder.internal.CXSparseAPI.chol(A, upper);
        end
        function y = mldivide(A,b)
            if ~issparse(A)
                y = A\full(b);
                return;
            end
            if coder.internal.isConst(size(A)) && isscalar(A)
                y = A.\b;
                return;
            end
            allowWarnings = true;
            y = coder.internal.CXSparseAPI.iteratedSolve(A,b,allowWarnings);
        end
        function y = inv(A)
            coder.internal.assert(size(A,1) == size(A,2), 'MATLAB:square');
            y = A\speye(size(A,1));
        end
    end
    methods (Access = private, Static = true)
        function result = matlabCodegenNontunableProperties(~)
            result = {'matlabCodegenUserReadableName'};
        end
        function result = matlabCodegenSoftNontunableProperties(~)
            result = {'m' 'n'};
        end
        function validatePermuteOrder(order)
            coder.inline('always');
            coder.internal.prefer_const(order);
            coder.internal.assert(isreal(order), ...
                'MATLAB:permute:complexIndex');
            coder.internal.assert(coder.internal.isConst(size(order)), ...
                'Coder:toolbox:permute_4');
            ND = coder.const(numel(order));
            coder.internal.assert(ND >= 2,'MATLAB:permute:tooFewIndices'); % Only 2D sparse allowed
            coder.internal.assert(isPermutation(order), ...
                'Coder:toolbox:permute_invalidPermutation');
        end
    end
    methods (Access = public, Static = true, Hidden = true)
        I = eyeLike(ndiag,m,n,egone);
        this = applyScalarFunctionInPlace(fname,scalarfun,this,varargin);
        sanityCheck(this);
        s = genericLike(this,eg,varargin);
        function s = spallocLike(m,n,nzmax,eg)
            if issparse(eg)
                emptyEg = zeros(0,0,'like',eg.d);
            else
                emptyEg = zeros(0,0,'like',eg);
            end
            s = coder.internal.sparse([],[],emptyEg,m,n,nzmax);
            % Sanity check happens in c'tor
        end
        function s = spalloc(m,n,nzmax,cls)
            if nargin < 4
                cls = 'double';
            else
                coder.internal.prefer_const(cls);
            end
            s = coder.internal.sparse.spallocLike(m,n,nzmax,zeros(cls));
            % Sanity check happens in c'tor
        end
        function s = nullcopyLike(m,n,nzmax, eg)
            s = coder.internal.sparse();
            s.m = coder.internal.indexInt(m);
            s.n = coder.internal.indexInt(n);
            nzmax = max2(nzmax, ones([1,1], 'like', nzmax));
            s.maxnz = coder.internal.indexInt(nzmax);
            if issparse(eg)
                s.d = coder.nullcopy(ones(coder.internal.ignoreRange(nzmax), 1, 'like', eg.d));
            else
                s.d = coder.nullcopy(ones(coder.internal.ignoreRange(nzmax), 1, 'like', eg));
            end
            s.rowidx = coder.nullcopy(ones(coder.internal.ignoreRange(nzmax),1, coder.internal.indexIntClass));
            s.colidx = coder.nullcopy(ones(coder.internal.ignoreRange(n+1), 1, coder.internal.indexIntClass));
            s.matlabCodegenUserReadableName = makeUserReadableName(s);
            %this matrix is not sane, but will hopefully be completely
            %rewritten by whatever function is calling this
        end
        function p = isAllowedSparseClass(s, checkType)
            % Check if s is of an allowed sparse class.
            coder.inline('always')
            if nargin < 2
                % s is a variable check if it is of the correct type.
                checkType = true;
            else
                % s is a class name, check if it can be used to construct a
                % sparse matrix.
                coder.internal.prefer_const(checkType)
            end
            if checkType
                % variable input
                p = islogical(s) || isa(s,'double') || ... 
                    (matlab.internal.feature("SingleSparse") && isa(s,'single')) ... 
                    || ischar(s);
            else
                % typename input
                coder.internal.prefer_const(s)
                p = coder.internal.isTextRow(s);
                p = p && (strcmp(s,'double') || strcmp(s,'logical') || ... 
                    (matlab.internal.feature("SingleSparse") && strcmp(s,'single')));
            end
        end
    end
    methods (Access = private, Hidden = true)
        y = locTranspose(this,doConj);
        this = fillIn(this,skipDuplCheck);
        c = spcat(dim,ceg,cnnz,cnrows,cncols,varargin);
    end
    methods (Access = public, Hidden = true)
        s = binOp(a,b,opstr,op);
        counts = nonzeroRowCounts(x);
        y = rowReduction(f,x);
        function n = nnzInt(this)
            n = this.colidx(end)-1;
        end
        function p = canUseRowMap(this)
        % Helper function for functions like all, any, sum, prod, etc. Returns true if
        % it is safe to allocate an array whose size is the number of rows of
        % this.
            p = this.n ~= 0 && (this.m <= nnzInt(this) || this.m <= this.n+1);
        end
        function p = allNonzero(this)
            if this.m == 0 || this.n == 0
                p = true;
            else
                p = coder.internal.indexDivide(nnzInt(this),this.m) == this.n;
            end
        end
        function out = castToComplex(s)
            out = coder.internal.sparse();
            out.rowidx = s.rowidx;
            out.colidx = s.colidx;
            out.d = complex(s.d,0);
            out.m = s.m;
            out.n = s.n;
            out.maxnz = s.maxnz;
            out.matlabCodegenUserReadableName = makeUserReadableName(out);
            coder.internal.sparse.sanityCheck(out);
        end
        function out = discardSize(this)
            out = coder.internal.sparse.spallocLike(coder.ignoreConst(this.m),...
                coder.ignoreConst(this.n),...
                this.nzmax,...
                this.d(1));
            out.d = this.d;
            out.rowidx = this.rowidx;
            out.colidx = this.colidx;
            out.maxnz = this.maxnz;
        end
    end
    % TODO: User readable name. Likely need specializations for supported data
    % types.

    methods (Access = public, Static = true, Hidden = true)
        function this = matlabCodegenToRedirected(s)
        % Given MATLAB sparse, s, return coder.internal.sparse, this.
            [nr,nc] = size(s);
            nz = nnz(s);
            % Validate sizes as we'll be converting these to integers
            assertValidSize(nr);
            assertValidSize(nc);
            assertValidSize(nz);
            [jc,ir] = coder.internal.getSparseProps(s);
            try
                if nz == 0
                    if isreal(s)
                        eg = ones(class(s));
                    else
                        eg = complex(ones(class(s)),ones(class(s)));
                    end
                    this = coder.internal.sparse.spallocLike(nr,nc,nz,eg);
                    return
                end

                this = coder.internal.sparse();
                this.m = coder.internal.indexInt(nr);
                this.n = coder.internal.indexInt(nc);
                this.maxnz = coder.internal.indexInt(nz);
                this.d = nonzeros(s);
                this.rowidx = coder.internal.indexInt(ir);
                this.colidx = coder.internal.indexInt(jc);
            catch me
                warning('Attempt to convert a sparse to a coder.internal.sparse failed:\n\n%s',me.getReport());
                this = coder.internal.sparse(nr,nc);
            end
            coder.internal.sparse.sanityCheck(this);
        end
        function s = matlabCodegenFromRedirected(this)
        % Given coder.internal.sparse, this, return MATLAB sparse, s.
            try 
                md = double(this.m);
                nd = double(this.n);
                thisnnz = nnzInt(this);
                if thisnnz == 0
                    s = sparse([],[],zeros(0,0,'like',this.d),md,nd);
                else
                    counts = diff(this.colidx);
                    colIdx = repelem(1:nd,counts);
                    if thisnnz == this.maxnz
                        s = sparse(double(this.rowidx),colIdx,this.d,md,nd);
                    else
                        s = sparse(double(this.rowidx(1:thisnnz)),colIdx,this.d(1:thisnnz),md,nd);
                    end
                end
            catch me
                warning(['Attempting to convert a coder.internal.sparse to a ' ...
                         'MATLAB sparse resulted in an error. This usually ' ...
                         'signifies an inconsistency with the ' ...
                         'coder.internal.sparse matrix. Make sure that the ' ...
                         'dimensions of the properties rowidx and d are ' ...
                         'consistent and check nnz and nzmax.\n\nThe error ' ...
                         'report is:\n\n%s'],me.getReport());

                s = sparse(double(this.rowidx(1:thisnnz)),colIdx,this.d(1:thisnnz),md,nd);
            end
        end
    end
    properties (Hidden = true, SetAccess = 'private')
        matlabCodegenUserReadableName;
    end
end

%--------------------------------------------------------------------------

function assertValidSize(s)
    coder.internal.prefer_const(s);
    if ~coder.target('MATLAB')
        coder.internal.assert(coder.internal.isConst(isscalar(s)) && isscalar(s), ...
                              'Coder:toolbox:eml_assert_valid_size_arg_6');
        fs = full(s);
        if islogical(fs)
            coder.internal.assertValidSizeArg(coder.internal.indexInt(fs));
        else
            coder.internal.assertValidSizeArg(fs);
        end
        coder.internal.errorIf(fs < 0, 'Coder:toolbox:SparseNegativeSize');
        MAXI = intmax(coder.internal.indexIntClass);
        coder.internal.assert(fs < MAXI, ...
                              'Coder:toolbox:SparseMaxSize',MAXI);
    end
end

%--------------------------------------------------------------------------

function sint = assertValidIndexArg(s)
    ns = coder.internal.indexInt(numel(s));
    if issparse(s)
        % Any zeros are invalid
        coder.internal.assert(nnzInt(s) == ns, ...
                              'MATLAB:sparsfcn:nonPosIndex');
        sint = assertValidIndexArg(full(s));
        return
    end
    if islogical(s)
        sint = assertValidIndexArg(coder.internal.indexInt(s));
        return
    end
    coder.internal.assert(coder.internal.isBuiltInNumeric(s), ...
                          'MATLAB:sparsfcn:nonPosIndex');
    sint = coder.nullcopy(zeros(ns,ONE,'like',ONE));
    MAXI = intmax(coder.internal.indexIntClass());
    ZEROSK = zeros('like',s);
    for k = 1:ns
        sk = s(k);
        coder.internal.assert(floor(sk) == sk, ...
                              'MATLAB:sparsfcn:nonIntegerIndex');
        coder.internal.assert(sk < MAXI, ...
                              'MATLAB:sparsfcn:largeIndex');
        coder.internal.assert(ZEROSK < sk, ...
                              'MATLAB:sparsfcn:nonPosIndex');
        sint(k) = sk;
    end
end

%--------------------------------------------------------------------------

function [idx,a,b] = locSortrows(idx,a,b)
% Helper to do the equivalent of [x,idx] = sortrows([a,b]);
    idx = coder.internal.introsort(idx,ONE,coder.internal.indexInt(numel(a)), ...
                                   @(i,j)sortrowsCmp(i,j,a,b));
    a = permuteVector(idx,a);
    b = permuteVector(idx,b);
end

%--------------------------------------------------------------------------

function y = permuteVector(idx,y)
    ny = coder.internal.indexInt(numel(y));
    t = y;
    for k = 1:ny
        y(k) = t(idx(k));
    end
end

%--------------------------------------------------------------------------

function p = sortrowsCmp(i,j,a,b)
    coder.inline('always');
    ai = a(i);
    aj = a(j);
    if ai < aj
        p = true;
    elseif ai == aj
        p = b(i) < b(j);
    else
        p = false;
    end
end

%--------------------------------------------------------------------------

function [idx,a] = locSortidx(idx,a)
% Helper to do the equivalent of idx = coder.internal.sortIdx(a);
    idx = coder.internal.introsort(idx,ONE,coder.internal.indexInt(numel(a)), ...
                                   @(i,j)sortidxCmp(i,j,a));
    a = permuteVector(idx,a);
end

%--------------------------------------------------------------------------

function p = sortidxCmp(i,j,a)
    coder.inline('always');
    p = a(i) < a(j);
end

%--------------------------------------------------------------------------

function p = bothSparse(a,b)
    p = issparse(a) && issparse(b);
end

%--------------------------------------------------------------------------

function p = sparseAOrFullB(a,b)
    p = issparse(a) || ~issparse(b);
end

%--------------------------------------------------------------------------

function p = firstSparse(a, ~)
    p = issparse(a);
end

%--------------------------------------------------------------------------

function [varargout] = functionNotSupported(fname)
    coder.internal.prefer_const(fname);
    coder.inline('always');
    coder.internal.assert(false, ...
        'Coder:toolbox:FunctionDoesNotSupportDatatype',fname,'sparse');
    [varargout{1:nargout}] = deal([]);
end

%--------------------------------------------------------------------------

