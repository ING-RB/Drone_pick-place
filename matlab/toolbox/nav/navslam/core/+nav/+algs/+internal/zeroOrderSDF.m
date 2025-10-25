classdef zeroOrderSDF < nav.algs.internal.SDFImplBase
%This class is for internal use only. It may be removed in the future.

%ZEROORDERSDF Utility class for storing discrete signed distance and 
% nearest-neighbor information over a 2D region of space. This class serves
% as the back-end to signedDistanceMap when InterpolationMethod = "none".

% Copyright 2022 The MathWorks, Inc.

    %#codegen

    methods
        function [dist, inBounds] = distanceImpl(obj, varargin)
            if nargout > 1
                [dist,inBounds,isGrid] = obj.Dist.getMapDataImpl(varargin{:});
            else
                [dist,~,isGrid] = obj.Dist.getMapDataImpl(varargin{:});
            end
            if isGrid
                dist = dist*obj.Dist.Resolution;
            end
        end

        function [gradient,isValid] = gradientImpl(obj, varargin)
            if nargout > 1
                [gradient, isValid] = obj.Grad.getMapDataImpl(varargin{:});
            else
                gradient = obj.Grad.getMapDataImpl(varargin{:});
            end
        end
        
        function updateSDF(obj,mat)
            % Generate SDF
            [SSD,idx] = nav.algs.internal.signedSquareDistance(mat);
            mapIdx = double(idx);
            mapIdx(idx == 0) = nan;

            % Update internal data
            SD = sign(SSD).*sqrt(abs(SSD))/obj.Dist.Resolution;
            obj.Dist.setMapData(SD);
            obj.Idx.setMapData(mapIdx);
        end
    end
end