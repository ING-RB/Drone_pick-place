function [u,v] = dclothoidwp(x, y, varargin)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.DCLOTHOIDWP piecewise discrete clothoid data interpolation
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   [U,V] = matlabshared.tracking.internal.scenario.dclothoidwp(X,Y)
%   constructs a piecewise clothoid curve through the control points (X,Y)
%   upsampled by 1024 points.  If the first point (X(1),Y(1)) and the last
%   point (X(end),Y(end)) are equal, slope and curvature are preserved at
%   the endpoints.  Otherwise, endpoints have zero curvature.
%
%   [U,V] = matlabshared.tracking.internal.scenario.dclothoidwp(X,Y,DX,DY)
%   specifies the slope of the curve through the first and last point.  DX
%   and DY are two element row vectors, where (DX(1),DY(1)) corresponds to
%   the slope of the first point, (X(1),Y(1)), and (DX(2),DY(2))
%   corresponds to the slope at the last point, (X(end),Y(end)).
%   If either slope is NaN, then zero curvature is used instead.
%
%   [U,V] = matlabshared.tracking.internal.scenario.dclothoidwp(...,ITER)
%   upsamples by 2^ITER points.
%
%   matlabshared.tracking.internal.scenario.dclothoidwp(...) without output
%   arguments plots the piecewise clothoid
%
%   % Example 1:
%   %   Construct a piecewise clothoid curve through three points whose
%   %   endpoints have zero curvature.
%   x = [0 25 25];
%   y = [0 0 25];
%   matlabshared.tracking.internal.scenario.dclothoidwp(x,y)
%
%   % Example 2:
%   %   Connect the endpoints to create a closed loop by setting the
%   %   starting waypoint to the final waypoint.  Three points will define
%   %   a circle if they are far enough apart.
%   x = [0 25 25 0];
%   y = [0 0 25  0];
%   matlabshared.tracking.internal.scenario.dclothoidwp(x,y)
%
%   % Example 3:
%   %   Construct a curve through three points with zero curvature at the
%   %   endpoints.  Specify the initial and final tangent vectors both
%   %   oriented directly upwards
%   x = [0 25 25];
%   y = [0 0 25 ];
%   dx = [0 0];
%   dy = [1 1];
%   matlabshared.tracking.internal.scenario.dclothoidwp(x,y,dx,dy)
%
%   % Example 4:
%   %   Construct a curve through three points with zero curvature at the
%   %   endpoints.  Specify the initial tangent pointing upwards, and the
%   %   final tangent pointing downwards
%   x = [0 25 25];
%   y = [0 0 25];
%   dx = [0  0];
%   dy = [1 -1];
%   matlabshared.tracking.internal.scenario.dclothoidwp(x,y,dx,dy)
%
%   See Also SPLINE.

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

% Reference:
%    Curvature-controlled curve editing using piecewise clothoid curves
%    S. Havemann, J. Edelsbrunner, P. Wagner, D. Fellner.
%    DOI: 10.1016/j.cag.2014.05.015

if mod(numel(varargin),2)==1
    iter = varargin{end};
else
    iter = 10;
end

z = complex(x,y);

if nargin<4
    [r,s] = cloth(iter, z);
else
    [r,s] = cloth(iter, z, complex(varargin{1:2}));
end

if nargout==0
    plot(r,s,'-',x,y,'o');
    axis equal
elseif isempty(coder.target)
    [u,v] = packageMATLAB(iscolumn(x),r,s);
else
    [u,v] = packageCodegen(iscolumn(x),r,s,1+(2^iter)*(length(x)-1));
end


function [u,v] = packageMATLAB(iscol,r,s)
if iscol
    u = reshape(r,numel(r),1);
    v = reshape(s,numel(s),1);
else
    u = r;
    v = s;
end


function [u,v] = packageCodegen(iscol,r,s,n)
if iscol
    u = zeros(n,1);
    v = zeros(n,1);
else
    u = zeros(1,n);
    v = zeros(1,n);
end
u(1:n) = r(1:n);
v(1:n) = s(1:n);


function [r,s] = cloth(iter, z, varargin)
nz = numel(z);
z = reshape(z,1,nz);

if ~isempty(varargin)
    args = {reshape(varargin{1},1,numel(varargin{1}))};
else
    args = {};
end

if isempty(coder.target)
    Zout = z;
    for i=1:iter
        Zout = insert(Zout,args{:});
        Zout = optimize(Zout,z,args{:});
        Zout = optimize(Zout,z,args{:});
        Zout = optimize(Zout,z,args{:});
    end
else
    nmax = 1 + (length(z)-1)*2^iter;
    Zout = zeros(1,nmax,'like',z);
    m = numel(z);
    Zout(1:m) = z;
    for i=1:iter
        mnew = 2*m-1;
        Zout(1:mnew) = insertCodegen(Zout,m,nmax,args{:});
        Zout(1:mnew) = optimize(Zout(1:mnew),z,args{:});
        Zout(1:mnew) = optimize(Zout(1:mnew),z,args{:});
        Zout(1:mnew) = optimize(Zout(1:mnew),z,args{:});
        m = mnew;
    end
end
r = real(Zout);
s = imag(Zout);


function Zout = insert(zorig,varargin)
% pad with endpoints
[zleft, zright] = endpointpadding(zorig,zorig,varargin{:});
z = [zleft zorig zright];

% compute insertion points
dz = diff(z);
l = abs(dz);
alpha = angle(conj(dz(2:end)).*dz(1:end-1));
if ~isempty(varargin)
    tangents = varargin{1};
    if ~isnan(tangents(1))
        l(1) = 0;
        alpha(1) = angle(conj(dz(2)).*tangents(1));
    end
    
    if ~isnan(tangents(2))
        l(end) = 0;
        alpha(end) = angle(conj(tangents(end)).*dz(end-1));
    end
end

znew = midcurve(z(2:end-2), dz(2:end-1), l(1:end-2), l(2:end-1), l(3:end), alpha(1:end-1), alpha(2:end));

% insert new points in between every point of the original.
Zout = zeros(1, 2*numel(zorig)-1, 'like', zorig);
Zout(1:2:2*numel(zorig)-1) = zorig;
Zout(2:2:2*numel(znew)+1) = znew;

function Zout = insertCodegen(zorig,m,nmax,varargin)
% pad with endpoints
[zleft, zright] = endpointpadding(zorig(1:m),zorig(1:m),varargin{:});
z = [zleft zorig(1:m) zright];

% compute insertion points
dz = diff(z);
l = abs(dz);
alpha = angle(conj(dz(2:end)).*dz(1:end-1));
if ~isempty(varargin)
    tangents = varargin{1};
    if ~isnan(tangents(1))
        l(1) = 0;
        alpha(1) = angle(conj(dz(2)).*tangents(1));
    end
    
    if ~isnan(tangents(2))
        l(end) = 0;
        alpha(end) = angle(conj(tangents(end)).*dz(end-1));
    end
end

znew = midcurve(z(2:end-2), dz(2:end-1), l(1:end-2), l(2:end-1), l(3:end), alpha(1:end-1), alpha(2:end));

% provide hint for MATLAB Coder
Zout = zeros(1,nmax,'like', zorig);

% insert new points in between every point of the original.
Zout(1:2:2*m-1) = zorig(1:m);
Zout(2:2:2*numel(znew)+1) = znew;
Zout = Zout(1:2*m-1);

function Zout = optimize(zcurrent,zorig,varargin)
% pad with endpoints
[zleft, zright] = endpointpadding(zcurrent,zorig,varargin{:});
z = [zleft zcurrent zright];

d1 = diff(z);
l1 = abs(d1);
d2 = z(3:end)-z(1:end-2);
alpha = angle(conj(d2(2:end-1)).*d1(1:end-3));
beta = angle(conj(d1(4:end)).*d2(2:end-1));
if ~isempty(varargin)
    tangents = varargin{1};
    if ~isnan(tangents(1))
        l1(1) = 0;
        alpha(1) = angle(conj(d2(2)).*tangents(1));
    end
    if ~isnan(tangents(2))
        l1(end) = 0;
        beta(end) = angle(conj(tangents(end)).*d2(end-1));
    end
end

zcorr = midcurve(zcurrent(1:end-2),d2(2:end-1),l1(1:end-3),l1(2:end-2)+l1(3:end-1),l1(4:end),alpha,beta);

Zout = [zorig(1) zcorr zorig(end)];

nseg = (numel(zcurrent)-numel(zorig))/(numel(zorig)-1);
Zout(1:nseg+1:end) = zorig;
  
function [zleft, zright] = endpointpadding(zcurrent,zorig,varargin)
% set extension factor
f = 100;
if ~isempty(varargin)
    arg = varargin{1};
    if isnan(arg(1))
        zleft = zcurrent(1) + f*(zcurrent(1)-zcurrent(2));
    else
        zleft = NaN;
    end
    
    if isnan(arg(2))
        zright = zcurrent(end) + f*(zcurrent(end)-zcurrent(end-1));
    else
        zright = NaN;
    end
elseif zorig(1)==zorig(end) && numel(zorig)>2
    zleft = zcurrent(end-1);
    zright = zcurrent(2);
else
    zleft = zcurrent(1)+f*(zcurrent(1)-zcurrent(2));
    zright = zcurrent(end)+f*(zcurrent(end)-zcurrent(end-1));
end

function Pc = midcurve(Pb, Vbd, Lab, Lbd, Lde, alpha, beta)
% compute point C from point B; vector BD; lengths ab, bd, and de,
% respectively and exterior angles alpha and beta.  Point C lies
% a distance tan(gamma) along the bisector of BD and is chosen so
% curvature at C is the arithmetic mean of the curvature at B and D.
% For faster convergence, length BD may be set to length BC + length CD if known.
%                 C
%              .  |   .
%           .     |       .
%   ---- B--------+---------D -----
% alpha /                    \ beta
%      /                      \
%     A                        E

a = 2*Lde+Lbd;
b = 2*Lab+Lbd;
gamma = Lbd.*(alpha.*a+beta.*b)./(2*(a.*b)+Lbd.*(a+b));
Pc = Pb + (1+1i*tan(gamma)).*Vbd/2;
Pc(Lbd==0) = Pb(Lbd==0);
