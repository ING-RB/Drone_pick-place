function yi = interp1cubicConvLoopBody(y,nyrows,nycols,xi,yi,nxi,k, ...
    extrapByMethod,minx,secx,penx,maxx,nx,varargin)
% Loop body for Cubic Convolution Interpolation. This is called in
% vectorized form:
%     yi = cubicConvLoopBody(...,nycols,xi,yi,nxi,k,...)
% in the general case. When using PARFOR, however, it is called in a
% scalarized way:
%     yi(k) = cubicConvLoopBody(...,1,xi(k),yi(k),1,1,...).

%   Copyright 2022 The MathWorks, Inc.

%#codegen
    
    coder.internal.prefer_const(nyrows,nycols,nxi,k,nyrows);
    coder.inline('always');
    NAN = coder.const(coder.internal.interpolate.interpNaN(yi));
    if isnan(xi(k))
        for j = 0:nycols-1
            yi(k + j*nxi) = NAN;
        end
    elseif xi(k) >= minx && xi(k) <= maxx
        [n,c0,c1,c2,c3] = cubicConvCoeffs(xi(k),minx,secx,penx,nx,varargin{:});
        if n < 2
            for j = 0:nycols-1
                yi(k + j*nxi) = cubicConvFirst(y,n + j*nyrows,c0,c1,c2,c3);
            end
        elseif n < nyrows - 1
            for j = 0:nycols-1
                yi(k + j*nxi) = cubicConvMiddle(y,n + j*nyrows,c0,c1,c2,c3);
            end
        else
            for j = 0:nycols-1
                yi(k + j*nxi) = cubicConvLast(y,n + j*nyrows,c0,c1,c2,c3);
            end
        end
    elseif extrapByMethod
        [n,c0,c1,c2,c3] = cubicConvCoeffs(xi(k),minx,secx,penx,nx,varargin{:});
        if n < 2
            for j = 0:nycols-1
                yi(k + j*nxi) = cubicConvFirst(y,n + j*nyrows,c0,c1,c2,c3);
            end
        else
            for j = 0:nycols-1
                yi(k + j*nxi) = cubicConvLast(y,n + j*nyrows,c0,c1,c2,c3);
            end
        end
    end
end
%--------------------------------------------------------------------------

function [n,c0,c1,c2,c3] = cubicConvCoeffs(xik,minx,secx,penx,nx,varargin)
% Cubic Convolution helper function to calculate the piece n and the
% coefficients c0, c1, c2, and c3.
    coder.inline('always');
    xNotSupplied = nargin < 7;
    if xik < secx
        n = coder.internal.indexInt(1);
        if xNotSupplied
            s = xik - minx;
        else
            s = (xik - minx)/varargin{2};
        end
    elseif xik >= penx
        n = nx - 1;
        if xNotSupplied
            s = xik - penx;
        else
            s = (xik - penx)/varargin{2};
        end
    else
        if xNotSupplied
            xikf = floor(xik);
            n = coder.internal.indexInt(xikf);
            s = xik - xikf;
        else
            n = coder.internal.indexInt(1 + floor((xik - minx)/varargin{2}));
            if xik >= varargin{1}(n + 1)
                % This can occur when xik falls on a node but due to round-off
                % error in the value presented to FLOOR, the n-th segment
                % (as n is calculated above) turns out to be to the left of the
                % node rather than to its right. Select the segment to the
                % right.
                n = n + 1;
            end
            s = (xik - varargin{1}(n))/varargin{2};
        end
    end
    sd2 = s/2;
    ssd2 = s*sd2;
    s3m4 = 3*s - 4;
    c0 = -s*(s*(sd2 - 1) + 0.5);   % (  -s^3 + 2*s^2 - s    )/2;
    c1 = ssd2*(s3m4 - 1) + 1;      % ( 3*s^3 - 5*s^2     + 2)/2;
    c2 = -sd2*(s*s3m4 - 1);        % (-3*s^3 + 4*s^2 + s    )/2;
    c3 = ssd2*(s - 1);             % (   s^3 -   s^2        )/2;
end
%--------------------------------------------------------------------------

function yi = cubicConvFirst(y,n,c0,c1,c2,c3)
% Cubic Convolution helper function to evaluate the interpolant on the
% first interval.
coder.inline('always');
y1 = y(n);
y2 = y(n + 1);
y3 = y(n + 2);
y0 = 3*y1 - 3*y2 + y3;
yi = c0*y0 + c1*y1 + c2*y2 + c3*y3;
end
%--------------------------------------------------------------------------

function yi = cubicConvMiddle(y,n,c0,c1,c2,c3)
% Cubic Convolution helper function to evaluate the interpolant on the
% middle intervals.
coder.inline('always');
y0 = y(n - 1);
y1 = y(n);
y2 = y(n + 1);
y3 = y(n + 2);
yi = c0*y0 + c1*y1 + c2*y2 + c3*y3;
end
%--------------------------------------------------------------------------

function yi = cubicConvLast(y,n,c0,c1,c2,c3)
% Cubic Convolution helper function to evaluate the interpolant on the
% last interval.
coder.inline('always');
y0 = y(n - 1);
y1 = y(n);
y2 = y(n + 1);
y3 = 3*y2 - 3*y1 + y0;
yi = c0*y0 + c1*y1 + c2*y2 + c3*y3;
end
