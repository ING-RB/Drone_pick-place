function course = solveMissingCourse(waypoints, course) 
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.SOLVEMISSINGCOURSE find missing tangent angles at waypoints for G2 clothoid fit
%   This function invokes the continuity solver after pruning out repeated
%   waypoints. The corresponding tangent angles are then copied to their
%   the corresponding locations of the original (unpruned) vector.
%
%   This function is for internal use only and may be removed in a later
%   release.

%   Copyright 2021 The MathWorks, Inc.

%#codegen

% find repeated waypoints
tf = waypoints(1:end-1,1)==waypoints(2:end,1) ...
   & waypoints(1:end-1,2)==waypoints(2:end,2);

% find the active non-equal consecutive waypoints
iUnique = 1+[0; find(~tf)];

% solve the course using just unique waypoints
uniqueCourse = clothoidG2FitMissingCourse(waypoints(iUnique,:), course(iUnique));

% copy the result to appropriate indices
course(iUnique) = uniqueCourse;

% find the indices of the repeated waypoints we skipped
iEqual = find(tf);
iRepeated = 1+iEqual;

% find the offset into the unique course
iResult = 1+cumsum(double(~tf));

% copy over the appropriate unique result to its final destination.
course(iRepeated) = uniqueCourse(iResult(iEqual));


function uniqueCourse = clothoidG2FitMissingCourse(waypoints, course)
% invoke the continuity solver if we have more than one point

if isscalar(course)
    % if only one is unique, then all waypoints were identical.
    % get the course from the first value or set it to zero if
    % it is marked as missing to be consistent with IEEE754 conventions.
    uniqueCourse = course;
    if isnan(uniqueCourse)
        uniqueCourse = 0;
    end
else
    % otherwise we have at least two distict points.  
    % invoke the contintuity solver
    uniqueCourse = matlabshared.tracking.internal.scenario.clothoidG2fitMissingCourse(waypoints,course);
end
