classdef Sim3Helpers < robotics.core.internal.InternalAccess
    %This class is for internal use only. It may be removed in the future.
    
    %SIM3HELPERS Helper utilities around elements in similarity lie algebra groups
    %
    %   References: 
    %   [1] Ethan Eade, "Lie groups for 2D and 3D Transformations", October 2018
    %   http://ethaneade.com/lie.pdf
    
    %   Copyright 2019 The MathWorks, Inc.
    
    %#codegen
    
    properties (Constant)
        %ZeroTolerance Threshold around zero to consider the axis angle 0.
        %This threshold was empirically chosen similar to g2o library. 
        ZeroTolerance = 1e-5;
        
        %JacobianPerturbation small increment to compute x+ and x- useful for
        %computing numerical jacobian
        JacobianPerturbation = 1e-9;
    end
    
    % Sim3
    methods (Static)
        function S = poseVecToSformSim3(poseVec)
            %poseVecToSformSim3 converts poseVec (1-by- 8 Sim3 vector form
            %   [x, y, z, qw, qx, qy, qz, scale]) to S (4-by-4 similarity
            %   transformation matrix form [R,t;0,scale])
            
            xyz = poseVec(1:3);
            q = poseVec(4:7);
            S = trvec2tform(xyz)*quat2tform(q);
            if length(poseVec) >7
                S(4,4) = poseVec(8);
            end    
        end
        
        function poseVec = sformToPoseVecSim3(S)
            %sformToPoseVecSim3 converts S (4-by-4 similarity
            %   transformation matrix form [R,t;0,scale]) to poseVec (1-by-
            %   8 Sim3 vector form [x, y, z, qw, qx, qy, qz, scale])
            
            R = S(1:3, 1:3);
            q = tform2quat(blkdiag(R, 1));
            t = S(1:3,4);
            s = (S(4,4));
            poseVec = [t', q, s];
        end
        
        function [Sinv] = sforminvSim3(S)
            %sforminvSim3 inverts a 4-by-4 3D Similarity
            %   transformation matrix S ([R,t;0,scale])
            
            R = S(1:3,1:3)';
            p = -(R*S(1:3,4))/S(4,4);
            newS = 1/S(4,4);
            Sinv = [R,    p; ...
                [0 0 0 newS]];
            
        end
        
        function A = hatsim3(e)
            %hatsim3 coverts 1-by-7 sim3 minimal representation vector to
            %   4-by-4 matrix form.
            
            A = robotics.core.internal.SEHelpers.hatse3(e(1:6));
            A(4,4) = e(7);
        end
        
        function [S] = sformMultiplySim3(S1,S2)
            %sformMultiplySim3 computes an efficient multiplication between
            %   two similarity transforms in 4-by-4 matrix form
            
            R = S1(1:3,1:3)*S2(1:3,1:3);
            t = S1(4,4)*S1(1:3,1:3)*S2(1:3,4) + S1(1:3,4);
            s = S1(4,4)*S2(4,4);
            S = [R,    t; ...
                [0 0 0 s]];
        end
        
        function adS = adjointSim3(S)
            %adjointSim3 sends S in Sim(3) to a automorphism in sim(3). 
            %   adS - Adjoint representation of Sim3 Group.
            
            R = S(1:3, 1:3);
            t = S(1:3,4);
            s = S(4,4);
            adS = [R/s, (robotics.core.internal.SEHelpers.skew(t)*R)/s,-t/s; zeros(3), R,zeros(3,1);zeros(1,6),1];
        end
        
        function [vec] = veelogmSim3(S)
            %veelogmSim3 converts an Sim3 transformation into its Lie algebra
            %   in minimal vector representation form.
            
            s = S(4,4);
            t = S(1:3,4);
            R = S(1:3,1:3);
            sigma = log(S(4,4));
            epsth = robotics.core.internal.Sim3Helpers.ZeroTolerance;
            d = 0.5*(R(1,1)+R(2,2)+R(3,3)-1);
            if abs(sigma) < epsth
                c = 1-(sigma/2);
                if d > (1-epsth)
                    omega1 = 0.5*robotics.core.internal.SEHelpers.veeso3(R-R');
                    omega2 = robotics.core.internal.SEHelpers.skew(omega1);
                    a = 1/2;
                    b = 1/6;
                else
                    th = acos(d);
                    thSquare = th*th;
                    omega1 = (th/(2*sqrt(1-d*d)))*robotics.core.internal.SEHelpers.veeso3(R-R');
                    omega2 = robotics.core.internal.SEHelpers.skew(omega1);
                    a = (1-cos(th))/thSquare;
                    b = (th-sin(th))/(thSquare*th);
                end
            else
                c = (s-1)/sigma;
                if d > (1-epsth)
                    sigmaSquare = sigma*sigma;
                    omega1 = 0.5*robotics.core.internal.SEHelpers.veeso3(R-R');
                    omega2 = robotics.core.internal.SEHelpers.skew(omega1);
                    a = (((sigma-1)*s)+1)/(sigmaSquare);
                    b = ((0.5*sigmaSquare-sigma+1)*s-1)/(sigmaSquare*sigma);
                else
                    th = acos(d);
                    omega1 = (th/(2*sqrt(1-d*d)))*robotics.core.internal.SEHelpers.veeso3(R-R');
                    omega2 = robotics.core.internal.SEHelpers.skew(omega1);
                    thSquare = th*th;
                    a1 = s*sin(th);
                    b1 = s*cos(th);
                    c1 = thSquare + (sigma*sigma);
                    a = (a1*sigma + (1-b1)*th)/(th*c1);
                    b = (c - ((((b1-1)*sigma) + (a1*th))/c1))/thSquare;
                end
            end
            w = a*omega2 + b*omega2*omega2 + c*eye(3);
            u = (eye(3)/w)*t;
            vec = [u;omega1;sigma];
        end
        
        function S = sim3ToSform(minVecSim3)
            %sim3ToSform computes the exponential map of minVecSim3 (sim(3)
            %   lie algebra in minimal vector 1-by-7) and returns it in
            %   4-by-4 similarity transformation matrix form
            
            omega = minVecSim3(4:6);
            u = minVecSim3(1:3);
            sigma = minVecSim3(7);
            w = robotics.core.internal.SEHelpers.skew(omega);
            th = norm(omega);
            s = exp(sigma);
            wSquare = w*w;
            epsth = robotics.core.internal.Sim3Helpers.ZeroTolerance;
            if abs(sigma) < epsth
                c = 1;
                if th < epsth
                    % for small lambda a = (1-cos(th))/thSquare
                    % for small th using L’Hospital’s Rule a = 1/2
                    a = 1/2;
                    % for small lambda b = (1 - (sin(th)/thSquare))/thSquare
                    % for small th using L’Hospital’s Rule b = 1/6
                    b = 1/6;
                    R = eye(3) + w + wSquare/2;
                else
                    thSquare = th*th;
                    a = (1-cos(th))/thSquare;
                    b = (th - sin(th))/(thSquare*th);
                    R = eye(3) + (sin(th)/th)*w + ((1-cos(th))/(thSquare))*wSquare;
                end
            else
                c = (s-1)/sigma;
                if th < epsth
                    sigmaSquare = sigma*sigma;
                    a = ((sigma-1)*s+1)/sigmaSquare;
                    b = ((0.5*sigmaSquare-sigma+1)*s-1)/(sigmaSquare*sigma);
                    R = eye(3) + w + wSquare/2;
                else
                    a1 = s*sin(th);
                    b1 = s*cos(th);
                    thSquare = th*th;
                    sigmaSquare = sigma*sigma;
                    c1 = thSquare+sigmaSquare;
                    a = (a1*sigma+ (1-b1)*th)/(th*c1);
                    b = (c-(((b1-1)*sigma+a1*th)/c1))/(thSquare);
                    R = eye(3) + (sin(th)/th)*w + ((1-cos(th))/(thSquare))*wSquare;
                end
            end
            Rd = a*w + b*wSquare + c*eye(3);
            t = Rd*u;
            S = [R,t;zeros(1,3),s];
        end
        
        function poseVec = accumulatePoseVecSim3(poseVec0, relPoseVec)
            %accumulatePoseVecSim3 multiplies two similarity transforms in
            %   1-by-8 vector form and returns the result in vector form 
            %   (poseVec = poseVec0*relPoseVec).
            
            S0 = robotics.core.internal.Sim3Helpers.poseVecToSformSim3(poseVec0);
            Sd = robotics.core.internal.Sim3Helpers.poseVecToSformSim3(relPoseVec);
            S = robotics.core.internal.Sim3Helpers.sformMultiplySim3(S0,Sd);
            poseVec = robotics.core.internal.Sim3Helpers.sformToPoseVecSim3(S);
        end
        
        function [Jaci,Jacj] = computeNumericalJacobianSim3(Sji,Soi,Soj)
            %computeNumericalJacobianSim3 computes jacobian of the residual
            %   r w.r.t left Soi and Soj using a numerical method.
            %   (r = Sij*inv(Soi)*Soj).
            
            Jaci = zeros(7);
            Jacj = zeros(7);
            delta = robotics.core.internal.Sim3Helpers.JacobianPerturbation;
            scalar = 1/(2*delta);
            Sio = robotics.core.internal.Sim3Helpers.sforminvSim3(Soi);
            for k = 1:7
                deltavec = zeros(7,1);
                deltavec(k) = delta;
                deltatform = robotics.core.internal.Sim3Helpers.sforminvSim3(robotics.core.internal.Sim3Helpers.sim3ToSform(deltavec));
                Siox = robotics.core.internal.Sim3Helpers.sforminvSim3(robotics.core.internal.Sim3Helpers.sformMultiplySim3(Soi,deltatform));
                Sojy = robotics.core.internal.Sim3Helpers.sformMultiplySim3(Soj,deltatform);
                er1 = robotics.core.internal.Sim3Helpers.multiplyLogSim3(Sji,Siox,Soj);
                er2 = robotics.core.internal.Sim3Helpers.multiplyLogSim3(Sji,Sio,Sojy);
                deltavec(k) = -delta;
                deltatform = robotics.core.internal.Sim3Helpers.sforminvSim3(robotics.core.internal.Sim3Helpers.sim3ToSform(deltavec));
                Siox = robotics.core.internal.Sim3Helpers.sforminvSim3(robotics.core.internal.Sim3Helpers.sformMultiplySim3(Soi,deltatform));
                Sojy = robotics.core.internal.Sim3Helpers.sformMultiplySim3(Soj,deltatform);
                er3 = robotics.core.internal.Sim3Helpers.multiplyLogSim3(Sji,Siox,Soj);
                er4 = robotics.core.internal.Sim3Helpers.multiplyLogSim3(Sji,Sio,Sojy);
                Jaci(:,k) = (er1-er3)*scalar;
                Jacj(:,k) = (er2-er4)*scalar;
            end
        end
        
        function e = multiplyLogSim3(S1,S2,S3)
            S12 = robotics.core.internal.Sim3Helpers.sformMultiplySim3(S1,S2);
            S123 = robotics.core.internal.Sim3Helpers.sformMultiplySim3(S12,S3);
            e = robotics.core.internal.Sim3Helpers.veelogmSim3(S123);
        end
        
        
        function infoMat = deserializeInformationMatrixSim3(im)
            %deserializeInformationMatrixSim3 Restore compact information
            %   matrix to full matrix. Expecting the input to be a 28-vector
            
            infoMat = [im(1) im(2)  im(3)  im(4)  im(5)  im(6) im(7);
                       im(2) im(8)  im(9)  im(10)  im(11) im(12) im(13);
                       im(3) im(9)  im(14) im(15) im(16) im(17) im(18);
                       im(4) im(10) im(15) im(19) im(20) im(21) im(22);
                       im(5) im(11) im(16) im(20) im(23) im(24) im(25);
                       im(6) im(12) im(17) im(21) im(24) im(26) im(27);
                       im(7) im(13) im(18) im(22) im(25) im(27) im(28)];
        end
        
        function im = serializeInformationMatrixSim3(infoMat)
            %serializeInformationMatrixSim3 Flatten the information matrix
            %   into the compact vector form. Expecting the input to be
            %   a 7-by-7 matrix
            
            im = [infoMat(1), infoMat(8), infoMat(15), infoMat(22), infoMat(29), infoMat(36), infoMat(43), ...
                              infoMat(9), infoMat(16), infoMat(23), infoMat(30), infoMat(37), infoMat(44),...
                                          infoMat(17), infoMat(24), infoMat(31), infoMat(38), infoMat(45),...
                                                       infoMat(25), infoMat(32), infoMat(39), infoMat(46),...
                                                                    infoMat(33), infoMat(40), infoMat(47),...
                                                                                 infoMat(41), infoMat(48),...
                                                                                              infoMat(49)];
        end
    end
    
end

