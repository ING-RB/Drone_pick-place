function [witnesspts, dist2] = solveDistance(W, P, Q, spx, witnesspts)
%SOLVEDISTANCE determine the square distance to the origin and return the
%witness point. 
%
% [witnesspts, dist2] = solveDistance(W, P, Q, witnesspts)
%
% Input
%          P, Q: Specified as a 2-by-3 or 3-by-4 matrix of XY coordinate
%                points of the shapes
%          W   : Specified as a 2-by-3 or 3-by-4 matrix of coordinate
%                points of Simplex on the Configuration Space, where W:=P-Q.
%           spx: Identifier simplex variable, {1:Point, 2:Line, 3:Triangle,
%                4:Tetrahedron}
%   witnesspts : Specified as a 2-by-2 or 2-by-3 matrix of coordinate
%                points of Simplex on the Configuration Space. 
% Output
%   witnesspts : Specified as a 2-by-3 matrix of coordinate points of
%                Simplex on the Configuration Space.
%        dist2 : Square distance of the simplex to the origin, scalar

%#codegen

%   Author: Eri Gualter
%   Copyright 2022 MathWorks, Inc.

dist2 = zeros(1,'like',W);

switch spx
    case 1
        % the simplex is currently a point (0-simplex)
        dist2 = dot(W(:,1),W(:,1));
        witnesspts(:,1) = P(:,1);
        witnesspts(:,2) = Q(:,1);

    case 2
        % the simplex is currently a line segment (1-simplex)
        [~,u,v,dist2] = ...
            controllib.internal.gjk.GJK.closestPointOnEdgeToOrigin( ...
            W(:,1), W(:,2));

        if v<0
            if dot(W(:,1),W(:,1)) > dot(W(:,2),W(:,2))
                dist2 = dot(W(:,1),W(:,1));
                witnesspts(:,1) = P(:,1);
                witnesspts(:,2) = Q(:,1);
            else
                dist2 = dot(W(:,2),W(:,2));
                witnesspts(:,1) = P(:,2);
                witnesspts(:,2) = Q(:,2);
            end
        else
            witnesspts(:,1) = u*P(:,1) + v*P(:,2);
            witnesspts(:,2) = u*Q(:,1) + v*Q(:,2);
        end

    case 3
        % the simplex is currently a triangle (2-simplex)
        [~,u,v,w,dist2] = ...
            controllib.internal.gjk.GJK.closestPointOnTriangleToOrigin( ...
            W(:,1), W(:,2), W(:,3));

        witnesspts(:,1) = u*P(:,1) + v*P(:,2) + w*P(:,3);
        witnesspts(:,2) = u*Q(:,1) + v*Q(:,2) + w*Q(:,3);
    case 4
        % calculate the square distance to the origin
        [~,u,v,w,y,dist2] = ...
            controllib.internal.gjk.GJK.closestPointOnTetraToOrigin(W(:,1),...
            W(:,2), W(:,3), W(:,4));
        
        witnesspts(:,1) = u*P(:,1) + v*P(:,2) + w*P(:,3) + y*P(:,3);
        witnesspts(:,2) = u*Q(:,1) + v*Q(:,2) + w*Q(:,3) + y*Q(:,3);
end

end