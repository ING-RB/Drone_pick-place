function [yint,ypint] = ntrp3h(tint,t,y,tnew,ynew,yp,ypnew,idxNonNegative)
%NTRP3H  Interpolation helper function for BVP4C, DDE23, DDESD, and DDENSD.
%   YINT = NTRP3H(TINT,T,Y,TNEW,YNEW,YP,YPNEW) evaluates the Hermite cubic
%   interpolant at time TINT. TINT may be a scalar or a row vector.   
%   [YINT,YPINT] = NTRP3H(TINT,T,Y,TNEW,YNEW,YP,YPNEW) also returns the
%   derivative of the interpolating polynomial. 
%   
%   See also BVP4C, DDE23, DDESD, DDENSD, DEVAL.

%   Jacek Kierzenka and Lawrence F. Shampine
%   Copyright 1984-2023 The MathWorks, Inc.

if nargin < 8
    idxNonNegative = [];
end

h = tnew - t;
s = (tint - t)./h;
s2 = s .* s;
s3 = s .* s2;
slope = (ynew - y)./h; % y must be a column vector
c = 3*slope - 2*yp - ypnew; % yp must be a column vector
d = yp + ypnew - 2*slope;
yint = y + (h*d*s3 + h*c*s2 + h*yp*s);
if nargout > 1
    ypint = yp + (3*d*s2 + 2*c*s);
end

% Non-negative solution
if ~isempty(idxNonNegative)
    idx = find(yint(idxNonNegative,:)<0);
    if ~isempty(idx)
        w = yint(idxNonNegative,:);
        w(idx) = 0;
        yint(idxNonNegative,:) = w;
        if nargout > 1   % the derivative
            w = ypint(idxNonNegative,:);
            w(idx) = 0;
            ypint(idxNonNegative,:) = w;
        end
    end
end