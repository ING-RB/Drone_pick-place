function [h,dtheta,e,w] = quaternionC2fit(y,x,wi,wf,maxit,tol)
% Subroutine qspline produces a quaternion spline interpolation of sparse data.
% The method is based on a third-order polynomial expansion of the
% rotation angle vector.
%
%  Inputs
%     maxit         maximum number of iterations.
%     tol           convergence tolerance (rad/sec) for iteration termination.
%     wi            initial angular rate vector.
%     wf            final angular rate vector.
%     x             pointer to input vector of time values (at least 4 points).
%     y             pointer to input vector of quaternion values.
% 
%  Outputs
%     h             vector of time interval values.
%     dtheta        vector of rotation angles.
%     e             array of rotation axis vectors.
%     w             intermediate angular rate values.

% Adapted from:  James McEnnan, qspline
%          ( http://sourceforge.net/projects/qspline-cc0 )

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

m = numel(y);

if m < 2
  error('insufficient input data.');
end
if m~=numel(x)
    error('mismatch size');
end

validateattributes(wi,{'double'},{'size',[1 3]});
validateattributes(wf,{'double'},{'size',[1 3]});
validateattributes(x,{'double'},{'increasing'});
validateattributes(maxit,{'double'},{'scalar','<',1000});
validateattributes(tol,{'double'},{'scalar','positive','<',1e-3});

h = diff(x);

[dtheta,e] = getang(y(1:m-1),y(2:m));

w = rates(m,maxit,tol,wi,wf,h,dtheta,e);



function [dtheta,e] = getang(qi,qf)
% [DTHETA,E] = GETANG(QI,QF) computes the slew angle, DTHETA, and axis, E, 
% between the input initial and final attitude quaternions, QI, and QF,
% respectively. 

m = size(qi,1);
n = size(qi,2);
if n~=1 || n~=size(qf,2) || m ~= size(qf,1)
    error('internal error');
end

deltaQuat = normalize( conj(qi).*qf );
% Make angle component of quaternion positive (quat == -quat).
idx = parts(deltaQuat) < 0;
deltaQuat(idx) = -deltaQuat(idx);

rv = rotvec(deltaQuat);

[dtheta, e] = unvec(rv);


function w = rates(n,maxit,tol,wi,wf,h,dtheta,e)
% subroutine rates computes intermediate angular rates for interpolation.
% n             i      number of input data points.
% maxit         i      maximum number of iterations.
% tol           i      convergence tolerance (rad/sec) for iteration termination.
% wi            i      initial angular rate vector.
% wf            i      final angular rate vector.
% h             i      pointer to vector of time interval values.
% dtheta        i      pointer to vector of rotation angles.
% e             i      pointer to array of rotation axis vectors.
% w             o      pointer to output intermediate angular rate values.

iter = 0;
flag = true;

a = zeros(n,1);
b = zeros(n,1);
c = zeros(n,1);
w = zeros(n,3);
wprev = zeros(n,3);

while flag % start iteration loop.
  wprev(2:n-1,:) = w(2:n-1,:);

  % set up the tridiagonal matrix. d initially holds the RHS vector array;
  % it is then overlaid with the calculated angular rate vector array.
  for i = 2:n-1
    a(i) = 2.0/h(i-1);
    b(i) = 4.0/h(i-1) + 4.0/h(i);
    c(i) = 2.0/h(i);

    temp1 = rf(e(i - 1,:),dtheta(i - 1),wprev(i,:));

    w(i,:) = 6.0*(dtheta(i-1)*e(i-1,:)/(h(i-1)*h(i-1)) + ...
                  dtheta(i  )*e(i  ,:)/(h(i  )*h(i  ))) - ...
              temp1;
  end

  temp1 = bd(e(1  ,:),dtheta(1  ),1,wi);
  temp2 = bd(e(n-1,:),dtheta(n-1),0,wf);

  w(2  ,:) = w(2  ,:) - a(2  )*temp1;
  w(n-1,:) = w(n-1,:) - c(n-1)*temp2;

  % reduce the matrix to upper triangular form.
  for i = 2:n-1
    b(i+1) = b(i+1) - c(i)*a(i+1)/b(i);
    temp1 = bd(e(i,:),dtheta(i),1,w(i,:));
    w(i+1,:) = w(i+1,:) - temp1*a(i+1)/b(i);
  end

  % solve using back substitution.
  w(n-1,:) =  w(n-1,:) / b(n-1);

  for i = n-2:-1:2
    temp1 = bd(e(i,:),dtheta(i),0,w(i+1,:));
    w(i,:) = (w(i,:) - c(i)*temp1)/b(i);
  end

  dw = norm(w(2:n-1,:)-wprev(2:n-1,:));

  iter = iter + 1;
  flag = iter<maxit && dw > tol;
end

% solve for end conditions.
w(1,:) = wi;
w(n,:) = wf;


function xout = bd(e,dtheta,flag,xin)

% Subroutine bd performs the transformation between the coefficient vector
% and the angular rate vector.
% 
% variable     i/o     description
% --------     ---     -----------
% e             i      unit vector along slew eigen-axis.
% dtheta        i      slew angle (rad).
% flag          i      flag determining direction of transformation.
%                       = 0 -> compute coefficient vector from
%                       angular rate vector
%                       = 1 -> compute angular rate vector from
%                       coefficient vector
% xin           i      input vector.
% xout          o      output vector.

EPS = 1e-6;
if dtheta > EPS
    ca = cos(dtheta);
    sa = sin(dtheta);

    if flag == 0
      b1 = 0.5*dtheta*sa/(1.0 - ca);
      b2 = 0.5*dtheta;
    elseif flag == 1
      b1 = sa/dtheta;
      b2 = (ca - 1.0)/dtheta;
    end

    b0 = dot(xin,e);

    temp2 = cross(e,xin);
    temp1 = cross(temp2,e);
    xout = b0*e + b1*temp1 + b2*temp2;
else
    xout = xin;
end

function rhs = rf(e,dtheta,win)

% Subroutine rf computes the non-linear rate contributions to the final
% angular acceleration.
% e             i      unit vector along slew eigen-axis.
% dtheta        i      slew angle (rad).
% win           i      input final angular rate vector.
% rhs           o      output vector containing non-linear rate contributions
%                      to the final acceleration.
EPS = 1e-6;
if dtheta > EPS
    ca = cos(dtheta);
    sa = sin(dtheta);

    temp2 = cross(e,win);
    temp1 = cross(temp2,e);

    windote = dot(win,e);
    magsq = dot(win,win);

    c1 = (1.0 - ca);

    r0 = 0.5*(magsq - windote*windote)*(dtheta - sa)/c1;

    r1 = windote*(dtheta*sa - 2.0*c1)/(dtheta*c1);

    rhs = r0*e + r1*temp1;
else
    rhs = zeros(1,3);
end

function [amag,au] = unvec(a)
%UNVEC unitizes a vector, a, and computes its magnitude.

amag = vecnorm(a,2,2);

% au = a ./ amag;
au = bsxfun(@rdivide, a, amag);

izero = find(amag<=0);
au(izero, :) = zeros(length(izero),3);

