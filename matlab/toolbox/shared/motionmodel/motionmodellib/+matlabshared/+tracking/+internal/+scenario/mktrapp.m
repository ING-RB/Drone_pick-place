function [pp, segt] = mktrapp(d, v, Jc, entryTime, waitTimes)
% MATLABSHARED.TRACKING.INTERNAL.SCENARIO.MKTRAPP - make trapezodal acceleration piecewise polynomial
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   [PP, SEGT] = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.MKTRAPP(D, V, Jc, ENTRYTIME, WAITTIMES)
%   returns a piecewise polynomial, PP, and segment durations SEGT
%   corresponding to a one-dimensional set of distances, D, velocities, V, 
%   constant jerk limit, Jc, desired starting time, ENTRYTIME, and wait
%   durations WAITTIMES.

% Copyright 2022 The MathWorks, Inc.

%#codegen

% Speed may be specified using negative values for reverse movement.
v = abs(v);
accel = getAccelerations(v, d);

numSegs = length(d);
t = zeros(4*numSegs,1);
coeffs = zeros(4*numSegs-1,4);
pndx = 0;
accumDistance = 0;
segt = zeros(numSegs,1);

for kndx = 1:numSegs
    currentDist = d(kndx);
    [t1,t2,t3,v0,a0,j0,j2] = mktrapseg(currentDist, v(kndx), accel(kndx), v(kndx+1), accel(kndx+1), Jc);
    d0 = accumDistance;
    d1 = d0 + v0.*t1 + a0/2.*t1.*t1 + j0/6.*t1.*t1.*t1;
    v1 = v0 + a0.*t1 + j0/2.*t1.*t1;
    a1 = a0 + j0.*t1;
    d2 = d1 + v1.*t2 + a1/2.*t2.^2;
    v2 = v1 + a1.*t2;
    a2 = a1;
    wt = waitTimes(kndx);
    if wt < 1e-12
        t(pndx+1:pndx+3) = [t1 t2 t3];
        coeffs(pndx+1:pndx+3,:) = [j0/6 a0/2 v0  d0;
            0    a1/2 v1 d1;
            j2/6 a2/2 v2 d2];
        pndx = pndx + 3;
    else
        t(pndx+1:pndx+4) = [wt t1 t2 t3];
        coeffs(pndx+1:pndx+4,:) = [0 0 0 d0;
            j0/6 a0/2 v0  d0;
            0    a1/2 v1 d1;
            j2/6 a2/2 v2 d2];
        pndx = pndx + 4;
    end
    accumDistance = accumDistance + currentDist;
    segt(kndx) = t1 + t2 + t3;
end

if coder.target('MATLAB') || coder.internal.eml_option_eq('UseMalloc','VariableSizeArrays')
    % construct polynomial
    breaks = cumsum([entryTime; t(1:pndx)]');
    pp = mkpp(breaks, coeffs(1:pndx,:));
else
    % pad with penultimate break and its coefficients
    breaks = zeros(4*numSegs,1);
    breaks(1:pndx+1) = cumsum([entryTime; t(1:pndx)]);
    breaks(pndx+2:end-1) = breaks(pndx+1);
    breaks(end) = t(pndx+1);
    coeffs(pndx+1:end,:) = coeffs(pndx,:);
    pp = mkpp(breaks,coeffs);
end


function accel = getAccelerations(v, hl)
% Return accelerations for each segment.
vi = v(1:end-1);
vf = v(2:end);
a = (vf - vi) .* (vf + vi) ./ (2*hl);
accel = zeros(size(v));
for kndx = 2:length(accel)-1
    constVel = v(kndx) == v(kndx+1) || v(kndx) == v(kndx-1);
    extrmVel = v(kndx-1) < v(kndx) && v(kndx) > v(kndx+1) ...
            || v(kndx-1) > v(kndx) && v(kndx) < v(kndx+1);
    if constVel || extrmVel
        accel(kndx) = 0;
    else
        totDist = hl(kndx-1) + hl(kndx);
        w1 = hl(kndx-1)/totDist;
        w2 = hl(kndx)/totDist;
        accel(kndx) = w1*a(kndx-1) + w2*a(kndx);
    end
end

function [t1, t2, t3] = timesolve(d3, v0, a0, j0, v3, a3, j2)
%TIMESOLVE Solve for each durations of the trapzoidal trajectory
%   t1 is the duration of the initial constant jerk leg (j0)
%   t2 is the duration of the constant acceleration leg (a1=a2)
%   t3 is the duration of the final constant jerk leg   (j2)
%
%      a3   |                      ....|
%     a1=a2 |     .. +--------+....    |
%           |   ..   |        |        |
%           | ..     |        |        |
%      a0   +--------+--------+--------+
%      t:   |  <t1>  |  <t2>  |  <t3>  |
%
%      d:   0        d1       d2       d3
%      v:  v0        v1       v2       v3
%      a:  a0        |<a1==a2>|        a3
%      j:   |  <j0>  |  0     |  <j2>  |
A = j0^2*j2^2 - j0^4;
B = 4*a0*j0*j2^2 - 4*a0*j0^3;
C = - 6*a0^2*j0^2 + 6*a3^2*j0^2 - 12*v3*j0^2*j2 + 12*v0*j0*j2^2;
D = - 4*j0*a0^3 + 12*j0*a0*a3^2 - 24*j0*j2*v3*a0 - 8*j0*a3^3 + 24*j0*j2*v3*a3 - 24*j0*j2^2*d3;
E = - a0^4 + 6*a0^2*a3^2 - 12*a0^2*j2*v3 - 8*a0*a3^3 + 24*a0*a3*j2*v3 + 3*a3^4 - 12*a3^2*j2*v3 - 12*j2^2*v0^2 + 12*j2^2*v3^2 - 24*a0*j2^2*d3;

% validate when a1 == a0 + j0.*t1 == 0.
%  (can happen in constant velocity profile)
t1 = roots([A B C D E]);
if isempty(t1) && a0==a3 && v0==v3
  t1 = 0;
  t2 = d3/v0;
  t3 = 0;
  return
end

d0 = 0;
% get d1, v1, a1.
d1 = d0 + v0.*t1 + a0/2.*t1.*t1 + j0/6.*t1.*t1.*t1;
v1 = v0 + a0.*t1 + j0/2.*t1.*t1;
a1 = a0 + j0.*t1;
t3 = (a3 - a0 - j0.*t1)/j2;

% get a2, v2, d2.
a2 = a3 - j2.*t3;   
v2 = v3 - a2.*t3 - j2/2.*t3.*t3;
d2 = d3 - v2.*t3 - a2/2.*t3.*t3 - j2/6.*t3.*t3.*t3;
% solve t2 for v2 = v1 + a1*t2;   
t2 = (v2 - v1)./a1;
% solve t2 for d2 = d1 + v1*t2 + a1/2*t2^2 when a1==0.
%   we do not want a solution where v1 is zero, since we
%   require monotonicity between v0 and v3 and do not allow
%   v0 and v3 to change sign.  So if it is zero, t2 becomes
%   infinite and it is the caller's responsibility to reject it.
t2(a1==0) = (d2(a1==0) - d1(a1==0)) ./ v1(a1==0);


function flag = validate(t1, t2, t3, d3, v0, a0, j0, v3, a3, j2)

% make sure all times are real and non-negative
flag = imag(t1)==0 & imag(t2)==0 & imag(t3)==0;
flag = flag & 0 <= t1 & 0 <= t2 & 0 <= t3;

d0 = 0;

% compute distance, velocity, and acceleration after first duration.
d1 = d0 + v0.*t1 + a0/2.*t1.*t1 + j0/6.*t1.*t1.*t1;
v1 = v0 + a0.*t1 + j0/2.*t1.*t1;
a1 = a0 + j0.*t1;

% compute distance, velocity, and acceleration after second duration
d2 = d1 + v1.*t2 + a1/2.*t2.^2;
v2 = v1 + a1.*t2;
a2 = a1;

% verify final distance, velocity and acceleration
flag = flag & abs(d3 - (d2 + v2.*t3 + a2./2.*t3.*t3 + j2./6.*t3.*t3.*t3)) < sqrt(eps(d3));
flag = flag & abs(v3 - (v2 + a2.*t3 + j2./2.*t3.*t3)) < sqrt(eps(v3+1e-3));
flag = flag & abs(a3 - (a2 + j2.*t3)) < sqrt(eps(a3+1e-4));

% make sure distances are positive
flag = flag & 0 <= d1;
flag = flag & 0 <= d2 - d1;
flag = flag & (0 <= d3 - d2 | -eps(d3) <= d3 - d2);

% make sure velocities are monotone
flag = flag & (v0 <= v1 & v1 <= v2 & v2 <= v3 | v0 >= v1 & v1 >= v2 & v2 >= v3);


function [t1out,t2out,t3out,v0out,a0out,j0out,j2out] = mktrapseg(d, Vi, Ai, Vf, Af, Jc)
%MKTRAPSEG make trapezoidal acceleration piecewise polynomial
%   [T1,T2,T3,V0,A0,J0,J2] = MKTRAPSEG(D, Vi, Ai, Vf, Af, Jc) computes the
%   durations (T1,T2,T3), initial velocity and acceleration (V0,A0) and
%   initial and final jerk (J0,J2) for a trapezoidal acceleration pattern
%   over the specified distance, D; with initial velocity, Vi, initial
%   acceleration, Ai, final velocity, Vf, final acceleration Af, using a
%   constant magnitude jerk, Jc, for the initial and final leg.

[t1a, t2a, t3a] = timesolve(d, Vi, Ai,  Jc, Vf, Af,  Jc);
[t1b, t2b, t3b] = timesolve(d, Vi, Ai,  Jc, Vf, Af, -Jc);
[t1c, t2c, t3c] = timesolve(d, Vi, Ai, -Jc, Vf, Af,  Jc);
[t1d, t2d, t3d] = timesolve(d, Vi, Ai, -Jc, Vf, Af, -Jc);

t1 = vertcat(t1a,t1b,t1c,t1d);
t2 = vertcat(t2a,t2b,t2c,t2d);
t3 = vertcat(t3a,t3b,t3c,t3d);

n = size(t1,1);
d3 = repmat(d,n,1);
v0 = repmat(Vi,n,1);
a0 = repmat(Ai,n,1);

j0 = vertcat(repmat( Jc,size(t1a,1),1), ...
    repmat( Jc,size(t1b,1),1), ...
    repmat(-Jc,size(t1c,1),1), ...
    repmat(-Jc,size(t1d,1),1));
v3 = repmat(Vf,n,1);
a3 = repmat(Af,n,1);
j2 = vertcat(repmat( Jc,size(t1a,1),1), ...
    repmat(-Jc,size(t1b,1),1), ...
    repmat( Jc,size(t1c,1),1), ...
    repmat(-Jc,size(t1d,1),1));

flag = validate(t1,t2,t3,d3,v0,a0,j0,v3,a3,j2);
numSol = sum(flag);

if numSol > 0
    % provide real and constant hints to MATLAB Coder
    idx = find(flag,1);
    t1out = real(t1(idx(1)));
    t2out = real(t2(idx(1)));
    t3out = real(t3(idx(1)));
    v0out = real(v0(idx(1)));
    a0out = real(a0(idx(1)));
    j0out = real(j0(idx(1)));
    j2out = real(j2(idx(1)));
else
    t1out = nan;
    t2out = nan;
    t3out = nan;
    v0out = nan;
    a0out = nan;
    j0out = nan;
    j2out = nan;
end
