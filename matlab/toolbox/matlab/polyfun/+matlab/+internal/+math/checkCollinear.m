function output=checkCollinear(output,subject,pt3,idx_begin,idx_end,tolerance)
% Helper function to test whether a query pt lies on a polyshape edge
% The output is m-by-2 matrix containing the query point coordinates that
% lie on the polyshape edges. subject is a polyshape. pt3 is a query pt
% given as a 1-by-2 matrix. idx_begin is starting index of the polyshape
% edge that is to be checked. idx_end is end index of the polyshape
% edge that is to be checked. tolerance determines the zone within the
% query pt be considered as a part of the edge.
%
% Copyright 2022 The MathWorks, Inc.

    ax = subject.Vertices(idx_begin,1);
    ay = subject.Vertices(idx_begin,2);
    bx = subject.Vertices(idx_end,1);
    by = subject.Vertices(idx_end,2);
    cx = pt3(1);
    cy = pt3(2);
    orient = det([ax ay 1; bx by 1;cx cy 1] );
    isCollinear = abs(orient) <= tolerance;

    % ensure c lies between a and b. bounding box test
    % tol_zone = 1e-8;
    max_ab_x = max(ax,bx);
    max_ab_y = max(ay,by);
    min_ab_x = min(ax,bx);
    min_ab_y = min(ay,by);
    % this is for edge cases when the intersection pt may be at "zero"
    isInside = cx <= max_ab_x+tolerance & cx >= min_ab_x-tolerance & ...
        cy <= max_ab_y+tolerance & cy >= min_ab_y-tolerance;

    % discard if point already exists in the list
    ptExists = any([any(ismember(output,[idx_begin idx_begin],'rows')) ...
                    any(ismember(output,[idx_end idx_end],'rows')) ]);

    if (all([~ptExists isInside isCollinear]))
        output=[output; idx_begin idx_end];
    end
end