function yi = TensorCubicLoopBody(y,xi,yi,x)

%   Copyright 2022 The MathWorks, Inc.

%#codegen
    
    
    coder.inline('always');
    NAN = coder.const(coder.internal.interpolate.interpNaN(yi));

    minx = x(1);
    secx = x(2);
    penx = x(end-1);
    maxx = x(end);
    nx = coder.internal.indexInt(numel(x));
    h = x(2) - x(1);
    ONE = coder.const(coder.internal.indexInt(1));
    nyrows = coder.internal.indexInt(size(y,1));
    nycols = coder.internal.indexInt(coder.internal.prodsize(y,'above',ONE));


    for k = 1:coder.internal.indexInt(numel(xi))
        if isnan(xi(k))
            for j = 0:nycols-1
                yi((k-1)*nycols + j + 1) = NAN;
            end
        elseif xi(k) >= minx && xi(k) <= maxx
            [n,c0,c1,c2,c3] = cubicConvCoeffs(xi(k),minx,secx,penx,nx,x,h);
            if n < 2
                for j = 0:nycols-1
                    yi((k-1)*nycols + j + 1) = cubicConvFirst(y,n + j*nyrows,c0,c1,c2,c3);
                end
            elseif n < nyrows - 1
                for j = 0:nycols-1
                    yi((k-1)*nycols + j + 1) = cubicConvMiddle(y,n + j*nyrows,c0,c1,c2,c3);
                end
            else
                for j = 0:nycols-1
                    yi((k-1)*nycols + j + 1) = cubicConvLast(y,n + j*nyrows,c0,c1,c2,c3);
                end
            end
        else
            [n,c0,c1,c2,c3] = cubicConvCoeffs(xi(k),minx,secx,penx,nx,x,h);
            if n < 2
                for j = 0:nycols-1
                    yi((k-1)*nycols + j + 1) = cubicConvFirst(y,n + j*nyrows,c0,c1,c2,c3);
                end
            else
                for j = 0:nycols-1
                    yi((k-1)*nycols + j + 1) = cubicConvLast(y,n + j*nyrows,c0,c1,c2,c3);
                end
            end
        end
    end

end
%--------------------------------------------------------------------------

function [n,c0,c1,c2,c3] = cubicConvCoeffs(xik,minx,secx,penx,nx,x,h)
% Cubic Convolution helper function to calculate the piece n and the
% coefficients c0, c1, c2, and c3.
    coder.inline('always');
    if xik < secx
        n = coder.internal.indexInt(1);
        s = (xik - minx)/h;
    elseif xik >= penx
        n = nx - 1;
        s = (xik - penx)/h;
    else
        n = coder.internal.indexInt(1 + floor((xik - minx)/h));
        if xik >= x(n + 1)
            % This can occur when xik falls on a node but due to round-off
            % error in the value presented to FLOOR, the n-th segment
            % (as n is calculated above) turns out to be to the left of the
            % node rather than to its right. Select the segment to the
            % right.
            n = n + 1;
        end
        s = (xik - x(n))/h;
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
