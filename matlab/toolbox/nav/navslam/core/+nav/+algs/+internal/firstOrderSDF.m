classdef firstOrderSDF < nav.algs.internal.SDFImplBase
%This class is for internal use only. It may be removed in the future.

%FIRSTORDERSDF Utility class storing signed distance, nearest-neighbor, and
% gradient information over a 2D region of space. This class serves
% as the back-end to signedDistanceMap when InterpolationMethod = "linear"
% and performs bilinear interpolation when calculating distance.

% Copyright 2022-2023 The MathWorks, Inc.

    %#codegen

    properties
        %Interpolant Linear interpolant for 1st-order distance function
        Interpolant
    end

    methods
        function obj = firstOrderSDF(mat,sharedProps)
            % Construct base class
            obj = obj@nav.algs.internal.SDFImplBase(mat,sharedProps);

            % Create linear interpolant for distance
            [x,y] = obj.Dist.createInterpVectors('l');
            x = x-obj.Dist.GridOriginInLocal(1);
            y = y-obj.Dist.GridOriginInLocal(2);
            coder.internal.errorIf(any(sharedProps.GridSize < 2),'nav:navalgs:signeddistancemap:AtLeast2x2Grid');
            obj.Interpolant = griddedInterpolant({y,x},zeros(sharedProps.GridSize),'linear');
        end

        function [dist, isValid] = distanceImpl(obj, varargin)
            if isempty(varargin)
                dist = obj.Dist.getMapDataImpl(varargin{:});
            else
                [isValid, matSize, isGrid, isLocal] = getParser(obj.Dist, 'distance', varargin{:});
                if isempty(matSize)
                    % Points
                    if isGrid
                        pts = obj.Dist.grid2localImpl(varargin{1});
                    elseif isLocal
                        pts = varargin{1};
                    else
                        pts = obj.Dist.world2localImpl(varargin{1});
                    end
                    outSize = [size(pts,1) 1];
                    m = isValid;
                else
                    % Convert block to discrete set of local XY points
                    if nargin < 4
                        frame = 'w';
                    else
                        frame = char(varargin{3});
                    end
                    [XX,YY,m] = obj.Dist.block2localPoints(varargin{1},varargin{2},frame);
                    pts = [XX(:) YY(:)];
                    outSize = size(XX);
                end

                dist = nan(outSize);

                % Evaluate points in interpolant
                pts = pts-obj.Dist.GridOriginInLocal;
                dist(m(:)) = obj.Interpolant(pts(m(:),2),pts(m(:),1));
                if isGrid
                    dist = dist*obj.Dist.Resolution;
                end
            end
        end
        
        function [gradient,isValid] = gradientImpl(obj, varargin)
            if isempty(varargin)
                % Gradients lie at cell-centers, use simple lookup
                gradient = obj.Grad.getMapDataImpl(varargin{:});
            else
                [isValid, matSize, isGrid, isLocal] = getParser(obj.Grad, 'distance', varargin{:});
                if ~isempty(matSize)
                    % Block queries return data at cell centers
                    gradient = obj.Grad.getMapDataImpl(varargin{:});
                else
                    % Convert points to local coordinates
                    if isGrid
                        pts = obj.Grad.grid2localImpl(varargin{1});
                    elseif isLocal
                        pts = varargin{1};
                    else
                        pts = obj.Grad.world2localImpl(varargin{1});
                    end

                    % Calculate outputs size
                    outSize = [size(pts,1) 1 2];
                    m = isValid;
                    gradient = nan(outSize);

                    % Evaluate gradient using interpolant
                    gradient(m(:),1,:) = obj.bilinearGradient(pts(m(:),:));
                end
                if isGrid
                    % Conversion from XY->IJ consists of swapping the XY
                    % channels, scaling them by resolution, and negating 
                    % the I channel (since the +I axis points along the 
                    % -Y axis)
                    gradient = circshift(gradient*obj.Grad.Resolution,1,3);
                    gradient(:,:,1) = -gradient(:,:,1);
                end
            end
        end

        function gXY = bilinearGradient(obj,xyLocal)
        %bilinearGradient Gradient of bilinearly interpolated surface
        %
        %   xyLocal : Nx2 matrix of query-points in local coordinates
        %
        %   First compute 4 points forming the quadrant of the cell which 
        %   bounds its corresponding query-point, xyLocal. The gradient 
        %   is then calculated by bilinearly interpolating the partial 
        %   derivatives of the distance function.
        
            % Find values for all bounding points
            if isempty(xyLocal)
                gXY = zeros(0,1,2);
            else
                halfWidth = 1/obj.Grad.Resolution/2;
                [dx,dy] = meshgrid(halfWidth*[-1 1],halfWidth*[-1 1]);
                p0 = obj.Grad.grid2localImpl(obj.Grad.local2gridImpl(xyLocal));
                pB0 = reshape([dx(:) dy(:)],1,[],2); 
                local2interpOffset = obj.Grad.GridOriginInLocal;
                interpolant = obj.Interpolant;

                % Find quadrant containing each query point
                tXY = reshape(xyLocal-p0,[],1,2);
                m = sign(tXY);
                mShift = m==0;
                mBound = any(mShift,3);
                m(mShift) = 1;

                % Each "row" contains a (1,4,2) matrix defining quadrant 
                % surrounding localPts(i,:)
                pBound = reshape(p0,[],1,2) + (pB0 + m*halfWidth)/2;

                % Compute gradient
                gXY = obj.gradientInQuadrant(local2interpOffset,interpolant,xyLocal,pBound,halfWidth);

                % Compute mean for points lying on cell-centerlines
                pBound = pBound - mShift*halfWidth;
                if nnz(mBound) > 0
                    gXY(mBound,:,:) = (gXY(mBound,:,:) + ...
                        obj.gradientInQuadrant(local2interpOffset,interpolant,xyLocal(mBound,:),pBound(mBound,:,:),halfWidth))/2;
                end
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

            % Update distance interpolant
            V = flipud(double(SD));
            obj.Interpolant.Values = V;

            % Update gradient
            [gx,gy] = gradient(flipud(V));
            gXY = reshape([gx,-gy],[size(gx) 2]);
            obj.Grad.setMapData(gXY);
        end
    end

    methods (Static, Hidden)
        function gXY = gradientInQuadrant(local2interpOffset,interpolant,P,pBound,quadSize)
        %gradientInQuadrant Computes gradient of distance-surface via 
        % bilinear interpolation of partial derivatives.
        %
        %   [1] https://en.wikipedia.org/wiki/Bilinear_interpolation
        %   
        %   Bilinear interpolation can be defined as follows:
        %
        %   Let F(x,y) = F(x,y0)*(1-dy) + F(x,y1)*(dy) be the
        %   bilinearly interpolated value between 4 points on a 
        %   distance grid, where:
        %              
        %       F(x,y0) = F(x0,y0)*(1-dx) + F(x1,y0)*(dx)
        %       F(x,y1) = F(x0,y1)*(1-dx) + F(x1,y1)*(dx)
        %       dx = (x-x0)/(x1-x0)
        %       dy = (y-y0)/(y1-y0)
        %
        %   The partial derivatives, are therefore:
        %
        %       d/dx(F(x,y)) = d/dx[Fx(x,y0)]*(1-dy) + d/dx[F(x,y1)]*(dy)
        %                    = [F(x1,y0) - F(x0,y0)]*(1-dy) + [F(x1,y1) - F(x0,y1)]*(dy)
        %       d/dy(F(x,y)) = F(x,y1)-Fx(x,y0)
        %                    = F(x0,y1)*(1-dx) + F(x1,y1)*(dx)

            % Query points on quadrant bounds
            xq = reshape(pBound(:,:,1)-local2interpOffset(1),[],1);
            yq = reshape(pBound(:,:,2)-local2interpOffset(2),[],1);
            F = reshape(interpolant(yq(:),xq(:)),[],4);     % F(i,:) = [F(x0,y0) F(x0,y1) F(x1,y0) F(x1,y1)]

            % Calculate local gradient via bilinear interp
            sf = 1/quadSize;
            t = (P-reshape(pBound(:,1,:),[],2))*sf*sf; % [dx dy]
            dFxy0 = F(:,3)-F(:,1);
            dFxy1 = F(:,4)-F(:,2);
            dFx0y = F(:,2)-F(:,1);
            dFx1y = F(:,4)-F(:,3);
        
            % Approximate and scale gradient in quadrant
            gXY = reshape([ ...
                 dFxy0.*(sf-t(:,2)) + dFxy1.*t(:,2), ...        % dFdx
                 dFx0y.*(sf-t(:,1)) + dFx1y.*t(:,1)],[],1,2);   % dFdy
        end
    end
end
