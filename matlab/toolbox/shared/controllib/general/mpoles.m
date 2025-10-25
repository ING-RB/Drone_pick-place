function [mults, indx] = mpoles( p, mpoles_tol, reorder )
%MPOLES Identify repeated poles & their multiplicities.
%     [MULTS, IDX] = mpoles(P,TOL)
%        P:     the list of poles
%        TOL:   tolerance for checking when two poles
%                 are the "same" (default=1.0e-03)
%        REORDER: Sort the poles?  0=don't sort, 1=sort (default)
%        MULTS: list of pole multiplicities
%        IDX:   indices used to sort P
%     NOTE: this is a support function for RESIDUEZ.
%
%   Example:
%       input:  P = [1 3 1 2 1 2]
%       output: [MULTS, IDX] = mpoles(P)
%                   MULTS' = [1 1 2 1 2 3], IDX' = [2 4 6 1 3 5]
%                   P(IDX) = [3 2 2 1 1 1]
%       Thus, MULTS contains the exponent for each pole in a
%       partial fraction expansion.
%
%       There are times when the poles shouldn't be sorted in descending order,
%       such as when the poles correspond to given residuals from RESIDUEZ.  
%       In that case, set REORDER=0.  For example:
%       input:  P = [1 3 1 2 1 2]
%       output: [MULTS, IDX] = mpoles(P,[],0)
%                   MULTS' = [1 2 3 1 1 2], IDX' = [1 3 5 2 4 6]
%                   P(IDX) = [1 1 1 3 2 2]
%
%   Class support for input P:
%      float: double, single

%   Copyright 1984-2020 The MathWorks, Inc.
%#codegen

if nargin < 2 || isempty(mpoles_tol)
    tol = cast(1.0e-03,class(p));
else
    tol = mpoles_tol(1);
end
if nargin < 3 || isempty(reorder)
   doreorder = 1;
else
   doreorder = reorder(1);
end
Lp = length(p);
if doreorder 
   [~,indp] = sort(-abs(p(:))); %--work largest to smallest
   p = p(indp);
else
   indp=(1:Lp)';
end
mults = zeros(Lp,1,class(p));
indx  = zeros(Lp,1);
jkl   = zeros(Lp,1);
test  = zeros(Lp,1,'like',p);
ii = 1;
while Lp > 1
    gt0 = true;
    for k = 1:Lp
        test(k) = abs(p(1) - p(k));
        gt0 = gt0 & abs(p(k)) > 0;
    end
    if gt0
        thresh = tol*abs(p(1));
    else
        thresh = tol;
    end
    ndone = 0;
    for k = 1:Lp
        if test(k) < thresh
            ndone = ndone + 1;
            jkl(ndone) = k;
        end
    end
    for k = 1:ndone
        mults(ii+k-1) = k;
        indx(ii+k-1)  = indp(jkl(k));
    end
    % A pole has repeated ndone number of times, next we remove them from
    % being processed again.
    nLp = 0;
    idx = 1;
    for k = 1:ndone
        for m = idx:jkl(k)-1
            nLp = nLp + 1;
            p(nLp) = p(m);
            indp(nLp) = indp(m);
        end
        idx = jkl(k) + 1;
    end
    for m = idx:Lp
        nLp = nLp + 1;
        p(nLp) = p(m);
        indp(nLp) = indp(m);
    end
    Lp = nLp;
    ii = ii + ndone;
end
if Lp == 1
    mults(ii) = 1;
    indx(ii)  = indp(1);
end

% LocalWords:  MULTS ndone
