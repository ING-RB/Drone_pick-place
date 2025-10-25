function [dFdy, fac, nfevals, nfcalls] = odenumjac(F, Fargs, Fvalue, options)
%ODENUMJAC Numerically compute the Jacobian dF/dY of function F(...,Y,...).
%   [DFDY,FAC] = ODENUMJAC(F,FARGS,FVALUE,OPTIONS) numerically computes 
%   the Jacobian of function F with respect to variable Y, returning it 
%   as a matrix DFDY. F could be a function of several variables. It must 
%   return a column vector. The arguments of F are specified in a cell 
%   array FARGS. Vector FVALUE contains F(FARGS{:}).  
%   The structure OPTIONS must have the following fields: DIFFVAR, VECTVARS, 
%   THRESH, and FAC. For sparse Jacobians, OPTIONS must also have fields 
%   PATTERNS and G. The field OPTIONS.DIFFVAR is the index of the 
%   differentiation variable, Y = FARGS{DIFFVAR}. For a function F(t,x), 
%   set DIFFVAR to 1 to compute DF/Dt, or to 2 to compute DF/Dx.
%   ODENUMJAC takes advantage of vectorization, i.e., when several values F 
%   can be obtained with one function evaluation. Set OPTIONS.VECTVAR 
%   to the indices of vectorized arguments: VECTVAR = [2] indicates that 
%   F(t,[x1 y2 ...]) returns [F(t,x1) F(t,x2) ...], while VECTVAR = [1,2] 
%   indicates that F([t1 t2 ...],[x1 x2 ...]) returns [F(t1,x1) F(t2,x2) ...]. 
%   OPTIONS.THRESH provides a threshold of significance for Y, i.e. 
%   the exact value of a component Y(i) with abs(Y(i)) < THRESH(i) is not 
%   important. All components of THRESH must be positive. Column FAC is 
%   working storage. On the first call, set OPTIONS.FAC to []. Do not alter 
%   the returned value between calls. 
%   
%   [DFDY,FAC] = ODENUMJAC(F,FARGS,FVALUE,OPTIONS) computes a sparse matrix 
%   DFDY if the fields OPTIONS.PATTERN and OPTIONS.G are present.  
%   PATTERN is a non-empty sparse matrix of 0's and 1's. A value of 0 for 
%   PATTERN(i,j) means that component i of the function F(...,Y,...) does not 
%   depend on component j of vector Y (hence DFDY(i,j) = 0).  Column vector 
%   OPTIONS.G is an efficient column grouping, as determined by COLGROUP(PATTERN).
%   
%   [DFDY,FAC,NFEVALS,NFCALLS] = ODENUMJAC(...) returns the number of values
%   F(FARGS{:}) computed while forming dFdY (NFEVALS) and the number of calls 
%   to the function F (NFCALLS). If F is not vectorized, NFCALLS equals NFEVALS. 
%
%   Although ODENUMJAC was developed specifically for the approximation of
%   partial derivatives when integrating a system of ODE's, it can be used
%   for other applications.  In particular, when the length of the vector
%   returned by F(...,Y,...) is different from the length of Y, DFDY is
%   rectangular.
%   
%   See also COLGROUP.

%   ODENUMJAC is an implementation of an exceptionally robust scheme due to
%   Salane for the approximation of partial derivatives when integrating 
%   a system of ODEs, Y' = F(T,Y). It is called when the ODE code has an
%   approximation Y at time T and is about to step to T+H.  The ODE code
%   controls the error in Y to be less than the absolute error tolerance
%   ATOL = THRESH.  Experience computing partial derivatives at previous
%   steps is recorded in FAC.  A sparse Jacobian is computed efficiently 
%   by using COLGROUP(S) to find groups of columns of DFDY that can be
%   approximated with a single call to function F.  COLGROUP tries two
%   schemes (first-fit and first-fit after reverse COLAMD ordering) and
%   returns the better grouping.
%   
%   D.E. Salane, "Adaptive Routines for Forming Jacobians Numerically",
%   SAND86-1319, Sandia National Laboratories, 1986.
%   
%   T.F. Coleman, B.S. Garbow, and J.J. More, Software for estimating
%   sparse Jacobian matrices, ACM Trans. Math. Software, 11(1984)
%   329-345.
%   
%   L.F. Shampine and M.W. Reichelt, The MATLAB ODE Suite, SIAM Journal on
%   Scientific Computing, 18-1, 1997.

%   Mark W. Reichelt and Lawrence F. Shampine, 3-28-94
%   Copyright 1984-2024 The MathWorks, Inc.

% Options
diffvar = options.diffvar;
vectvar = options.vectvars;
thresh  = options.thresh;
fac     = options.fac;

% Full or sparse Jacobian.
fullJacobian = true;
if isfield(options,'pattern')
    fullJacobian = false;
    S = options.pattern;
    g = options.g;
end

% The differentiation variable.
y  = Fargs{diffvar};

% Initialize.
Fvalue = Fvalue(:);
epsF = eps("like", Fvalue);
br = epsF .^ 0.875;
bl = epsF .^ 0.75;
bu = epsF .^ 0.25;
epsY = eps("like", y);
facmin = epsY .^ 0.78;
facmax = 0.1;
ny = length(y);
nF = length(Fvalue);
if isempty(fac)
    fac = repmat(sqrt(epsY), ny, 1);
end

% Select an increment del for a difference approximation to
% column j of dFdy.  The vector fac accounts for experience
% gained in previous calls to numjac.
yscale = max(abs(y),thresh);
del = (y + fac .* yscale) - y;
for j = 1:numel(del)
    if del(j) == 0
        while true
            if fac(j) < facmax
                fac(j) = min(100*fac(j),facmax);
                del(j) = (y(j) + fac(j)*yscale(j)) - y(j);
                if del(j)
                    break
                end
            else
                del(j) = thresh(j);
                break;
            end
        end
    end
end
if nF == ny
    del = (-1 + 2.*(Fvalue >= 0)) .* abs(del);  % keep del pointing into region
end

% Form a difference approximation to all columns of dFdy.
if fullJacobian                           % generate full matrix dFdy
    if isempty(vectvar)
        % non-vectorized
        Fdel = zeros(nF,ny);
        ydel = y;
        for j = 1:ny
            ydel_j = ydel(j);
            ydel(j) = ydel_j + del(j);
            Fargs{diffvar} = ydel;
            Fdel(:,j) = F(Fargs{:});
            ydel(j) = ydel_j;             % restore ydel to y
        end
        nfcalls = ny;                     % stats
    else
        % Expand arguments.  Need to preserve the original (non-expanded)
        % Fargs in case of correcting columns (done one column at a time).
        Fargs_expanded = Fargs;
        Fargs_expanded{diffvar} = y + diag(del);
        for i=1:length(vectvar)
            vectvar_i = vectvar(i);
            if vectvar_i ~= diffvar
                Fargs_expanded{vectvar_i} = repmat(Fargs{vectvar_i},1,ny);
            end
        end
        Fdel = F(Fargs_expanded{:});
        nfcalls = 1;                      % stats
    end
    nfevals = ny;                         % stats (at least one per loop)
    Fdiff = Fdel - Fvalue;
    dFdy = Fdiff ./ del.';
    [Difmax, Rowmax] = max(abs(Fdiff),[],1);
    % If Fdel is a column vector, then index is a scalar, so indexing is okay.
    absFdelRm = abs(Fdel((0:nF:(ny-1)*nF) + Rowmax));
else
    % sparse dFdy with structure S and column grouping g
    nzcols = find(g > 0); % g==0 for all-zero columns in sparsity pattern

    if isempty(nzcols)  % No columns requested -- early exit
        dFdy = sparse([],[],[],nF,ny);
        nfcalls = 0;                      % stats
        nfevals = 0;                      % stats
        return;
    end

    ng = max(g);
    ydel = repmat(y, 1, ng);

    i = (g(nzcols)-1)*ny + nzcols;
    ydel(i) = ydel(i) + del(nzcols);
    if isempty(vectvar)
        % non-vectorized
        Fdel = zeros(nF,ng);
        for j = 1:ng
            Fargs{diffvar} = ydel(:,j);
            Fdel(:,j) = F(Fargs{:});
        end
        nfcalls = ng;                     % stats
    else
        % Expand arguments.  Need to preserve the original (non-expanded)
        % Fargs in case of correcting columns (done one column at a time).
        Fargs_expanded = Fargs;
        Fargs_expanded{diffvar} = ydel;
        for i=1:length(vectvar)
            vectvar_i = vectvar(i);
            if vectvar_i ~= diffvar
                Fargs_expanded{vectvar_i} = repmat(Fargs{vectvar_i},1,ng);
            end
        end
        Fdel = F(Fargs_expanded{:});
        nfcalls = 1;                      % stats
    end
    nfevals = ng;                         % stats (at least one per column)
    Fdiff = Fdel - Fvalue;
    [i, j] = find(S);
    if ~isempty(i)
        i = i(:); % ensure that i is a column vector (S could be a row vector)
    end
    Fdiff = sparse(i,j,Fdiff((g(j)-1)*nF + i),nF,ny);
    dFdy = Fdiff ./ del.';
    [Difmax, Rowmax] = max(abs(Fdiff),[],1);
    Difmax = full(Difmax);
    % If ng==1, then Fdel is a column vector although index may be a row vector.
    absFdelRm = zeros(1,ny);
    absFdelRm(nzcols) = abs(Fdel((g(nzcols)-1)*nF + Rowmax(nzcols)'));
end

% Adjust fac for next call to numjac.
for k = 1:numel(absFdelRm)
    ydel = y;
    absFdelRm_k = absFdelRm(k);
    absFvalueRm_k = abs(Fvalue(Rowmax(k)));
    Difmax_k = Difmax(k);
    if (absFdelRm_k ~= 0 && absFvalueRm_k ~= 0) || Difmax_k == 0
        if ~fullJacobian && ~(g(k) > 0)   % refine only requested columns
            continue;
        end
        % If the difference in f values is so small that the column might be just
        % roundoff error, try a bigger increment.
        Fscale_k = max(absFdelRm_k,absFvalueRm_k);
        fac_k = fac(k);
        if Difmax_k <= br*Fscale_k
            y_k = y(k);
            tmpfac = min(sqrt(fac_k),facmax);
            del = (y_k + tmpfac*yscale(k)) - y_k;
            if (tmpfac ~= fac_k) && (del ~= 0)
                if nF == ny
                    if Fvalue(k) >= 0  % keep del pointing into region
                        del = abs(del);
                    else
                        del = -abs(del);
                    end
                end

                ydel(k) = y_k + del;
                Fargs{diffvar} = ydel;
                fdel = F(Fargs{:});
                nfevals = nfevals + 1;         % stats
                nfcalls = nfcalls + 1;         % stats
                ydel(k) = y_k;     %#ok<NASGU> % restore ydel to y
                fdiff = fdel(:) - Fvalue;
                tmp = fdiff ./ del;

                [difmax,rowmax] = max(abs(fdiff));
                norm_tmp = norm(tmp,inf);
                if tmpfac * norm_tmp >= norm(dFdy(:,k),inf)
                    % The new difference is more significant, so
                    % use the column computed with this increment.
                    if norm_tmp > 0  
                        % norm_tmp == 0 implies 
                        % tmp and dFdy(:,k) are both all zero vectors.
                        if fullJacobian
                            dFdy(:,k) = tmp;
                        else
                            i = find(S(:,k));
                            if ~isempty(i)
                                dFdy(i,k) = tmp(i);
                            end
                        end
                    end

                    % Adjust fac for the next call to numjac.
                    fscale = max(abs(fdel(rowmax)),abs(Fvalue(rowmax)));

                    if difmax <= bl*fscale
                        % The difference is small, so increase the increment.
                        fac(k) = min(10*tmpfac, facmax);
                    elseif difmax > bu*fscale
                        % The difference is large, so reduce the increment.
                        fac(k) = max(0.1*tmpfac, facmin);
                    else
                        fac(k) = tmpfac;
                    end
                end
            end
        elseif Difmax_k <= bl*Fscale_k
            fac(k) = min(10*fac_k, facmax);
        end
        if Difmax_k > bu*Fscale_k
            fac(k) = max(0.1*fac_k, facmin);
        end
    end
end
