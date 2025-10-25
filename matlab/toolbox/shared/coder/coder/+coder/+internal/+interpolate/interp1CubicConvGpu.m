function yi = interp1CubicConvGpu(y,nyrows,nycols,xi,yi,varargin)
% GPU specific implementation for 'cubic' method.
% Perform cubic interpolation on (x,y). The algorithm follows MATLAB coder
% implementation. Some loops are rewritten to generate optimized GPU code.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.gpu.kernelfun;
coder.inline('always');
coder.internal.prefer_const(nyrows,nycols);
NAN = coder.const(coder.internal.interpolate.interpNaN(yi));
nx = nyrows;
if nx < 3
    yi = interp1LinearGpu(y,nyrows,nycols,xi,yi,false,varargin{1:end-1});
    return
end
xNotSupplied = nargin < 6;
if xNotSupplied
    minx = cast(1,'like',xi);
    secx = cast(2,'like',xi);
    penx = cast(nx - 1,'like',xi);
    maxx = cast(nx,'like',xi);
else
    minx = varargin{1}(1);
    secx = varargin{1}(2);
    penx = varargin{1}(end - 1);
    maxx = varargin{1}(end);
end
nxi = coder.internal.indexInt(numel(xi));

% Slope calculation for 'cubic' method
% Calculate the piece m and the coefficients c0, c1, c2, and c3.
m = coder.internal.indexInt(zeros(1,nxi));
c0 = zeros(1,nxi,'like',xi);
c1 = zeros(1,nxi,'like',xi);
c2 = zeros(1,nxi,'like',xi);
c3 = zeros(1,nxi,'like',xi);
for k = 1:nxi
    xik = xi(k);
    if ~isnan(xik)
        if xi(k) >= minx && xi(k) <= maxx
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
                    n = coder.internal.indexInt(1 + floor((xik - minx)/...
                        varargin{2}));
                    s = (xik - varargin{1}(n))/varargin{2};
                end
            end
            m(k) = n;
            sd2 = s/2;
            ssd2 = s*sd2;
            s3m4 = 3*s - 4;
            c0(k) = -s*(s*(sd2 - 1) + 0.5);
            c1(k) = ssd2*(s3m4 - 1) + 1;
            c2(k) = -sd2*(s*s3m4 - 1);
            c3(k) = ssd2*(s - 1);
        end
    end
end
% Interpolation main operation for 'cubic' method
for j = 0:nycols-1
    for k = 1:nxi
        xik = xi(k);
        if isnan(xik)
            yi(k + j*nxi) = NAN;
        elseif xi(k) >= minx && xi(k) <= maxx
            if m(k) < 2
                n = m(k) + j*nyrows;
                % Evaluate interpolant on the first interval.
                y0 = 3*y(n) - 3*y(n + 1) + y(n + 2);
                yi(k + j*nxi) = c0(k)*y0 + c1(k)*y(n)...
                    + c2(k)*y(n + 1) + c3(k)*y(n + 2);
            elseif m(k) < nyrows - 1
                n = m(k) + j*nyrows;
                % Evaluate the interpolant on the middle intervals.
                yi(k + j*nxi) = c0(k)*y(n - 1) + c1(k)*y(n)...
                    + c2(k)*y(n + 1) + c3(k)*y(n + 2);
            else
                n = m(k) + j*nyrows;
                % Evaluate interpolant on the last interval.
                y3 = 3*y(n + 1) - 3*y(n) + y(n - 1);
                yi(k + j*nxi) = c0(k)*y(n - 1) + c1(k)*y(n)...
                    + c2(k)*y(n + 1) + c3(k)*y3;
            end
        end
    end
end