function [heading, lateralOffset, curvature, derivativeCurvature, curveLength] = fitSingleClothoid(z, tol)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.FITSINGLECLOTHOID Fit single clothoid model to a filtered set of points.
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   [HEAD, LATOFFSET, KAPPA, DKAPPA, CURVLEN] = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.FITSINGLECLOTHOID(Z,TOL)
%   fits a curve in the complex plane whose curvature varies linearly with
%   respect to distance traveled to a subset of the points in Z.  The fit
%   is truncated when the supplied tolerance is exceeded.  The tolerance
%   is scaled as a function of longitudinal distance.  The points in Z
%   should be pre-filtered to a smooth a curve and close enough together
%   to provide meaningful tangent angles

%   Copyright 2017 The MathWorks, Inc.
%#codegen

    % opportunistically start with the entire length of the data
    idxBreak = length(z);

    % pre-initialize
    heading = NaN;
    lateralOffset = NaN;
    curvature = NaN;
    derivativeCurvature = NaN;
    curveLength = NaN;
    
    while idxBreak > 1
        % make initial guess using the first and last points.
        z0 = z(1);
        z1 = z(idxBreak);
        theta0 = angle(z(2)-z(1));
        theta1 = angle(z(idxBreak)-z(idxBreak-1));
        [k0,k1,l] = matlabshared.tracking.internal.scenario.clothoidG1fit(z0,theta0,z1,theta1);
        
        % Provide MATLAB Coder hint that returned values are scalar.
        k0 = k0(1);
        k1 = k1(1);
        l = l(1);
        
        % compute curvature derivative
        dk = (k1-k0)/l;
        
        if ~isfinite(dk) || l<0.1
            % bail if can't compute
            idxBreak = 0;
        else
            % otherwise find worst offending point
            L0 = 0:0.1:l;
            [~, ~, dcp] = matlabshared.tracking.internal.scenario.fresnelgcp(z(1:idxBreak)-z0,dk,k0,theta0,L0);
            [dWorst, iWorst] = max(dcp);
            
            if iWorst>0 && dWorst > tol(iWorst)
                if idxBreak ~= iWorst
                    % try again with new point
                    idxBreak = iWorst;
                else
                    % drop offending point
                    idxBreak = iWorst - 1;
                end
            else
                % scan ahead until we break
                [~, lcp, dcp] = matlabshared.tracking.internal.scenario.fresnelgcp(z(idxBreak+1:numel(z))-z0,dk,k0,theta0,L0);
                for i=idxBreak+1:numel(z)
                    if dcp(i-idxBreak) < tol(i)
                       l = lcp(i-idxBreak);
                    else
                        break
                    end
                end

                % good-to-go
                outL0 = -abs(z0):0.1:0;
                [zcp, lcp] = matlabshared.tracking.internal.scenario.fresnelgcp(-z0,dk,k0,theta0,outL0);
                zcp = zcp(1);
                lcp = lcp(1);
                zcp = zcp + z(1);
                
                % return outputs
                heading = rad2deg(theta0 + lcp.^2*dk/2 + lcp.*k0);
                lateralOffset = abs(zcp) * sign(imag(zcp));
                curvature = rad2deg(k0+dk*lcp);
                derivativeCurvature = rad2deg(dk);
                curveLength = l-lcp;
                return
            end
        end
    end        
end
