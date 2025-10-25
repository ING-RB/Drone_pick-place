function f = univarKDE(tx, txi, iscdf, bw, weight, kernel, cutoff, bounds, doNorm, useReflection)
%UNIVARKDE Computing the KDE estimate for a set of data
%   F = UNIVARKDE(TX, TXI, ISCDF, BW, WEIGHT, KERNEL, CUTOFF, BOUNDS)
%   computes the KDE of a univariate set of double/single data TX at
%   double/single vector TXI using the scalar double/single bandwidth BW,
%   and kernel function KERNEL. WEIGHT is a double/single vector of observation 
%   weights for TX. CUTOFF is the cutoff point for the kernel. BOUNDS are a 
%   set of lower and upper bound within which TX lives. ISCDF indicates if 
%   the CDF or PDF are to be computed. If ISCDF is false, F is an estimate 
%   of the PDF of TX at TXI. If ISCDF is true, F is an estimate of the CDF
%   instead.
%
%   F = UNIVARKDE(TX, TXI, ISCDF, BW, WEIGHT, KERNEL, CUTOFF, BOUNDS,
%   DONORM, USEREFLECTION) takes in an additional logical, DONORM,
%   indicating if the resultant PDF/CDF should be normalized. If true, a
%   PDF F is divided by BW, and a CDF F is capped at 1. If false, neither
%   of these is done. This is useful for codepaths where the unnormalized
%   values are needed first in computation. USEREFLECTION is a logical
%   indicating if the boundary correction method is reflection or not.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2023 The MathWorks, Inc.
if nargin < 9
    % Assume reflection is used rather than log transformation for bounded
    % data, and assume we should normalize the PDF (if we are to compute
    % the PDF)
    doNorm = true;
    useReflection = true;
end

m = length(txi);
n = length(tx);
blocksize = matlab.internal.math.getBlockSizeForKDE(tx);
L = bounds(1);
U = bounds(2);

% Determine which boundary correction and which function is being computed
% Either it uses reflection, in which case we correct here, or it uses a
% log transformation, in which case that transformation-untransformation is
% handled outside of this function
reflectPDF = useReflection && ~iscdf;
reflectCDF = useReflection && iscdf;
if n*m<=blocksize && ~iscdf
    % For small problems, compute kernel density estimate in one operation
    ftemp = ones(n,m,"like",txi);
    z = (txi' - tx) / bw;
    fz = feval(kernel, z);
    if ~isequal(size(fz), size(z))
        error(message('MATLAB:kde:KernelFcnIncorrectOutputSize'));
    end
    if reflectPDF
        % Add rows to columns to get full matrix
        zleft = (txi' + tx - 2*L) / bw;
        zright = (txi' + tx - 2*U) / bw;
        f = fz + feval(kernel, zleft) + feval(kernel, zright);
    else
        f = fz;
    end
    f = weight * (ftemp.*f);
else
    % For large problems or computing CDF, try more selective looping
    % First sort y and carry along weights
    [tx,idx] = sort(tx);
    weight = weight(idx);

    % Loop over evaluation points
    f = zeros(1,m,"like",txi);

    if isinf(cutoff)
        if reflectCDF
            fc = compute_CDFreduction(L,U,bw,Inf,n,tx,weight,kernel);
        end
        for k=1:m
            % Sum contributions from all
            z = (txi(k)-tx)/bw;
            fz = feval(kernel, z);
            if ~isequal(size(fz), size(z))
                error(message('MATLAB:kde:KernelFcnIncorrectOutputSize'));
            end
            if reflectPDF
                zleft = (txi(k)+tx-2*L)/bw;
                zright = (txi(k)+tx-2*U)/bw;
                f(k) = weight * (fz+feval(kernel,zleft)+feval(kernel,zright));
            elseif reflectCDF
                zleft = (txi(k)+tx-2*L)/bw;
                zright = (txi(k)+tx-2*U)/bw;
                fk = weight * (fz+feval(kernel,zleft)+feval(kernel,zright));
                f(k) = fk - fc;
            else
                f(k) = weight * fz;
            end
        end           
    else
        % Sort evaluation points and remember their indices
        [stxi,idx] = sort(txi);

        jstart = 1;       % lowest nearby point
        jend = 1;         % highest nearby point
        halfwidth = cutoff*bw;
        
        % Calculate reduction for reflectionCDF
        if reflectCDF
            fc = compute_CDFreduction(L,U,bw,halfwidth,n,tx,weight,kernel);
        end
        
        for k=1:m
            % Find nearby data points for current evaluation point
            lo = stxi(k) - halfwidth;
            jstart = iFindNextGreaterOrEqual(tx, lo, jstart, n);
            hi = stxi(k) + halfwidth;
            
            jend = max(jend,jstart);
            jend = iFindNextGreaterThan(tx, hi, jend, n);

            nearby = jstart:jend;

            % Sum contributions from these points
            z = (stxi(k)-tx(nearby))/bw;
            fz = feval(kernel,z);
            if ~isequal(size(fz), size(z))
                error(message('MATLAB:kde:KernelFcnIncorrectOutputSize'));
            end
            if reflectPDF
                zleft = (stxi(k)+tx(nearby)-2*L)/bw;
                zright = (stxi(k)+tx(nearby)-2*U)/bw;
                fk = weight(nearby) * (fz+feval(kernel,zleft)+feval(kernel,zright));
            elseif reflectCDF
                zleft = (stxi(k)+tx(nearby)-2*L)/bw;
                zright = (stxi(k)+tx(nearby)-2*U)/bw;
                fk = weight(nearby) * fz;
                fk = fk + sum(weight(1:jstart-1));
                if jstart == 1
                    fk = fk + weight(nearby) * feval(kernel,zleft);
                    fk = fk + sum(weight(jend+1:end));
                else
                    fk = fk + sum(weight);
                end
                if jend == n
                    fk = fk + weight(nearby) * feval(kernel,zright);
                end
                fk = fk - fc;
            elseif ~iscdf
                fk = weight(nearby) * fz;
            else
                fk = weight(nearby) * fz;
                fk = fk + sum(weight(1:jstart-1));
            end
            f(k) = fk;
        end

        % Restore original x order
        f(idx) = f;
    end
end

if doNorm
    if iscdf
        % Don't normalize, but do ensure that the CDF is capped at 1, which
        % may be exceeded slightly due to roundoff.
        f = min(f, 1);
    else
        f = f ./ bw;
    end

    % Can't be less than 0, cap at 0 to protect from roundoff
    f = max(f, 0);
end
end

function fc = compute_CDFreduction(L,U,u,halfwidth,n,ty,weight,kernel)
jstart = 1;
jend = 1;
hi = L + halfwidth;
jend = iFindNextGreaterThan(ty, hi, jend, n);
nearby = jstart:jend;
z = (L - ty(nearby))/u;
zleft = (ty(nearby) - L)/u;
zright = (L + ty(nearby) -2*U)/u;
if jend == n
    fc = weight(nearby) * (feval(kernel,z)+feval(kernel,zleft)+feval(kernel,zright));
else
    fc = weight(nearby) * (feval(kernel,z)+feval(kernel,zleft));
    fc = fc + sum(weight(jend+1:end));
end
end

function idx = iFindNextGreaterOrEqual(val, threshold, startIdx, maxIdx)
% Helper to find the next entry in a vector that is above a threshold.

% Objects that overload indexing (i.e., gpuArray) will be slow to iterate 
% over elements.
slowIndexing = isobject(val);

if slowIndexing
    idx = iFindNextVectorized(val(startIdx:maxIdx)>=threshold, startIdx);
else
    idx = startIdx;
    while(val(idx)<threshold && idx<maxIdx)
        idx = idx+1;
    end
end
end

function idx = iFindNextGreaterThan(val, threshold, startIdx, maxIdx)
% Helper to find the next entry in a vector that is above a threshold.

% Objects that overload indexing (i.e., gpuArray) will be slow to iterate 
% over elements.
slowIndexing = isobject(val);

if slowIndexing
    idx = iFindNextVectorized(val(startIdx:maxIdx)>threshold, startIdx);
else
    idx = startIdx;
    while(val(idx)<=threshold && idx<maxIdx)
        idx = idx+1;
    end
end
end

function idx = iFindNextVectorized(val, firstIdx)
idx = find(val, 1, "first");
if isempty(idx)
    idx = numel(val);
end
idx = firstIdx + idx - 1;
end
