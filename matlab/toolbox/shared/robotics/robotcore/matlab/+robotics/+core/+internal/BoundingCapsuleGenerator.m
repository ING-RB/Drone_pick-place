classdef BoundingCapsuleGenerator
%This class is for internal use only, and maybe removed in the future

%BoundingCapsuleGenerator Generates a bounding capsule of a convex geometry.
%   The class provides utilities to compute a tightly fitting capsule over a
%   primitive or a mesh geometry.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen
    methods(Static)
        function [cap,residual]=boundingCapsuleOfBox(x,y,z)
        %boundingCapsuleOfBox Create a bounding capsule of a box
        %   An axis-aligned bounding box is specified by its X,Y,Z axis
        %   extents.
            dim=[x,y,z];
            [maxdim,argmaxdim]=max(dim);
            length=maxdim;
            capsuledir=zeros(size(dim));
            capsuledir(argmaxdim)=1;
            planardims=dim(capsuledir==0);
            radius=max(norm(planardims)/2,eps);
            cap=collisionCapsule(radius,length);
            cap.Pose(1:3,1:3)=circshift(eye(3),3-argmaxdim,2);
            residual=repmat(radius,8,1);
        end

        function [cap,residual]=boundingCapsuleOfCylinder(radius,length)
        %boundingCapsuleOfCylinder Create a bounding capsule of a cylinder
        %   A cylinder's dimensions are its radius and length.

        % There could be two options in case of a cylinder.

        % Case 1: The bounding sphere is a better fit
            radiusBoundingSphere=norm([length/2,radius]);
            Vsphere=4/3*pi*radiusBoundingSphere^3;

            % Case 2: The capsule of radius and length is a better fit
            Vcapsule=4/3*pi*radius^3+pi*radius^2*length;
            if(Vsphere>Vcapsule)
                cap=collisionCapsule(radius,length);
                residual=radius;
            else
                cap=collisionCapsule(radiusBoundingSphere,0);
                residual=radiusBoundingSphere;
            end
        end

        function [cap,residual]=boundingCapsuleOfSphere(radius)
        %boundingCapsuleOfSphere Create a bounding capsule of a sphere
            cap=collisionCapsule(radius,0);
            residual=radius;
        end

        function [cap,residual]=boundingCapsuleOfMesh(vertices)
        %boundingCapsuleOfMesh Create a bounding capsule of a mesh
            p=vertices;
            [o,d]=robotics.core.internal.BoundingCapsuleGenerator.fitline(p);

            % Compute the perpendicular projection vectors of vertices on the
            % line (o,d)
            projvec=-((p-o)-(p-o)*d'.*d);
            normprojvec=vecnorm(projvec,2,2);

            % Radius of a bounding capsule should be positive
            radius=max(max(normprojvec),eps);

            % Compute the projected points of vertices on the line (o,d)
            projections=p+projvec;

            % Note the parametric equation of a line is of the form
            %           p = o + t*d
            %
            %   Where ,
            %
            %   "p" is a point on the line corresponding to parameter "t",
            %   given a point "o" on the line and a direction vector "d".
            %
            % Compute the parameter values of the projections.
            basisdir=(find(d~=0,1));
            t_=(projections(:,basisdir)-o(basisdir))/d(basisdir);

            % Compute the distance of the radial projection of the vertices
            % from their perpendicular projection.
            r = sqrt(radius^2-normprojvec.^2);

            % Find the parameter corresponding to the radial projections
            t=t_-sign(t_).*r;

            % Compute the extent of the capsule.
            % For radial projection parameters value corresponding to positive
            % perpendicular projection parameter values.
            radialpos=t(t_>=0);
            radialneg=t(t_<=0);
            maxT=max(radialpos);
            minT=min(radialneg);

            % Capsule's length is non-negative
            length=max(maxT-minT,0);


            cap=collisionCapsule(radius,length);

            % The capsule's origin is at the center of the minT and maxT
            % points
            cap.Pose(1:3,end)=((o+minT*d)+(o+maxT*d))/2;

            % The Z-axis of the capsule's frame corresponds to the line's
            % direction. Since this is a line, we want to fix the direction such
            % that it makes an acute angle with its first non-zero component's
            % direction i.e., the basisdir.
            zaxis=d*sign(d(basisdir(1)));

            % Find two orthogonal basis given a Z-axis, and form a valid
            % rotation matrix.
            if(d(1) == 0)
                xaxis=[1,0,0];
            elseif(d(1) ~= 0 && d(2) == 0)
                xaxis=[0,1,0];
            else
                xaxis=[-d(2),d(1),0];
                xaxis=xaxis/norm(xaxis);
            end
            yaxis=cross(zaxis,xaxis);
            cap.Pose(1:3,1:3)=[xaxis',yaxis',zaxis'];
            residual=normprojvec;
        end

        function [o,d]=fitline(vertices)
            p=vertices;
            o=mean(p,1);
            [~,~,V]=svd(p-o,'econ');
            d=normalize(V(:,1)',2,'norm');
        end

    end
    methods(Access=private,Static)
        function debugprojections(p,cap,o,t,d,projections,minT,maxT)
            [~,pobj]=show(collisionMesh(p));
            pobj.FaceAlpha=0.3;
            pobj.EdgeAlpha=0.0;
            hold on;
            radialprojections=o+t.*d;
            theline=[o-1.3*d;
                     o+1.3*d];
            plot3(theline(:,1),theline(:,2),theline(:,3),'g-','MarkerSize',3)
            plot3(theline(2,1),theline(2,2),theline(2,3),'kx','MarkerSize',8)
            plot3(p(:,1),p(:,2),p(:,3),'b*','MarkerSize',3)
            plot3(o(1),o(2),o(3),'r*','MarkerSize',8);
            for(i=1:size(projections,1))
                toplot=[p(i,:);
                        projections(i,:)];
                plot3(toplot(:,1),toplot(:,2),toplot(:,3),'k-');
            end
            for(i=1:size(projections,1))
                toplot=[p(i,:);
                        radialprojections(i,:)];
                plot3(toplot(:,1),toplot(:,2),toplot(:,3),'b-','LineWidth',1);
            end
            pminT=o+minT*d;
            pmaxT=o+maxT*d;
            plot3(pminT(:,1),pminT(:,2),pminT(:,3),'k*','MarkerSize',12);
            plot3(pmaxT(:,1),pmaxT(:,2),pmaxT(:,3),'k*','MarkerSize',12);
            [~,pobj]=show(cap);
            pobj.FaceAlpha=0.1;
            pobj.EdgeAlpha=0.1;
            hold off;
        end
    end

end
