classdef PrimitiveMeshGenerator  < robotics.core.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%PRIMITIVEMESHGENERATOR Utilities to generate meshes for common geometric primitives
%   such as cube, sphere or cylinder

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

    methods (Static)


        function [F, V] = regularExtrusionMesh(pm)
        % regularExtrusionMesh creates a mesh for regular prism shape. The
        % origin is at the centre of regular prism. The input arguments
        % are length of extrusion, number of sides and radius, given by
        % 3-by-1 vector.
            n = pm(1);    % number of sides
            r = pm(2);    % radius
            l = pm(3);    % length of extrusion

            ang = (2*pi) / n;
            V = zeros(2*(n+1), 3);
            F = zeros(4*n, 3);

            V(end-1,:) = [0,0,l/2];   %centre of top surface
            V(end,:) = [0,0,-l/2];    %centre of bottom surface
            for i=0:n-1
                th = i*ang;
                V(i+1,:) = [r*cos(th), r*sin(th), l/2];
                V(i+n+1, :) = [r*cos(th), r*sin(th), -l/2];
            end
            %top and bottom surface faces
            for i=1:n
                F(i,:) = [2*n+1, i , mod(i, n)+1];
                F(i+n, :) = [2*(n+1), n+i,n+mod(i,n)+1];
            end

            %faces along the sides
            for i=1:n
                F(i+(2*n), :) = [i, i+n, n+mod(i,n)+1];
                F(i+(3*n), :) = [i , mod(i, n)+1, n+mod(i,n)+1];
            end
            F = robotics.core.internal.PrimitiveMeshGenerator.flipFace(F);
        end


        function [F,V] = generalExtrusionMesh(pm)
        % generalExtrusionMesh creates a mesh for general prism shape.
        % The input parameters are cross section and length of
        % extrusion, given by 2-by-1 cell array. The origin is at
        % the origin of coordinate frame of the cross section moved by
        % half the length of extrusion in z direction. (middle of
        % extrusion in z direction)

            cs = pm{1};  % Cross section
            l = pm{2};   % length of extrusion

            % Triangulate the cross section and use the triangulation
            % data to create new vertices and faces for the extruded shape
            pl = polyshape(cs, "Simplify",false, "KeepCollinearPoints",true);
            tr = triangulation(pl);

            b = tr.Points;
            n = size(tr.Points,1);
            f = size(tr.ConnectivityList,1);

            V = zeros(2*n, 3);
            F = zeros(2*n+2*f, 3);

            %extruded surface along the boundary
            for i = 1:n
                V(i,:) = [b(i,1), b(i,2), l/2];
                V(i+n,:) = [b(i,1), b(i,2), -l/2];
            end

            for i = 1:n
                F(i, :) = [i, i+n, n+mod(i,n)+1];
                F(i+n, :) = [i , mod(i, n)+1, n+mod(i,n)+1];
            end

            %top and bottom surfaces
            for i=1:f
                F(2*n+i, :) = tr.ConnectivityList(i,:);
                F(f+2*n+i, :) = n + tr.ConnectivityList(i, :);
            end
            F = robotics.core.internal.PrimitiveMeshGenerator.flipFace(F);
        end


        function [F, V] = revolvedSolidMesh(pm)
        % revolvedSoledMesh creates a mesh for revolved solid shape,
        % The origin is at the origin of the coordinate frame in which
        % cross section is revolved. The input arguments are cross
        % section and angle of revolution, given by 2-by-1 cell array.
            cs = pm{1};   % cross section
            rot = 2*pi;   % angle of revolution
            isFullyRev = true; %is fully revolved

            if numel(pm) == 2
                rot = pm{2};
                isFullyRev = abs(rot-2*pi) < eps;
            end
            smf = 1000;   % smoothing factor

            th = rot/smf;

            pl = polyshape(cs);
            tr = triangulation(pl);

            b = tr.Points;
            n = size(tr.Points,1);   % no of cross section points
            nn = nnz(cs(:,1));       % no of points that do not lie on the axis of revolution
            csp = zeros(n,1);        % logical array to keep track of cross section points that lie on axis of revolution


            % When a point is revolved around an axis, the path traced by
            % that point forms a curve. If the point lies on the axis of
            % revolution, it only needs one vertex (because revolution will
            % not result in any curve). When the points which do not lie on
            % the axis are revolved around the axis, the traced path is
            % represented using smf number of points.
            V = zeros(nn*(smf) + n, 3);  % Vertices

            % We need to keep track of the indices of the vertices
            % representing the cross section when the vertices of original
            % cross section is revolved to the far left and right ends.
            % Because these lateral surfaces are need to be triangulated when
            % the angle of revolution is less than 2pi
            left_cs = zeros(n,1);
            right_cs = zeros(n,1);

            cnt = 1;
            idx = zeros(n,1); % indices of first point of the curve traced by a cross section point

            % Create vertices
            % If a point(x,y) is revolved at angle theta with X axis around
            % the axis of revolution (Z axis), the new vertex formed in this
            % reference frame would be v = [ x*cos(theta), x*sin(theta), y]
            for i=1:n

                if b(i,1) == 0 % if point lies on the axis of revolution
                    V(cnt, :) = [0, 0, b(i,2)];
                    left_cs(i) = cnt;
                    right_cs(i) = cnt;
                    idx(i) = cnt;
                    cnt = cnt +1;
                    csp(i) = 1;
                else
                    % If point(x,y) does not lie on the axis of revolution
                    r = b(i,1);
                    left_cs(i) = cnt;
                    idx(i) = cnt;
                    for j = smf/2:-1:-smf/2
                        V(cnt,:) = [r*cos(j*th), r*sin(j*th), b(i,2)];
                        cnt = cnt +1;
                    end
                    right_cs(i) = cnt-1;
                end
            end


            nfaces = 2*smf*(nn -1) + smf*2;   % no of faces which can be formed using the vertices
                                              % which do not lie on the axis of revolution

            sf = size(tr.ConnectivityList,1);
            if(isFullyRev)
                % If the angle of revolution is 2*pi then there would be no
                % lateral faces
                nfaces = nfaces + 2*(nn -1) + 1*2;
            else
                % If the angle of revolution is less than 2*pi
                % then the two lateral faces on both sides need to be
                % triangulated
                nfaces = nfaces + 2*sf;
            end

            F = zeros(nfaces, 3);   % Faces
                                    % Create faces
            fcnt = 1;

            for i=1:n
                next = mod(i+1,n);
                if next == 0
                    next = n;
                end
                % If this cross section point lies on axis of revolution
                if csp(i) == 1
                    % check if the next cross section point does not
                    % lie on axis of revolution.
                    if csp(next) ~= 1

                        for j=1:smf
                            F(fcnt,:) = [idx(i), idx(next)-1+j, idx(next)+j];
                            fcnt = fcnt +1;
                        end
                        if(isFullyRev)
                            F(fcnt,:) = [idx(i),idx(next)+smf, idx(next)];
                            fcnt = fcnt +1;
                        end
                    end

                    % If this cross section point does not lie on the axis
                    % of revolution
                else
                    % If next cross section point lies on the axis of
                    % revolution
                    if csp(next) == 1
                        for j=1:smf
                            F(fcnt,:) = [idx(next), idx(i)-1+j, idx(i)+j];
                            fcnt = fcnt +1;
                        end

                        % If it is a complete revolved solid, create faces
                        % joining the first and last vertex of each traced
                        % curve
                        if(isFullyRev)
                            F(fcnt,:) = [idx(next),idx(i)+smf, idx(i)];
                            fcnt = fcnt +1;
                        end

                        % If next cross section point lies on the axis of
                        % revolution
                    else
                        for j=1:smf
                            F(fcnt,:) = [idx(i)-1+j, idx(next)-1+j, idx(next)+j];
                            fcnt = fcnt +1;
                            F(fcnt,:) = [idx(i)-1+j, idx(i)+j, idx(next)+j];
                            fcnt = fcnt +1;
                        end

                        % If it is a complete revolved solid, create faces
                        % joining the first and last vertex of each traced
                        % curve
                        if(isFullyRev)
                            F(fcnt,:) = [idx(i)+smf, idx(next)+smf, idx(next)];
                            fcnt = fcnt +1;
                            F(fcnt,:) = [idx(i)+smf, idx(i), idx(next)];
                            fcnt = fcnt +1;
                        end

                    end
                end

            end

            % Create faces for lateral faces if angle of revolution less than 2pi
            for i=1:sf
                uf = tr.ConnectivityList(i, :);
                F(fcnt, :) = [left_cs(uf(1)), left_cs(uf(2)), left_cs(uf(3))];
                fcnt = fcnt +1;
                F(fcnt,:) = [right_cs(uf(1)), right_cs(uf(2)), right_cs(uf(3))];
                fcnt = fcnt +1;
            end

        end


        function [F, V] = ellipsoidMesh(radii)
        % ellipsoidMesh creates mesh for ellipsoid shape. The origin is
        % at the center of ellipsoid. The input arguments are principal
        % semiaxes along the x-, y-, and z-axes, given as 3-by-1 vector.

            xr = radii(1);    % principal semi axis along x axis
            yr = radii(2);    % principal semi axis along x axis
            zr = radii(3);    % principal semi axis along x axis

            smf = 100;        % no of faces returned by built-in ellipsoid method
            [x,y,z] = ellipsoid(0,0,0,xr,yr,zr,smf);
            [sx, sz] = size(x);

            n = 2+ (sx-2)*sx;

            %Vertices are extracted using the returned meshgrid from
            %built-in ellipsoid

            %Create vertices
            V = zeros(n, 3);
            V(1,3) = z(1,1);     % top most vertex in z direction
            V(end,3) = z(end,1); % bottom most vertex in z direction

            for i=2:length(z)-1
                V(2+(i-2)*sz: 1+(i-1)*sz,1) = x(i,:);
                V(2+(i-2)*sz: 1+(i-1)*sz,2) = y(i,:);
                V(2+(i-2)*sz: 1+(i-1)*sz,3) = z(i,:);

            end

            % Create faces
            F = zeros(2*(smf+1) + (smf-2)*(2*(smf+1)), 3);
            cnt =1;

            % faces formed by top and bottom point with neighbour trace of
            % vertices
            for i=1:smf+1
                next = i+1;
                if(i == smf+1)
                    next =1;
                end

                F(cnt,:) = [1, 1+i, 1+next];
                cnt = cnt +1;
                F(cnt, :) = [n, (n-1)-(smf +1) + i,(n-1)-(smf +1) + next ];
                cnt = cnt +1;
            end

            % all other faces
            for i = 2:smf-1

                for j = 1:smf+1
                    next = j+1;
                    if(j == smf+1)
                        next = 1;
                    end
                    F(cnt,:) = [1+(i-2)*(smf+1) + j,1+(i-1)*(smf+1) + j, 1+(i-1)*(smf+1) + next];
                    cnt = cnt +1;
                    F(cnt,:) = [1+(i-2)*(smf+1) + j,1+(i-2)*(smf+1) + next, 1+(i-1)*(smf+1) + next];
                    cnt = cnt +1;
                end

            end

        end


        function [F, V] = boxMesh(sz)
        %boxMesh Create mesh for a box shape. The origin is at the
        %   center of the box. The input arguments are the three side
        %   lengths of the box, given as a 3-by-1 vector
            xl = sz(1); yl = sz(2); zl = sz(3);

            V = [xl/2, -yl/2, -zl/2;
                 xl/2,  yl/2, -zl/2;
                 -xl/2,  yl/2, -zl/2;
                 -xl/2, -yl/2, -zl/2;
                 xl/2, -yl/2,  zl/2;
                 xl/2,  yl/2,  zl/2;
                 -xl/2,  yl/2,  zl/2;
                 -xl/2, -yl/2,  zl/2];
            F = [1 2 6;
                 1 6 5;
                 2 3 7;
                 2 7 6;
                 3 4 8;
                 3 8 7;
                 4 1 5;
                 4 5 8;
                 5 6 7;
                 5 7 8;
                 1 4 2;
                 2 4 3];

            F = robotics.core.internal.PrimitiveMeshGenerator.flipFace(F);
        end

        function [Fz, Vz] = cylinderMesh(rl)
        %cylinderMesh Create mesh for a cylinder shape. The origin is
        %   at the center of the cylinder, and the cylinder is pointing
        %   along the z axis. The input arguments are the radius and
        %   the length of the cylinder, given as a 1-by-2 vector

            r = rl(1); l = rl(2);
            N = 32;
            theta = linspace(0, 2*pi,N);
            theta = theta(1:end-1)';

            m = length(theta);

            % z-axis cylinder
            Vz = [r*cos(theta), r*sin(theta), -(l/2)*ones(m, 1)];
            Vz = [Vz;Vz];
            Vz(m+1:2*m,3) = (l/2)*ones(m, 1);
            Vz = [Vz; [ 0, 0, -l/2]; [ 0, 0, l/2] ];

            Fz = [];% CCW
                    %side
            for i = 1:m
                f = [i, i+1, m+i;        % side
                     m+i, i+1, m+i+1;    % side
                     m+i, m+i+1, 2*m+2;  % cap
                     i, 2*m+1, i+1];     % bottom
                if i==m
                    f= [m, 1, m+m;
                        m+m, 1, m+1;
                        m+m, m+1, 2*m+2;
                        m, 2*m+1, 1];
                end
                Fz = [Fz; f ]; %#ok<AGROW>
            end

            Fz = robotics.core.internal.PrimitiveMeshGenerator.flipFace(Fz);

        end

        function [F, V] = sphereMesh(r)
        %sphereMesh Create mesh for a sphere shape. The origin is
        %   at the center of the sphere. The input is the radius of the
        %   sphere.

        % using "normalized cube" approach
        % first, generating cube mesh

            n = 10;
            k = 0;
            V = [];
            F = [];
            % top
            for i = 1:n
                for j = 1:n
                    v = [-1+2*(i-1)/n,     -1+2*(j-1)/n,   1;
                         -1+2*(i-1)/n,     -1+2*(j)/n,     1;
                         -1+2*(i)/n,       -1+2*(j-1)/n,   1;
                         -1+2*(i)/n,       -1+2*(j)/n,     1];
                    f = [k+1, k+2, k+3;
                         k+3, k+2, k+4];
                    k = k+4;
                    V = [V;v];
                    F = [F; f];
                end
            end
            % bottom
            V2 = (axang2rotm([0 1 0 pi])* V')';
            % front
            V3 = (axang2rotm([0 1 0 pi/2])* V')';
            % back
            V4 = (axang2rotm([0 1 0 -pi/2])* V')';
            % left
            V5 = (axang2rotm([1 0 0 pi/2])* V')';
            % right
            V6 = (axang2rotm([1 0 0 -pi/2])* V')';

            % assemble cube
            V = [V;V2;V3;V4;V5;V6];
            F = [F; F+k; F+2*k; F+3*k; F+4*k; F+5*k];

            % combine vertices
            [V, ~, Ic]= unique(V, 'rows', 'stable');
            for i = 1:size(F, 1)
                F(i,:) = [Ic(F(i,1)), Ic(F(i,2)), Ic(F(i,3))];
            end

            % normalize to make sphere
            V = normalize(V, 2, 'norm') *r;

            F = robotics.core.internal.PrimitiveMeshGenerator.flipFace(F);
        end

        function [F,V] = capsuleMesh(L,R,p,is2D)
        %capsuleMesh Create a mesh for a capsule geometry
        %   The origin of the capsule is located at one of the centers of
        %   the hemispheres, and the positive X-axis of the capsule's frame
        %   aligns with its central line-segment.
        %
        %   Points on the sphere are generated by linearly sampling
        %   spherical coordinates. For simplicity, faces are defined as
        %   4-edge "panes" rather than triangles.

        % Represent hemisphere using slats

            if nargin == 3 && is2D == true
                % Number of points in each semicircle
                pTot = 1+2*p;

                % Create xyz points on semicircle
                tht = linspace(0,pi,1+2*p).';
                x = sin(tht)*R;
                y = cos(tht)*R;
                z = zeros(pTot,1);
            else
                % Design capsule rotationally symmetric about x axis

                % Number of "rings" along the hemisphere's x-axis
                numRings = 12;

                % Number of points in each ring
                pTot = 1+2*p;

                % Create xyz points on hemisphere
                th = linspace(0,pi/2,numRings);
                phi = linspace(2*pi,0,pTot)';
                x = ones(pTot,1)*sin(th)*R;
                y = cos(phi)*cos(th)*R;
                z = sin(phi)*cos(th)*R;
            end

            % Number of vertices in hemisphere
            nS = numel(x);

            % Combine top/bottom vertices to form ends of capsule
            if L >= 0
                V = [x(:)+L, y(:), z(:); -x(:), y(:), z(:)];
            else
                V = [-x(:)+L, y(:), z(:); x(:), y(:), z(:)];
            end

            % Define faces for hemisphere. All vertices aside from those in
            % the ring furthest from sphere-center serve as the first
            % vertex in a 4-edge face. Therefore the collection of all
            % faces in the sphere can be formed by joining each of these
            % vertices (FSphere1) with its direct neighbor and those in the
            % proceeding ring, [0, 1, pTot+1, pTot].
            FSphere1 = (1:(nS-pTot-1))';
            FSphere = FSphere1+[0,1,pTot+1,pTot];

            % Define faces for cylinder. Cylinder faces can be formed by
            % connecting each point on the first hemisphere's equator,
            % FCylinder1, with its immediate neighbor and the equatorial
            % points of the opposing hemisphere, [0,1,nS+1,nS].
            FCylinder1 = (1:(pTot-1))';
            FCylinder = FCylinder1+[0,1,nS+1,nS];

            % Represent final patch using faces
            F = [FSphere;FSphere+nS;FCylinder];
        end

        function Fo = flipFace(F)
        %flipFace Flip between CW and CCW ordering
            Fo = [F(:,1), F(:,3), F(:,2)];
        end
    end
end
