function course = clothoidG2fitCourse(waypoints)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.CLOTHOIDG2FITCOURSE find tangent angles at waypoints for G2
%clothoid fit approximate course with discrete clothoid fit upsampled 1024x
%
%   This function is for internal use only and may be removed in a later
%   release.
%

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

n = size(waypoints,1);
course = zeros(n,1);

if n == 2
    % When there are only 2 waypoints, course is computed directly without calling dclothoid
    course(1) = angle(complex(waypoints(2,1)-waypoints(1,1),waypoints(2,2)-waypoints(1,2)));
    course(n) = course(1);
else
    % Get initial approximation to course angles
    up=1024;
    [u,v] = matlabshared.tracking.internal.scenario.dclothoid(waypoints(:,1),waypoints(:,2));
    course(1) = angle(complex(u(2)-u(1),v(2)-v(1)));
    course(n) = angle(complex(u(end)-u(end-1),v(end)-v(end-1)));
    for i=1:n-2
        course(i+1) = angle(complex(u(i*up+1)-u(i*up),v(i*up+1)-v(i*up)));
    end

    % finish with Levenberg-Marquardt-Fletcher solver
    if isequal(waypoints(1,:),waypoints(end,:))
        % initial and final course should be identical
        courselsq = matlabshared.tracking.internal.scenario.LMFsolve(@(x) clothresidloop(waypoints,x), course(1:n-1));
        courselsq = [courselsq; courselsq(1)];
    else
        courselsq = matlabshared.tracking.internal.scenario.LMFsolve(@(x) clothresid(waypoints,x), course);
    end

    course = courselsq;
end


function [kerr,Jtri] = clothresidloop(waypoints, course)
% obtain the (horizontal) initial positions
hip = complex(waypoints(:,1), waypoints(:,2));

% obtain number of control points (loop element is repeated at endpoints)
n = size(waypoints(:,1),1);

% obtain the starting curvature and final curvature of each segment.
[k0, k1, ~, dk0_dc0, dk0_dc1, dk1_dc0, dk1_dc1] = matlabshared.tracking.internal.scenario.clothoidG1fit2(hip(1:n-1),course(1:n-1),hip(2:n),course([2:n-1 1]));

% return the differences in curvature
kerr = [k1(end)-k0(1); k1(1:end-1)-k0(2:end)];

% The Jacobian is an N-1 by N-1 cyclic tridiagonal matrix
upper_diag = -dk0_dc1;
lower_diag =  dk1_dc0;
center_diag = dk1_dc1([n-1 1:n-2]) - dk0_dc0;

% J = sparse([1:n-1 1:n-1 2:n-1 1],[2:n-1 1 1:n-1 1:n-1],[upper_diag; center_diag; lower_diag],n-1,n-1);
Jtri = [lower_diag, center_diag, upper_diag];


function [kerr,Jtri] = clothresid(waypoints, course)
% obtain the (horizontal) initial positions
hip = complex(waypoints(:,1), waypoints(:,2));

% get the total number of control points
n = size(waypoints(:,1),1);

% for each segment, extract the initial and final curvatures and their
% partial derivatives with respect to the initial and final course angles
[k0, k1, ~, dk0_dc0, dk0_dc1, dk1_dc0, dk1_dc1] = matlabshared.tracking.internal.scenario.clothoidG1fit2(hip(1:n-1),course(1:n-1),hip(2:n),course(2:n));

% Set desired curvature at endpoints
k0_begin = 0;
k1_end = 0;

% return the differences in curvature
kerr = [k0_begin-k0(1); k1(1:end-1)-k0(2:end); k1(end)-k1_end];

% The Jacobian is an N by N tridiagonal matrix
upper_diag = -dk0_dc1;
lower_diag =  dk1_dc0;

center_diag = [k0_begin       - dk0_dc0(1); 
               dk1_dc1(1:n-2) - dk0_dc0(2:n-1); 
               dk1_dc1(n-1)   - k1_end];
           
% J = sparse([1:n-1 1:n 2:n],[2:n 1:n 1:n-1],[upper_diag; center_diag; lower_diag],n,n);
Jtri = [[lower_diag; 0], center_diag, [upper_diag; 0]];