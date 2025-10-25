function sub = subRange(range,span,orientation)
    %SUBRANGE subdivide a range
    %   range - a four element range vector [startRow startColumn numRow numColumn]
    %   span - the column to use, or a start and end column to use.
    %   orientation - 'column' (default) or 'row'. 
    %
    %   Returns a four element range of only the columns/row of interest.
    
    % Copyright 2016 The MathWorks, Inc.
    
    sub = range;
    %Select the span of columns
    width = span(end) - span(1) + 1;
    if ~exist('orientation','var') || strcmp(orientation,'column')
        sub(2) = range(2) + span(1) - 1;
        sub(4) = width;
    else
        sub(1) = range(1) + span(1) - 1;
        sub(3) = width;
    end
end
