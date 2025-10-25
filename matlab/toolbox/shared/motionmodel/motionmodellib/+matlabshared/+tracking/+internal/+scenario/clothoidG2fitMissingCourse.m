function course = clothoidG2fitMissingCourse(waypoints, course, m)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.CLOTHOIDG2FITMISSINGCOURSE find missing tangent angles at waypoints for G2 clothoid fit
%   approximate course with discrete clothoid fit upsampled by a factor of 2^m
%   
%   This function is for internal use only and may be removed in a later
%   release.
%

%   Copyright 2017-2018 The MathWorks, Inc.

%#codegen

if nargin < 3
    m = 7;
end

if isequal(waypoints(1,1:2), waypoints(end,1:2))
    course = fitPartialCourseLoop(waypoints, course, m);
else
    course = fitPartialCourse(waypoints, course, m);
end

function course = fitPartialCourseLoop(waypoints, course, m)
% if a course value is provided for the loop point
if isnan(course(1))
    course(1) = course(end);
else
    course(end) = course(1);
end

% partition the course into bordered segments
[ibegin,iend] = partitionCourse(course);

if isempty(ibegin) && isnan(course(1))
    % special case:  all values of loop are unknown
    course = fitLoopCourse(waypoints, m);
elseif isnan(course(1))
    % fill partition that wraps around beginning/endpoint
    n = numel(course);
    istart = ibegin(end);
    istop = iend(1);
    range = [istart:n-1 1:istop];
    course(range) = fitCourse(waypoints(range,:), course(range), m);
    course(n) = course(1);
    
    course = fillPartitions(waypoints, course, m, ibegin(1:end-1), iend(2:end));
else
    course = fillPartitions(waypoints, course, m, ibegin, iend);
end


function course = fitPartialCourse(waypoints, course, m)
% partition the course into bordered segments
[ibegin,iend] = partitionCourse(course);

% begin on starting NaN value if needed
if isnan(course(1))
    ibegin = [1; ibegin];
end

% terminate on NaN endpoint if needed
if isnan(course(end))
    iend = [iend; numel(course)];
end

% fill in each missing region
course = fillPartitions(waypoints, course, m, ibegin, iend);


function [ibegin,iend] = partitionCourse(course)
%PARTITIONCOURSE - partition course into segments
% [IBEGIN,IEND] = partitionCourse(course) returns starting locations,
% IBEGIN, and ending locations, IEND, that border consecutive unknown
% course regions marked by NaN.  

% find locations of known course values immediately prior to unknown
idxBegin = find(~isnan(course(1:end-1)) & isnan(course(2:end)));

% provide hint to MATLAB Coder
if isempty(idxBegin)
    ibegin = zeros(0,1);
else
    ibegin = idxBegin;
end

% find locations of known course values immediately after to unknown
idxEnd = 1+find(isnan(course(1:end-1)) & ~isnan(course(2:end)));

% provide hint to MATLAB Coder
if isempty(idxEnd)
    iend = zeros(0,1);
else
    iend = idxEnd;
end


function course = fillPartitions(waypoints, course, m, ibegin, iend)
for i=1:numel(ibegin)
    range = ibegin(i):iend(i);
    course(range) = fitCourse(waypoints(range,:), course(range), m);
end


function course = fitLoopCourse(waypoints, m)
% Get initial approximation of path
[u,v] = matlabshared.tracking.internal.scenario.dclothoidwp(waypoints(:,1),waypoints(:,2),m);

% Get approximate course angles
n = size(waypoints,1);
course = zeros(n,1);
course(1) = angle(complex(u(2)-u(1),v(2)-v(1)));
course(n) = angle(complex(u(end)-u(end-1),v(end)-v(end-1)));
up = 2^m;
for i=1:n-2
    course(i+1) = angle(complex(u(i*up+1)-u(i*up),v(i*up+1)-v(i*up)));
end

% finish with Levenberg-Marquardt-Fletcher solver
courselsq = matlabshared.tracking.internal.scenario.LMFsolve(@(x) clothresidloop(waypoints,x), course(1:n-1));
courselsq = [courselsq; courselsq(1)];

course = courselsq;


function [kerr,Jtri] = clothresidloop(waypoints, course)
% obtain the (horizontal) initial positions
hip = complex(waypoints(:,1), waypoints(:,2));

% obtain number of control points (loop element is repeated at endpoints)
n = size(waypoints,1);

% obtain the starting curvature and final curvature of each segment.
[k0, k1, ~, dk0_dc0, dk0_dc1, dk1_dc0, dk1_dc1] = matlabshared.tracking.internal.scenario.clothoidG1fit2(hip(1:n-1),course(1:n-1),hip(2:n),course([2:n-1 1]));

% return the differences in curvature
kerr = [k1(end,1)-k0(1,1); k1(1:end-1,1)-k0(2:end,1)];

% The Jacobian is an N-1 by N-1 cyclic tridiagonal matrix
upper_diag = -dk0_dc1;
lower_diag =  dk1_dc0;
center_diag = dk1_dc1([n-1 1:n-2],1) - dk0_dc0;

% J = sparse([1:n-1 1:n-1 2:n-1 1],[2:n-1 1 1:n-1 1:n-1],[upper_diag; center_diag; lower_diag],n-1,n-1);
Jtri = [lower_diag, center_diag, upper_diag];


function course = fitCourse(waypoints, course, m)
% make sure we have at least one course to fit
assert(any(isnan(course)));

% free endpoints have zero curvature
freelead = isnan(course(1));
freetail = isnan(course(end));

% initialize course via discrete clothoid fit
up = 2^m;
n = size(waypoints,1);

[dx,dy] = pol2cart(course([1; end],1),[1;1]);
[u,v] = matlabshared.tracking.internal.scenario.dclothoidwp(waypoints(:,1),waypoints(:,2),dx,dy,m);

for i=1:n-2
    course(i+1) = angle(complex(u(i*up+1)-u(i*up),v(i*up+1)-v(i*up)));
end

if freelead
    course(1) = angle(complex(u(2)-u(1),v(2)-v(1)));
end

if freetail
    course(end) = angle(complex(u(end)-u(end-1),v(end)-v(end-1)));
end

% finish with Levenberg-Marquardt-Fletcher 
if freelead && freetail
    courselsq = matlabshared.tracking.internal.scenario.LMFsolve(@(x) clothresid(waypoints,x), course);
elseif freelead
    courselsq = matlabshared.tracking.internal.scenario.LMFsolve(@(x) clothresidtrail(waypoints,course,x), course(1:end-1));
    courselsq = [courselsq; course(n)];
elseif freetail
    courselsq = matlabshared.tracking.internal.scenario.LMFsolve(@(x) clothresidlead(waypoints,course,x), course(2:end));
    courselsq = [course(1); courselsq];
else
    courselsq = matlabshared.tracking.internal.scenario.LMFsolve(@(x) clothresidsand(waypoints,course,x), course(2:end-1));
    courselsq = [course(1); courselsq; course(n)];
end
course = courselsq;


function [kerr,Jtri] = clothresidlead(waypoints, course, trailcourse)
% obtain the (horizontal) initial positions
hip = complex(waypoints(:,1), waypoints(:,2));

% get the total number of points
n = size(waypoints,1);

% set best course
course(2:end) = trailcourse;

% for each segment, extract the initial and final curvatures and their
% partial derivatives with respect to the initial and final course angles
[k0, k1, ~, dk0_dc0, dk0_dc1, dk1_dc0, dk1_dc1] = matlabshared.tracking.internal.scenario.clothoidG1fit2(hip(1:n-1),course(1:n-1),hip(2:n),course(2:n));

% Set desired curvature at endpoints
k1_end = 0;

% return the differences in curvature
kerr = [k1(1:end-1,1)-k0(2:end,1); k1(end,1)-k1_end];

% The Jacobian is an N-1 by N-1 tridiagonal matrix
upper_diag = -dk0_dc1(2:end,1);
lower_diag =  dk1_dc0(2:end,1);

center_diag = [dk1_dc1(1:n-2,1) - dk0_dc0(2:n-1,1); 
               dk1_dc1(n-1,1)   - k1_end];
           
% m = n-1;
% J = sparse([1:m-1 1:m 2:m],[2:m 1:m 1:m-1],[upper_diag; center_diag; lower_diag],m,m);
Jtri = [[lower_diag; 0], center_diag, [upper_diag; 0]];


function [kerr,Jtri] = clothresidtrail(waypoints, course, leadcourse)
% obtain the (horizontal) initial positions
hip = complex(waypoints(:,1), waypoints(:,2));

% get the total number of points
n = size(waypoints,1);

% set best course
course(1:end-1) = leadcourse;

% for each segment, extract the initial and final curvatures and their
% partial derivatives with respect to the initial and final course angles
[k0, k1, ~, dk0_dc0, dk0_dc1, dk1_dc0, dk1_dc1] = matlabshared.tracking.internal.scenario.clothoidG1fit2(hip(1:n-1),course(1:n-1),hip(2:n),course(2:n));

% Set desired curvature at endpoints
k0_begin = 0;

% return the differences in curvature
kerr = [k0_begin-k0(1,1); k1(1:end-1,1)-k0(2:end,1)];

% The Jacobian is an N-1 by N-1 tridiagonal matrix
upper_diag = -dk0_dc1(1:end-1,1);
lower_diag =  dk1_dc0(1:end-1,1);

center_diag = [k0_begin         - dk0_dc0(1,1); 
               dk1_dc1(1:n-2,1) - dk0_dc0(2:n-1,1)];
% m = n-1;
% J = sparse([1:m-1 1:m 2:m],[2:m 1:m 1:m-1],[upper_diag; center_diag; lower_diag],m,m);
Jtri = [[lower_diag; 0], center_diag, [upper_diag; 0]];


function [kerr,Jtri] = clothresidsand(waypoints, course, midcourse)
% obtain the (horizontal) initial positions
hip = complex(waypoints(:,1), waypoints(:,2));

% get the total number of points
n = size(waypoints,1);

% set best course
course(2:end-1) = midcourse;

% for each segment, extract the initial and final curvatures and their
% partial derivatives with respect to the initial and final course angles
[k0, k1, ~, dk0_dc0, dk0_dc1, dk1_dc0, dk1_dc1] = matlabshared.tracking.internal.scenario.clothoidG1fit2(hip(1:n-1),course(1:n-1),hip(2:n),course(2:n));

% return the differences in curvature
kerr = k1(1:end-1,1)-k0(2:end,1);

% The Jacobian is an N-2 by N-2 tridiagonal matrix
upper_diag = -dk0_dc1(2:end-1,1);
lower_diag =  dk1_dc0(2:end-1,1);

center_diag =  dk1_dc1(1:n-2,1) - dk0_dc0(2:n-1,1); 

% m = n-2;
% J = sparse([1:m-1 1:m 2:m],[2:m 1:m 1:m-1],[upper_diag; center_diag; lower_diag],m,m);
Jtri = [[lower_diag; 0], center_diag, [upper_diag; 0]];


function [kerr,Jtri] = clothresid(waypoints, course)
% obtain the (horizontal) initial positions
hip = complex(waypoints(:,1), waypoints(:,2));

% get the total number of control points
n = size(waypoints,1);

% for each segment, extract the initial and final curvatures and their
% partial derivatives with respect to the initial and final course angles
[k0, k1, ~, dk0_dc0, dk0_dc1, dk1_dc0, dk1_dc1] = matlabshared.tracking.internal.scenario.clothoidG1fit2(hip(1:n-1),course(1:n-1),hip(2:n),course(2:n));

% Set desired curvature at endpoints
k0_begin = 0;
k1_end = 0;

% return the differences in curvature
kerr = [k0_begin-k0(1,1); k1(1:end-1,1)-k0(2:end,1); k1(end,1)-k1_end];

% The Jacobian is an N by N tridiagonal matrix
upper_diag = -dk0_dc1;
lower_diag =  dk1_dc0;

center_diag = [k0_begin          - dk0_dc0(1,1); 
               dk1_dc1(1:n-2,1) - dk0_dc0(2:n-1,1); 
               dk1_dc1(n-1,1)   - k1_end];
           
% J = sparse([1:n-1 1:n 2:n],[2:n 1:n 1:n-1],[upper_diag; center_diag; lower_diag],n,n);
Jtri = [[lower_diag; 0], center_diag, [upper_diag; 0]];
