function sanityCheck(this)
%MATLAB Code Generation Private Method

% Performs sanity checks on the input sparse matrix to verify it is properly
% constructed. Disable the feature control switch SparseSanityChecks to disable
% this check.
%   Copyright 2017-2018 The MathWorks, Inc.
%#codegen

if ~issparse(this)
    return
end
if ~coder.target('MATLAB') && ~coder.internal.get_eml_option('SparseSanityChecks')
    % Sanity checks are disabled in codegen so skip
    return
end

% 1. Vectors should be non-empty columns, maxnz should be at least 1, sizes positive
coder.internal.assert(~isempty(this.colidx), 'Coder:toolbox:SparseSanityCheckPropError', ...
    'colidx','non-empty');
coder.internal.assert(~isempty(this.rowidx), ...
    'Coder:toolbox:SparseSanityCheckPropError', 'rowidx','non-empty');
coder.internal.assert(~isempty(this.d), ...
    'Coder:toolbox:SparseSanityCheckPropError', 'd','non-empty');
coder.internal.assert(coder.internal.isConst(iscolumn(this.colidx)) && iscolumn(this.colidx), ...
    'Coder:toolbox:SparseSanityCheckPropError', 'colidx','a compile-time column');
coder.internal.assert(coder.internal.isConst(iscolumn(this.rowidx)) && iscolumn(this.rowidx), ...
    'Coder:toolbox:SparseSanityCheckPropError', 'rowidx','a compile-time column');
coder.internal.assert(coder.internal.isConst(iscolumn(this.d)) && iscolumn(this.d), ...
    'Coder:toolbox:SparseSanityCheckPropError', 'd','a compile-time column');
coder.internal.errorIf(~coder.target('MATLAB') && coder.internal.isConst(size(this.d)),...
    'Coder:toolbox:SparseSanityCheckPropError', 'd', 'variable sized');
coder.internal.errorIf(~coder.target('MATLAB') && coder.internal.isConst(size(this.rowidx)),...
    'Coder:toolbox:SparseSanityCheckPropError', 'rowidx', 'variable sized');
coder.internal.errorIf(~coder.target('MATLAB') && coder.internal.isConst(size(this.colidx)),...
    'Coder:toolbox:SparseSanityCheckPropError', 'colidx', 'variable sized');
coder.internal.assert(this.maxnz >= ONE, ...
    'Coder:toolbox:SparseSanityCheckPropError', 'maxnz','at least 1');
coder.internal.assert(this.m >= ZERO, ...
    'Coder:toolbox:SparseSanityCheckPropError', 'm','nonnegative');
coder.internal.assert(this.n >= ZERO, ...
    'Coder:toolbox:SparseSanityCheckPropError', 'n','nonnegative');
coder.internal.assert(coder.internal.indexInt(numel(this.colidx)) == this.n+1, ...
    'Coder:toolbox:SparseSanityCheckPropError', 'colidx','n+1 elements long');
coder.internal.assert(coder.internal.indexInt(numel(this.rowidx)) == this.maxnz, ...
    'Coder:toolbox:SparseSanityCheckPropError', 'rowidx','nzmax elements long');
coder.internal.assert(coder.internal.indexInt(numel(this.d)) == this.maxnz, ...
    'Coder:toolbox:SparseSanityCheckPropError', 'd','nzmax elements long');

% 2. Indices must be at least 1. We'll check monotonicity later which ensures
% all elements are at least 1.
coder.internal.assert(this.colidx(ONE) >= ONE, ...
    'Coder:toolbox:SparseSanityCheckPropError', 'colidx','at least 1');
coder.internal.assert(this.colidx(ONE) >= ONE, ...
    'Coder:toolbox:SparseSanityCheckPropError', 'rowidx','at least 1');

% 3. Zeros should be squeezed out
nz = nnzInt(this);
ZEROD = zeros('like',this.d);
if coder.target('MATLAB')
    coder.internal.errorIf(any(this.d(1:nz) == ZEROD), ...
        'Coder:toolbox:SparseSanityCheckZeros',find(this.d,1), this.maxnz, nz);
else
    for k = 1:nz
        coder.internal.errorIf(this.d(k) == ZEROD, 'Coder:toolbox:SparseSanityCheckZeros', ...
            k, this.maxnz, nz);
    end
end

% 4. Row indices should be sorted and unique in each column
msg = 'sorted with unique elements in each column';
if coder.target('MATLAB')
    coder.internal.assert(issorted(this.colidx), ...
        'Coder:toolbox:SparseSanityCheckPropError','colidx','non-decreasing');
    % Check that this.rowidx is strictly increasing in each column by verifying that
    % the only elements which are smaller than their successors are the endpoints
    % specified in this.colidx.
    ridx = this.rowidx(1:nz);
    cidx = this.colidx;
    dridx = diff(ridx);
    negidx = find(dridx <= 0);
    if this.n > nz
        negidx = negidx+1;
    else
        cidx = cidx-1;
    end
    coder.internal.assert(all(ismember(negidx,cidx)), ...
        'Coder:toolbox:SparseSanityCheckPropError','rowidx',msg);
else
    for col = 1:this.n
        coder.internal.assert(this.colidx(col) <= this.colidx(col+1), ...
            'Coder:toolbox:SparseSanityCheckPropError','colidx','non-decreasing');
        colend = this.colidx(col+1)-1;
        for k = this.colidx(col):colend-1
            coder.internal.assert(this.rowidx(k) < this.rowidx(k+1), ...
                'Coder:toolbox:SparseSanityCheckPropError','rowidx',msg);
        end
    end
end

if ~coder.target('MATLAB')
    eml_check_upperbounds(this.d, [-1,1]);
    eml_check_upperbounds(this.rowidx, [-1,1]);
    eml_check_upperbounds(this.colidx, [-1,1]);
end

% 5. Verify matlabCodegenUserReadableName
if ~coder.target('MATLAB')
    if eml_ambiguous_types
        % Skip check
    else
        cls = class(this);
        if ~isreal(this)
            cplx = ' complex';
        else
            cplx = '';
        end
        if coder.internal.isConst(this.m)
            mstr = coder.const(feval('sprintf','%d',this.m));
        else
            mstr = ':?';
        end
        if coder.internal.isConst(this.n)
            nstr = coder.const(feval('sprintf','%d',this.n));
        else
            nstr = ':?';
        end
        readableName = coder.const(feval('sprintf','sparse%s %s - [%s x %s]',cplx,cls,mstr,nstr));
        coder.internal.assert(isequal(this.matlabCodegenUserReadableName,readableName), ...
                              'Coder:toolbox:SparseSanityCheckPropError','matlabCodegenUserReadableName', ...
                              coder.const(feval('sprintf','Equal to: ''%s''. Instead it has value: ''%s''',readableName,this.matlabCodegenUserReadableName)));
    end
end

%--------------------------------------------------------------------------
