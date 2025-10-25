classdef SEHelpers < robotics.core.internal.InternalAccess
    %This class is for internal use only. It may be removed in the future.
    
    %SEHELPERS Helper utilities around elements in special Euclidean groups
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    
    %#codegen
    
    % SE2
    methods (Static)
        function T = poseToTformSE2(pose)
            %poseToTformSE2
            x = pose(1);
            y = pose(2);
            theta = pose(3);
            T = [cos(theta), -sin(theta), x; sin(theta), cos(theta), y; 0 0 1];
        end
        
        function pose = tformToPoseSE2(T)
            %tformToPoseSE2
            theta = atan2(T(2,1), T(1,1));
            pose = [T(1,3), T(2,3), theta];
        end
        
        function pose = accumulatePoseSE2(pose0, relPose)
            %accumulatePoseSE2
            T0 = robotics.core.internal.SEHelpers.poseToTformSE2(pose0);
            Td = robotics.core.internal.SEHelpers.poseToTformSE2(relPose);
            T = T0*Td;
            pose = robotics.core.internal.SEHelpers.tformToPoseSE2(T);
        end
        
        function Tinv = tforminvSE2(T)
            %tforminvSE2
            R = T(1:2,1:2)';
            p = -R*T(1:2,3);
            Tinv = [R,    p; ...
                [0 0  1]];
        end

        function poseInv = poseInvSE2(pose)
            %poseInvSE2
            x = -pose(1);
            y = -pose(2);
            theta = pose(3);
            poseInv = [x*cos(theta) + y*sin(theta), ...
                -x*sin(theta) + y*cos(theta), ...
                -theta];
        end
        
        function infoMat = deserializeInformationMatrixSE2(im)
            %deserializeInformationMatrixSE2 Restore compact information
            %   matrix for SE(2) pose measurement to full matrix. Expecting
            %   the input to be a 6-vector
            infoMat = [im(1) im(2) im(3); im(2) im(4) im(5); im(3) im(5) im(6)];
        end

        function infoMat = deserializeInformationMatrixPoint2(im)
            %deserializeInformationMatrixPoint2 Restore compact information
            %   matrix for Point in R2 to full matrix. Expecting the input
            %   to be a 3-vector
            infoMat = [im(1) im(2); im(2) im(3)];
        end

        function im = serializeInformationMatrixSE2(infoMat)
            %serializeInformationMatrixSE2 Flatten the information matrix
            %   associated with SE(2) pose measurement into the compact 
            %   vector form. Expecting the input to be a 3-by-3 matrix
            %
            im = [infoMat(1), infoMat(4), infoMat(7), infoMat(5), infoMat(8), infoMat(9)];
        end

        function im = serializeInformationMatrixPoint2(infoMat)
            %serializeInformationMatrixPoint2 Flatten the information matrix
            %   associated with landmark observation (Point 2) into the 
            %   compact vector form. Expecting the input to be a
            %   2-by-2 matrix
            im = [infoMat(1), infoMat(3), infoMat(4)];
        end
        
        
        function M = hatse2(increment)
            %hatse2 Convert a compact 3x1 vector to its lie algebra form se(2)
            M = [0           -increment(3) increment(1);
                increment(3)             0 increment(2);
                0                        0            0];
        end
        
        function w = veeso2(R)
            %veeso2 Convert lie algebra of SO2 to minimal vector representation
            w = -R(1,2);
        end
        
        function theta = veelogmSO2(R)
            %veelogmSO2 Compute matrix logarithm then apply the vee operator
            theta = atan2(R(2,1), R(1,1));
        end
                
        function [vec, pseudoVec] = veeLogmSE2(T)
            %veeLogmSE2 "Lift" an element x in SE(3) manifold to an  
            %   element in the tangent space of x and then represent it 
            %   in minimal vector representation form.
            t = T(1:2,3);
            w = robotics.core.internal.SEHelpers.veelogmSO2(T(1:2,1:2));
            pseudoVec = [t; w];
            
            if abs(w) < 100*eps
                p = 1;
                q = 0;
            else
                p = sin(w)/w;
                q = (1-cos(w))/w;
            end
            Vinv = 1/(p*p+q*q)*[p q; -q p];
            vec = [Vinv\t; w];
        end
        
        function vec = veese2(A)
            %veese2 Convert element of se(2) to minimal vector representation
            
            w = robotics.core.internal.SEHelpers.veeso2(A(1:2,1:2));
            t = A(1:2,3);

            vec = [t; w];
        end
        
    end
    
    
    % SE3
    methods (Static)
        function T = poseToTformSE3(pose)
            %poseToTformSE3
            xyz = pose(1:3);
            q = pose(4:7);
            T = trvec2tform(xyz)*quat2tform(q);
        end
        
        function pose = tformToPoseSE3(T)
            %tformToPoseSE3
            R = T(1:3, 1:3);
            q = tform2quat(blkdiag(R, 1));
            t = T(1:3,4);
            pose = [t', q];
        end
        
        function Tinv = tforminvSE3(T)
            %tforminvSE3 Efficiently invert an SE3 transformation
            %   This one is equivalent to robotics.manip.internal.tforminv
            R = T(1:3,1:3)';
            p = -R*T(1:3,4);
            Tinv = [R,    p; ...
                [0 0 0 1]];
        end

        
        function pcross = skew(p)
            %skew Convert the cross product of a 3D vector into a skew symmetric matrix
            %   This one is equivalent to robotics.manip.internal.skew
            %   We can also call this method hatso3
            pcross = [0, -p(3), p(2); p(3), 0, -p(1); -p(2), p(1), 0];
            
        end
        
        function M = hatse3(e)
            %hatse3 Convert a compact 6x1 vector to the matrix form for lie algebra of SE3
            t = e(1:3);
            phi = e(4:6);
            M = [robotics.core.internal.SEHelpers.skew(phi), t; [0 0 0 0]];
        end
        
        function T = pseudoExpSE3hat(e)
            %pseudoExpSE3hat
            t = e(1:3);
            phi = e(4:6);
            Sphi = robotics.core.internal.SEHelpers.skew(phi);
            T = [expm(Sphi), t; [0 0 0 1]];
        end
 
        function T = expSE3hat(e)
            %expSE3hat Retract a compact 6x1 vector in tangent space at
            %   origin to the neighborhood in SE3 manifold (R_I)
            t = e(1:3);
            phi = e(4:6);
            Sphi = robotics.core.internal.SEHelpers.skew(phi);
            theta = norm(phi);
            thetaSq = theta*theta;
            b = (1 - cos(theta))/thetaSq;
            c = (theta - sin(theta))/(thetaSq*theta);
            if abs(b) < eps || ~isfinite(b)
                V = eye(3);
                R = eye(3);
            else
                V = eye(3) +  b*Sphi + c*Sphi*Sphi;
                R = eye(3) + Sphi*sin(theta)/theta + Sphi*Sphi/thetaSq*(1-cos(theta)); % Rodrigues' formula
            end
            T = [R, V*t; [0 0 0 1]];
        end

        
        function AdT = adjointSE3(T)
            %AdSE3 Adjoint representation of SE3 Group.
            %   adjointSE3 sends T in SE(3) to a automorphism in se(3)
            
            R = T(1:3, 1:3);
            t = T(1:3,4);
            AdT = [R, robotics.core.internal.SEHelpers.skew(t)*R; zeros(3), R];
        end
        
        function w = veeso3(R)
            %veeso3 convert lie algebra of SO3 to minimal vector representation
            %   This is the inverse of the skew operation
            w = [R(3,2); R(1,3); R(2,1)];
        end
        
        function w = veelogmSO3(R)
            %veeLogmSO3 uses Roderigues' formula to convert an SO3 transformation
            %   into its Lie algebra in minimal vector representation form.
            theta = real(acos(complex((1/2)*(R(1,1,:)+R(2,2,:)+R(3,3,:)-1))));
            
            a = theta/sin(theta);
            wx = (R-R');
            w = robotics.core.internal.SEHelpers.veeso3(wx);
            if (isfinite(a))&&(~(all(w==0,1)))
                w = w*a/2;
            else
                % Rotation of 0 or pi around the axis
                [~,~,V] = svd(eye(3)-R);
                wv = robotics.internal.normalizeRows(V(:,end)');
                w = (wv')*theta;
            end
        end
        
        function pseudoVec = pseudoVeeLogmSE3(T)
            %pseudoVeeLogmSE3 The returned PSEUDOVEC is the "lift"
            %   corresponding to the alternative retraction for SE3
            %   (i.e. the non-exponential-map)
            t = T(1:3,4);
            w = robotics.core.internal.SEHelpers.veelogmSO3(T(1:3,1:3));
            pseudoVec = [t; w]; % pseudo-logarithm, to be paired with pseudo-exponential
        end
        
        function [vec, pseudoVec] = veelogmSE3(T)
            %veeLogmSE3 converts an SE3 transformation into its Lie algebra
            %   in minimal vector representation form.
            t = T(1:3,4);
            w = robotics.core.internal.SEHelpers.veelogmSO3(T(1:3,1:3));
            pseudoVec = [t; w]; % pseudo-logarithm, to be paired with pseudo-exponential
            
            theta = sqrt(w'*w);
            thetaSq = theta*theta;
            
            a = sin(theta)/theta;
            b = (1 - cos(theta))/thetaSq;
            if abs(b) < eps || ~isfinite(b)
                Vinv = eye(3);
            else
                wx = robotics.core.internal.SEHelpers.skew(w);
                wxSq = wx*wx;
                
                Vinv = eye(3) -0.5*wx + (1/thetaSq)*(1 - a/(2*b))*wxSq; % closed form inverse of V
            end
            u = Vinv * t;
            vec = [u; w];
        end
        
        function vec = veese3(A)
            %veese3 convert lie algebra of SE3 to minimal vector representation
            t = A(1:3,4);
            w = robotics.core.internal.SEHelpers.veeso3(A(1:3,1:3));
            vec = [t; w];
            
        end
        
        function pose = accumulatePoseSE3(pose0, relPose)
            %accumulatePoseSE3
            T0 = robotics.core.internal.SEHelpers.poseToTformSE3(pose0);
            Td = robotics.core.internal.SEHelpers.poseToTformSE3(relPose);
            T = T0*Td;
            pose = robotics.core.internal.SEHelpers.tformToPoseSE3(T);
        end
        
        
        function infoMat = deserializeInformationMatrixSE3(im)
            %deserializeInformationMatrixSE3 Restore compact information
            %   matrix for SE(3) pose observation to full matrix. Expecting
            %   the input to be a 21-vector
            infoMat = [im(1) im(2)  im(3)  im(4)  im(5)  im(6);
                       im(2) im(7)  im(8)  im(9)  im(10) im(11);
                       im(3) im(8)  im(12) im(13) im(14) im(15);
                       im(4) im(9)  im(13) im(16) im(17) im(18);
                       im(5) im(10) im(14) im(17) im(19) im(20);
                       im(6) im(11) im(15) im(18) im(20) im(21)];
        end
        
        function infoMat = deserializeInformationMatrixPoint3(im)
            %deserializeInformationMatrixPoint3 Restore compact information
            %   matrix associated with 3D Point observation to full matrix.
            %   Expecting the input to be a 6-vector
            infoMat = [im(1) im(2) im(3); im(2) im(4) im(5); im(3) im(5) im(6)];
        end
        
        function im = serializeInformationMatrixSE3(infoMat)
            %serializeInformationMatrixSE3 Flatten the information matrix
            %   into the compact vector form. Expecting the input to be
            %   a 6-by-6 matrix
            im = [infoMat(1), infoMat(7), infoMat(13), infoMat(19), infoMat(25), infoMat(31), ...
                              infoMat(8), infoMat(14), infoMat(20), infoMat(26), infoMat(32), ...
                                          infoMat(15), infoMat(21), infoMat(27), infoMat(33), ...
                                                       infoMat(22), infoMat(28), infoMat(34), ...
                                                                    infoMat(29), infoMat(35), ...
                                                                                 infoMat(36)];
        end
        
        function im = serializeInformationMatrixPoint3(infoMat)
            %serializeInformationMatrixPoint3 Flatten the information matrix
            %   associated with 3D landmark observation (Point 3) into the 
            %   compact vector form. Expecting the input to be a
            %   3-by-3 matrix
            im = [infoMat(1), infoMat(4), infoMat(7), infoMat(5), infoMat(8), infoMat(9)];
        end
    end
    
end

