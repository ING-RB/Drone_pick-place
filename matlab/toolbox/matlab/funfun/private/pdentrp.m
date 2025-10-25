function [U,Ux] = pdentrp(singular,m,xL,uL,xR,uR,xout)
%PDENTRP  Interpolation helper function for PDEPE.
%   [U,UX] = PDENTRP(M,XL,UL,XR,UR,XOUT) uses solution values UL at XL and UR at XR
%   for successive mesh points XL < XR to interpolate the solution values U and
%   the partial derivative with respect to x, UX, at arguments XOUT(i) with
%   XL <= XOUT(i) <= XR.  UL and UR are column vectors. Column i of the output
%   arrays U, UX correspond to XOUT(i).
%
%   See also PDEPE, PDEVAL, PDEODES.

%   Lawrence F. Shampine and Jacek Kierzenka
%   Copyright 1984-2023 The MathWorks, Inc.

xout = xout(:).';
nout = length(xout);

uRL = uR - uL;

% Use singular interpolant on all subintervals.
if singular
    U  = uL + uRL*((xout .^ 2 - xL^2) / (xR^2 - xL^2));
    Ux =      uRL*(2*xout / (xR^2 - xL^2));
else
    if m == 0
        U  = uL + uRL*( (xout - xL) / (xR - xL));
        Ux =      uRL*(ones(1,nout) / (xR - xL));
    elseif m == 1
        U  = uL + uRL*(log(xout/xL) / log(xR/xL));
        Ux =      uRL*( (1 ./ xout) / log(xR/xL));
    elseif m == 2
        U  = uL + uRL*((xR ./ xout) .* ((xout - xL)/(xR - xL)));
        Ux =      uRL*((xR ./ xout) .* (xL ./ xout)/(xR - xL));
    end
end

