function jerk = mintrapjerk(d, v, checkInf)
% MATLABSHARED.TRACKING.INTERNAL.SCENARIO.MINTRAPJERK - find minimum jerk for trapezoidal acceleration profile
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   JERK = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.MINTRAPJERK(D, V)
%   returns the minimum jerk required to compute a trapezoidal acceleration
%   profile for the given durations and velocities.

% Copyright 2022-2024 The MathWorks, Inc.

% Speed may be specified using negative values for reverse movement.
arguments
    d(:,1) double
    v(:,1) double
    checkInf(1,1) logical = false
end
v = abs(v);
accel = getAccelerations(v, d);
numSegs = length(d);
jerk = 0;
for kndx = 1:numSegs
    if checkInf
        arrJerk = [minJerk(d(kndx), v(kndx), accel(kndx), v(kndx+1), accel(kndx+1)),jerk];
        jerk = max(arrJerk(arrJerk<inf));
    else
        jerk = max(minJerk(d(kndx), v(kndx), accel(kndx), v(kndx+1), accel(kndx+1)),jerk);
    end
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

function Jmin = minJerkOpp(d, v0, a0, v3, a3)

d0 = 0;
d3 = d;

A = 36 * (d3 - d0)^2;
B = 36 * ((v0 - v3)*(v3 + v0)^2 + 2*(d3 - d0)*(a0*v0 + a3*v3));
C = 6 * (a0 - a3) * (4*(d0-d3)*(a0^2 + a0*a3 + a3^2) - 3*(v0-v3)*(v0+v3)*(a0+a3) - 6*(a0-a3)*v0*v3);
D = 3 * (a0 - a3)^3 * ((v0+v3)*(a0+a3) + 2*(a0*v3+a3*v0));
E = -1/2 * ((a0 + a3)^2 + 2*a0*a3) * (a0 - a3)^4;

Jc = roots([A B C D E]);
Jc(imag(Jc) ~= 0) = [];

Jc = Jc + sign(Jc).*double(eps(single(Jc)));

Jmin = Inf;
for i=1:numel(Jc)
    [t1, t2, t3] = timesolve(d, v0, a0,  Jc(i), v3, a3, -Jc(i));
    flag = validate(t1, t2, t3, d3, v0, a0, Jc(i), v3, a3, -Jc(i));
    if any(flag)
        Jmin = min([Jmin; abs(Jc(i))]);
    end
end

function Jc = minJerkSame(d3, v0, a0, v3, a3)

if a0==a3
    Jc = 0;
    return
end

Jc = vertcat(minJerkZeroTa(d3, v0, a0, v3, a3), ...
    minJerkZeroTc(d3, v0, a0, v3, a3));



function Jc = minJerkZeroTa(d3, v0, a0, v3, a3)

aa = -12*v0^2 + 12*v3^2 - 24*a0*d3;
bb = -12*v3*a0^2 + 24*v3*a0*a3 - 12*v3*a3^2;
cc = a0^4 + 6*a0^2*a3^2 - 8*a0*a3^3 + 3*a3^4;

Jc = vertcat((a3+a0)*(a3-a0)/(2*(v0-v3)), ...
    (-bb-sqrt(bb^2-4*aa*cc))/(2*aa), ...
    (-bb+sqrt(bb^2-4*aa*cc))/(2*aa));

% filter out illegal solutions
if a0<a3
    Jc(Jc<=0) = [];
else
    Jc(Jc>=0) = [];
end

Ta = 0;
Tc = (a3 - a0)./Jc - Ta;
if a0==0
    Tb = (6*d3 - 6*Tc.*v0 - Jc.*Tc.^3)./(6*v0);
else
    Tb = (v3 - (v0 + (Jc.*Tc.^2)/2 + Tc.*(a0 + Jc.*Ta))) ./ (a0 + Jc.*Ta);
end
Jc = Jc(validate(Ta, Tb, Tc, d3, v0, a0, Jc, v3, a3, Jc));


function Jc = minJerkZeroTc(d3, v0, a0, v3, a3)

aa = -12*v0^2 + 12*v3^2 - 24*a3*d3;
bb = 12*v0*a0^2 - 24*v0*a0*a3 + 12*v0*a3^2;
cc = -3*a0^4 + 8*a0^3*a3 - 6*a0^2*a3^2 + a3^4;

Jc = vertcat((a3+a0)*(a0-a3)/(2*(v0-v3)), ...
    (-bb-sqrt(bb^2-4*aa*cc))/(2*aa), ...
    (-bb+sqrt(bb^2-4*aa*cc))/(2*aa));

% filter out illegal solutions
if a0<a3
    Jc(Jc<=0) = [];
else
    Jc(Jc>=0) = [];
end

Tc = 0;
Ta = (a3 - a0)./Jc - Tc;

if a3 == 0
    Tb = (6*d3 - 2*(a0.*Ta + 3*v0).*Ta) ./ (3*(a0.*Ta + 2*v0));
else
    Tb = (v3 - (v0 + a0.*Ta + (Jc.*Ta.^2)/2)) ./ a3;
end

Jc = Jc(validate(Ta, Tb, Tc, d3, v0, a0, Jc, v3, a3, Jc));


function Jc = minJerk(d3, v0, a0, v3, a3)

% try opposing jerks

Jc = min(abs(minJerkOpp(d3, v0, a0, v3, a3)));
if ~isfinite(Jc)
    Jc = min(abs(minJerkSame(d3, v0, a0, v3, a3)));
end


% allow six digits of accuracy
Jc = 1.000001*Jc;

% check solution
if isempty(Jc) || ~isfinite(Jc)
    Jc = Inf;
else
    t1out = mktrapseg(d3, v0, a0, v3, a3, Jc);
    if isnan(t1out)
        Jc = Inf;
    end
end
