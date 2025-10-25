function inter = validateLineIntervals(inter,propname)
% validates line intervals of the form [1,2;4,5;9,inf]. See
% TextImportOptions.DataLines

% Copyright 2017 MathWorks, Inc.

% Check for infs that are not in the last position
numOfInfs = sum(isinf(inter(1:end-1)));
if numOfInfs > 0
    error(message('MATLAB:textio:io:DataLinesInf',propname));
end

% Make sure the values are positive integers in a matrix with two columns
numColumns = size(inter,2);
isnotwhole = floor(inter) ~= inter;
isnotpositive = inter <= 0;
if ~isnumeric(inter) || ~isreal(inter) || numColumns ~= 2 || ~ismatrix(inter) ...
        || any(isnotwhole(:)) || any(isnotpositive(:))
    error(message('MATLAB:textio:io:InvalidDataLines',propname));
end

% Validate there are no intersections and that the intervals are in
% ascending order
rhs_transpose = inter';
d = diff(rhs_transpose(:));

% The odd diffs can be equal, e.g. [3 3] is a valid interval but the
% even diffs cannot be equal, e.g. [1 3; 3 5] is not a valid interval
if any(d(1:2:end) < 0) || any(d(2:2:end) <= 0)
    error(message('MATLAB:textio:io:InvalidDataLinesIntervals',propname));
end

inter = double(inter);
end