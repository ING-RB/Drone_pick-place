function varargout = intersect(subject, varargin)
% INTERSECT Find the intersection of two polyshapes or a polyshape and a
% line
%
% PG = INTERSECT(pshape1, pshape2) returns the intersection of two 
% polyshapes. pshape1 and pshape2 must have compatible array sizes.
%
% PG = INTERSECT(P) returns the intersection of all polyshape objects in
% the vector of polyshapes P. The intersection contains the regions 
% overlapped by all elements of P.
%
% [PG, shapeId, vertexId] = INTERSECT(pshape1, pshape2) returns the vertex
% mapping between the vertices in PG and the vertices in the polyshapes
% pshape1 and pshape2. shapeId and vertexId are both column vectors with 
% the same number of rows as in the Vertices property of PG. If an element 
% of shapeId is 1, the corresponding vertex in PG is from pshape1. If an
% element of shapeId is 2, the corresponding vertex in PG is from pshape2.
% If an element of shapeId is 0, the corresponding vertex in PG is created 
% by the intersection of pshape1 and pshape2. vertexId contains the row 
% numbers in the Vertices properties for pshape1 or pshape2. An element 
% of vertexId is 0 when the corresponding vertex in PG is created by the 
% intersection. The vertex mapping output arguments are only supported when 
% pshape1 and pshape2 are scalars.
%
% [PG, shapeId, vertexId] = INTERSECT(P) returns the vertex mapping between
% the vertices in PG and the vertices in the polyshapes vector P.
%
% PG = INTERSECT(..., 'KeepCollinearPoints', tf) specifies how to treat 
% consecutive vertices lying along a straight line. tf can be one of the 
% following:
%   true  - Keep all collinear points as vertices of PG.
%   false - Remove collinear points so that PG contains the fewest number
%           of necessary vertices.
% If this name-value pair is not specified, then INTERSECT uses the values
% of 'KeepCollinearPoints' that were used when creating the input
% polyshapes.
%
% PG = INTERSECT(..., 'Simplify', tf) specifies how to resolve boundary
% intersections and improper nesting and remove duplicate points and
% degeneracies. tf can be one of the following:
%   true (default) - Automatically alter boundary vertices to create a 
%                    well-defined polygon.
%   false - Polyshape may contain intersecting edges, improper nesting,
%           duplicate points or degeneracies.
%
% [inside, outside] = INTERSECT(pshape, lineseg) returns the line segments
% that are inside and outside of a polyshape. lineseg is a 2-column matrix
% whose first column defines the x-coordinates of the input line segments
% and the second column defines the y-coordinates. lineseg must have a
% least two rows.
%
% Example: Find the intersection of two squares
%   p = nsidedpoly(4, 'sideLength', 1, 'center', [0 1]);
%   q = nsidedpoly(4, 'sideLength', 2);
%   [PG, sId, vId] = intersect(p, q);
%   hp = plot(p);
%   hp.FaceColor = 'none';
%   axis equal; hold on
%   hq = plot(q);
%   hq.FaceColor = 'none';
%   hPG = plot(PG);
%
% See also subtract, union, xor, polyshape

% Copyright 2016-2024 The MathWorks, Inc.

narginchk(1, inf);
ns = polyshape.checkArray(subject);
[has_clip, collinear,simplify] = polyshape.parseIntersectUnionArgs(true, varargin{:});

if ~has_clip
    nargoutchk(0, 3);
    if isscalar(subject)
        %special treatment here. booleanVec returns an empty shape if
        %subject is a scalar shape
        [PG, shapeId, vertexId] = booleanFun(subject, subject, collinear, @intersect,simplify);
        shapeId(shapeId==2) = 1;
    else
        [PG, shapeId, vertexId] = booleanVec(subject, collinear, false,simplify);
    end
    varargout{1} = PG;
    if nargout >= 2
        varargout{2} = shapeId;
    end
    if nargout == 3
        varargout{3} = vertexId;
    end
else
    clip = varargin{1};
    pip = isa(clip, 'polyshape');
    if (pip)
        nargoutchk(0, 3);
        nc = polyshape.checkArray(clip);

        if ~(isscalar(subject) && isscalar(clip)) && nargout > 1
            error(message('MATLAB:polyshape:noVertexMapping'));
        end
        [PG, shapeId, vertexId] = booleanFun(subject, clip, collinear, @intersect,simplify);
        varargout{1} = PG;
        if nargout >= 2
            varargout{2} = shapeId;
        end
        if nargout == 3
            varargout{3} = vertexId;
        end
    else
        %isnumeric(clip) must be true
        if numel(subject) ~= 1
            error(message('MATLAB:polyshape:scalarPolyshapeError'));
        end
        nargoutchk(0, 2);
        
        param = struct;
        param.allow_inf = false;
        param.allow_nan = false; %allow 1 polyline as input
        param.one_point_only = false;
        param.errorOneInput = 'MATLAB:polyshape:lineInputError';
        param.errorTwoInput = 'MATLAB:polyshape:lineInputError';
        param.errorValue = 'MATLAB:polyshape:linePointValue';
        [X, Y] = polyshape.checkPointArray(param, clip);
        if numel(X) < 2
            error(message('MATLAB:polyshape:lineMin2Points'));
        end

        if collinear ~= "default"
            warning(message('MATLAB:polyshape:collinearNoEffect'));
        end

        if subject.isEmptyShape()
            out1 = zeros(0, 2);
            out2 = [X Y];
        else
            [out1, out2] = lineintersect(subject.Underlying, [X Y]);

            % Bug fix for edge case where single line segment parallel to one 
            % of edges of the polyshape and lying outside the polyshape does not
            % generate the out2 array
            if (isempty(out1) && isempty(out2))
                ux_coords = unique([X Y],'rows','stable');
                num_ux = size(ux_coords,1);
                if num_ux > 1
                    for ii=1:num_ux
                        [in1,on1] = inpolygon(ux_coords(ii,1),ux_coords(ii,2),subject.Vertices(:,1),...
                            subject.Vertices(:,2));
                        if ~in1 || on1
                            out2 = [out2; ux_coords(ii,1) ux_coords(ii,2);];
                        end
                    end
                end
            end

        end

        varargout{1} = out1;
        if nargout == 2
            varargout{2} = out2;
        end
    end
end
