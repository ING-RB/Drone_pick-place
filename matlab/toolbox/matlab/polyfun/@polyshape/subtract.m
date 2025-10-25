function [PG, shapeId, vertexId] = subtract(subject, clip, varargin)
% SUBTRACT Find the difference of two polyshapes
%
% PG = SUBTRACT(pshape1, pshape2) returns the difference between two 
% polyshapes. PG is a polyshape object with the same regions as pshape1
% minus any area where pshape2 overlaps pshape1. pshape1 and pshap2 must
% have compatible array sizes.
% 
% [PG, shapeId, vertexId] = SUBTRACT(pshape1, pshape2) returns the vertex
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
% PG = SUBTRACT(..., 'KeepCollinearPoints', tf) specifies how to treat 
% consecutive vertices lying along a straight line. tf can be one of the 
% following:
%   true  - Keep all collinear points as vertices of PG.
%   false - Remove collinear points so that PG contains the fewest number
%           of necessary vertices.
% If this name-value pair is not specified, then SUBTRACT uses the values
% of 'KeepCollinearPoints' that were used when creating the input
% polyshapes.
%
% PG = SUBTRACT(..., 'Simplify', tf) specifies how to resolve boundary
% intersections and improper nesting and remove duplicate points and
% degeneracies. tf can be one of the following:
%   true (default) - Automatically alter boundary vertices to create a 
%                    well-defined polygon.
%   false - Polyshape may contain intersecting edges, improper nesting,
%           duplicate points or degeneracies.
%
% See also union, xor, intersect, polyshape

% Copyright 2016-2024 The MathWorks, Inc.

narginchk(2, inf);
nargoutchk(0, 3);
polyshape.checkArray(subject);
polyshape.checkArray(clip);
[~, collinear,simplify] = polyshape.parseIntersectUnionArgs(false, varargin{:});

if ~(isscalar(subject) && isscalar(clip)) && nargout > 1
    error(message('MATLAB:polyshape:noVertexMapping'));
end
[PG, shapeId, vertexId] = booleanFun(subject, clip, collinear, @diff, simplify);
