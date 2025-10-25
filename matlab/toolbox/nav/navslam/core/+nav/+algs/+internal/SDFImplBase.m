classdef SDFImplBase < matlabshared.autonomous.map.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%SDFImplBase Base class common to all SDF-map approximation helpers

% Copyright 2022 The MathWorks, Inc.

    %#codegen

    properties
        %Dist Simple dist matrix, recalculated first time after data changes
        Dist

        %Idx Simple index matrix, contains the linear idx of nearest obj
        Idx

        %Grad Layer storing the xy gradient
        Grad
    end
    
    methods (Abstract)
        %updateSDF Take in signed distance matrix and update class
        updateSDF(obj, mat);

        %distanceImpl Implementation behind the user-facing "distance" method
        distanceImpl(obj, varargin);

        %gradientImpl Implementation behind the user-facing "gradient" method
        gradientImpl(obj, varargin);
    end

    methods
        function obj = SDFImplBase(mat,sharedProps)
            % Create layers for distance, neighbors, and gradient
            res = sharedProps.Resolution;
            gSize = size(mat);
            obj.Dist = mapLayer(nan(gSize),'Resolution',res,'LayerName','Distance','DefaultValue',nan);
            obj.Idx  = mapLayer(nan(gSize),'Resolution',res,'LayerName','Index','DefaultValue',nan);
            obj.Grad = mapLayer(nan([gSize 2]),'Resolution',res,'LayerName','Gradient','DefaultValue',nan);

            % By sharing the properties, modifications to the owner of
            % sharedProps are shared with the back-end interpolant
            obj.Dist.SharedProperties = sharedProps;
            obj.Idx.SharedProperties = sharedProps;
            obj.Grad.SharedProperties = sharedProps;
        end

        function [boundLocation, inBounds] = closestBoundaryImpl(obj,varargin)
        %closestBoundaryImpl Default implementation common to all approximations

            % Retrieve index data
            if nargout > 1
                [linIdx,inBounds] = obj.Idx.getMapData(varargin{:});
            else
                linIdx = obj.Idx.getMapData(varargin{:});
            end

            % Prep outputs
            gridSize = obj.Dist.GridSize;
            idxSize = size(linIdx);
            boundLocation = nan([idxSize 2]);
            if coder.target('MATLAB')
                [loc1,loc2] = ind2sub(gridSize,linIdx);
            else
                loc1 = nan(size(linIdx));
                loc2 = loc1;
                m = ~isnan(linIdx);
                [loc1(m),loc2(m)] = ind2sub(gridSize,linIdx(m));
            end
            isWorld = nargin == 1;
            if ~isWorld
                [inBounds, matSize, isGrid, isLocal] = getParser(obj.Dist, 'closestBoundary', varargin{:});
                isWorld = ~isGrid & ~isLocal;
            end

            if ~isWorld && isGrid
                % Grid frame
                boundLocation(:,:,1) = loc1;
                boundLocation(:,:,2) = loc2;
            else
                if ~isWorld
                    % Local frame
                    XY = obj.Dist.grid2localImpl([loc1(:) loc2(:)]);
                else
                    % World frame
                    XY = obj.Dist.grid2worldImpl([loc1(:) loc2(:)]);
                end
                boundLocation(:,:,1) = reshape(XY(:,1),idxSize);
                boundLocation(:,:,2) = reshape(XY(:,2),idxSize);
            end
        end
    end
end