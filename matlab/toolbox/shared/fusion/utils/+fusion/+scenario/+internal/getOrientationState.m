function [q, aVelocity, aAcceleration, aJerk] = getOrientationState(t, x, y, h, dtheta, e, w)
%FUSION.SCENARIO.INTERNAL.GETORIENTATIONSTATE interpolates a cubic quaternion spline
%  Inputs
%     t             desired output time
%     x             input vector of time values
%     y             input vector of quaternion values.
%     h             vector of time interval values.
%     dtheta        vector of rotation angles.
%     e             array of rotation axis vectors.
%     w             intermediate angular rate values.
%
%  Outputs
%     q             interpolated quaternion value.
%     aVelocity     interpolated angular rate (rad/sec).
%     aAcceleration interpolated angular acceleration (rad/sec^2).
%     aJerk         interpolated angular jerk (rad/sec^3).

% Adapted from:  James McEnnan, qspline
%          ( http://sourceforge.net/projects/qspline-cc0 )

%    Copyright 2017-2020 The MathWorks, Inc.

%#codegen

% assert(isscalar(t));

% look up index into time table (x)
i = discretize(t,x);
% i = nnz(x(1:end-1) <= t);

% fetch work matrices
[A,B,C,D] = slew3_init(h(i),dtheta(i),e(i,:),w(i,:),w(i + 1,:));

% fetch orientation and angular measures
[q,aVelocity,aAcceleration,aJerk] = slew3(t-x(i),h(i),y(i,:),A,B,C,D);


function [aa,bb,cc,dd] = slew3_init(dt,dtheta,e,wi,wf)
% Subroutine slew3_init computes the coefficients for a third-order polynomial
% interpolation function describing a slew between the input initial and
% final states.
% 
% dt            i      slew time (sec).
% dtheta        i      slew angle (rad).
% e             i      unit vector along slew eigen-axis.
% wi            i      initial body angular rate (rad/sec).
% wf            i      final body angular rate (rad/sec).

n = length(dt);

aa = zeros(n,3,3);
bb = zeros(n,3,3);
cc = zeros(n,3,2);
dd = zeros(n,3);

sa = sin(dtheta);
ca = cos(dtheta);

% final angular rate terms.
EPS = 1e-6;

igt = find(dtheta > EPS);

bvec = wf;

if ~isempty(igt)
    c1 = 0.5 * sa(igt) .* dtheta(igt) ./ (1.0 - ca(igt));
    c2 = 0.5 * dtheta(igt);
    b0 = dot(e(igt,:),wf(igt,:),2);
    bvec2 = cross(e(igt,:),wf(igt,:),2);
    bvec1 = cross(bvec2,e(igt,:),2);
    bvec(igt,:) = bsxmul(b0,e(igt,:)) + bsxmul(c1,bvec1) + bsxmul(c2,bvec2);
end

% compute coefficients. 
bb(:,:,1) = wi;

aa(:,:,3) = bsxmul(e,dtheta);
bb(:,:,3) = bvec;

aa(:,:,1) = bsxmul(bb(:,:,1),dt);
aa(:,:,2) = bsxmul(bb(:,:,3),dt) - 3*aa(:,:,3);

bb(:,:,2) = bsxdiv(2*aa(:,:,1) + 2*aa(:,:,2), dt);
cc(:,:,1) = bsxdiv(2*bb(:,:,1) +   bb(:,:,2), dt);
cc(:,:,2) = bsxdiv(  bb(:,:,2) + 2*bb(:,:,3), dt);

dd        = bsxdiv(  cc(:,:,1) +   cc(:,:,2), dt);

% clobber division by zero
invalid = find(dt <= 0.0);
aa(invalid,:,:) = 0;
bb(invalid,:,:) = 0;
cc(invalid,:,:) = 0;
dd(invalid,:) = 0;

function [q,angVel,angAcc,angJerk] = slew3(t,dt,qi,a,b,c,d)
% Subroutine slew3 computes the quaternion, body angular rate, acceleration and
% jerk as a function of time corresponding to a third-order polynomial
% interpolation function describing a slew between initial and final states.
% 
% t             i      current time (seconds from start).
% dt            i      slew time (sec).
% qi            i      initial attitude quaternion.
% q             o      current attitude quaternion.
% angVel        o      current body angular rate (rad/sec).
% angAcc        o      current body angular acceleration (rad/sec^2).
% angJerk       o      current body angular jerk (rad/sec^3).

EPS = 1e-6;
n = length(t);

q = quaternion.zeros(n,1);
angVel = zeros(n,3);
angAcc = zeros(n,3);
angJerk = zeros(n,3);
    
if dt <= 0.0
  return
end

x = t./dt;

x1 = x - 1.0;
x2 = x1.*x1;

th0 = bsxmul(bsxmul(bsxmul(a(:,:,3),x) + bsxmul(x1,a(:,:,2)),x) + bsxmul(x2,a(:,:,1)),x);
th1 =        bsxmul(bsxmul(b(:,:,3),x) + bsxmul(x1,b(:,:,2)),x) + bsxmul(x2,b(:,:,1));
th2 =               bsxmul(c(:,:,2),x) + bsxmul(x1,c(:,:,1));
th3 = d;

deltaQ = quaternion(th0, 'rotvec');
q = qi .* deltaQ;

[ang,u] = unvec(th0);


% pre-initialize
angVel = th1;
angAcc = th2;
angJerk = th3 - 0.5*cross(th1,th2,2);


igt = find(ang>EPS);

if ~isempty(igt)
   [angVel(igt,:), angAcc(igt,:), angJerk(igt,:)] = angDeriv(ang(igt),th1(igt,:),th2(igt,:),th3(igt,:),u(igt,:));
end


function [angVel, angAcc, angJerk] = angDeriv(ang, th1, th2, th3, u)
ca = cos(ang);
sa = sin(ang);

% compute angular rate vector.

temp1 = cross(u,th1,2);

w = bsxdiv(temp1,ang);

udot = cross(w,u,2);

thd1 = dot(u,th1,2);

angVel =  bsxmul(thd1,u) + bsxmul(sa,udot) - bsxmul(1.0-ca, w);

% compute angular acceleration vector.

thd2 = dot(udot,th1,2) + dot(u,th2,2);

temp1 = cross(u,th2,2);

wd1 = bsxdiv(temp1 - bsxmul(2.0*thd1,w), ang);

wd1xu = cross(wd1,u,2 );

temp0 = bsxmul(thd1,u) - w;
temp1 = cross(angVel,temp0,2);

angAcc = bsxmul(thd2,u) + bsxmul(sa,wd1xu) - bsxmul(1-ca, wd1) + bsxmul(thd1,udot) + temp1;

% compute angular jerk vector.

w2 = sum(w.*w,2);

thd3 = dot(wd1xu, th1, 2) - ...
       w2.*dot(u, th1, 2) + ...
         2*dot(udot, th2, 2) + ...
       dot(u, th3, 2);

temp1 = bsxdiv(cross(th1,th2,2), ang);
temp2 = cross(u,th3,2);

td2 = sum(th1.*th1, 2)./ang;

ut2 = dot(u, th2, 2);

wwd = dot(w, wd1, 2);

wd2 = bsxdiv(temp1 + temp2 - bsxmul(2*(td2 + ut2),w) - bsxmul(4*thd1,wd1), ang);

wd2xu = cross(wd2,u,2);

temp2 = bsxmul(thd2,u) + bsxmul(thd1,udot) - wd1;

temp1 = cross(angVel,temp2,2);
temp2 = cross(angAcc,temp0,2);

angJerk = bsxmul(thd3,u) + bsxmul(sa,wd2xu) - bsxmul(1-ca, wd2) + bsxmul(2.*thd2,udot) ...
                 + bsxmul(thd1, bsxmul(1.0+ca, wd1xu) - bsxmul(w2,u) - bsxmul(sa,wd1)) ...
                 - bsxmul(wwd.*sa,u) + temp1 + temp2;

function [amag,au] = unvec(a)
%UNVEC unitizes a vector, a, and computes its magnitude.

amag = vecnorm(a,2,2);

au = bsxdiv(a, amag);

izero = find(amag <= 0);
au(izero, :) = zeros(length(izero),3);

function z = bsxmul(x,y)
z = bsxfun(@times,x,y);

function z = bsxdiv(x,y)
z = bsxfun(@rdivide,x,y);
