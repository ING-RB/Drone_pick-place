classdef CircularIterator < matlabshared.autonomous.map.internal.IteratorBase
%This class is for internal use only. It may be removed in the future.
    
%CircularIterator is class for circular iterator

%CIRCULARITERATOR is class for circular iterator. The following syntaxes can be
% used for creating CircularIterator object:
% ITER = matlabshared.autonomous.map.internal.CircularIterator(MAP, CENTERS, RADIUS) 
% or
% ITER = matlabshared.autonomous.map.internal.CircularIterator(MAP, CENTERS, RADIUS, 'world')
% creates an iterator that iterates through cells in MAP that are crossed
% by circles with their centers in rows of CENTERS and their radius in
% RADIUS, centers defined in world coordinates
%
% ITER = matlabshared.autonomous.map.internal.CircularIterator(MAP, CENTERS, RADIUS, 'local')
% creates the iterator based on circle centers defined by local coordinates
%
% ITER = matlabshared.autonomous.map.internal.CircularIterator(MAP, CENTERS, RADIUS, 'grid')
% creates the iterator based on circle centers defined by grid coordinates
%
% ITER = matlabshared.autonomous.map.internal.CircularIterator(ITER, IDX) creates an iterator 
% that travels through the IDX-th circle traveled by ITER, which must also be a CircularIterator

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen
    
    properties (SetAccess = {?matlabshared.autonomous.map.internal.InternalAccess})
        %Radius of the the circular region around the specified centers
        Radius
    end
    
    properties (Access = {?matlabshared.autonomous.map.internal.InternalAccess})
        %CircularElementIndices grid indices of base circular element
        CircularElementIndices
        %CircularElementCenter circular element center grid index
        CircularElementCenter
        %CurrentCircleId id of the current circle when more than one
        %centers is passed
        CurrentCircleId
        %CurrentEleId circular element linear index of the current grid 
        CurrentEleId
        %NumCircles number of centers 
        NumCircles
        %NumEle number of grids lie within the specified radius
        NumEle
        %PointType expected coordinate frame of start and end points
        PointType
        %RadiusGrid radius represented in number of cells
        RadiusGrid
        %ComputedPoints stores all the computed grid iteration indices till
        %now
        ComputedPoints 
    end
    
    methods
        function obj = CircularIterator(varargin)
            %CircularIterator Construct an instance of this class
            
            narginchk(2,4);
            if isa(varargin{1},'matlabshared.autonomous.map.internal.CircularIterator')
                validateattributes(varargin{2},{'numeric'},{'nonempty','real','nonnan','finite','scalar','>',0,'<=',varargin{1}.NumCircles},'CircularIterator','Idx');
                circleIdx = varargin{2};
                obj.Map = varargin{1}.Map;
                obj.BasePoint = varargin{1}.BasePoint(circleIdx,:);
                obj.IsDone = false;
                obj.Radius = varargin{1}.Radius;
                obj.CircularElementCenter = varargin{1}.CircularElementCenter;
                obj.CircularElementIndices = varargin{1}.CircularElementIndices;
                obj.NumCircles = 1;
                obj.CurrentCircleId = 1;
                obj.CurrentEleId = 1;
                obj.NumEle = varargin{1}.NumEle;
                obj.PointType = varargin{1}.PointType;
                obj.RadiusGrid = varargin{1}.RadiusGrid;
                obj.ComputedPoints = varargin{1}.ComputedPoints;
                obj.IsMapLayer = varargin{1}.IsMapLayer;
                obj.CurrentPoint = nan(1,2);
                return;
            else
                validateattributes(varargin{1}, {'matlabshared.autonomous.internal.MapLayer',...
                    'matlabshared.autonomous.internal.MultiLayerMap'}, {},'CircularIterator','Map');
                obj.Map = varargin{1};
                validateattributes(varargin{2}, {'numeric'}, ...
                    {'real','nonempty', 'ncols', 2,'nonnan', 'finite'}, 'CircularIterator', 'Centers');
                validateattributes(varargin{3}, {'numeric'}, ...
                        {'real','nonempty', 'scalar','nonnan', 'finite'}, 'CircularIterator', 'Radius');
                if nargin > 3
                    pointType = validatestring(varargin{4},{'grid','local','world'},'CircularIterator','pointType');
                else
                    pointType = 'world';
                end
                obj.Map = varargin{1};
                obj.PointType = pointType;
                if isa(varargin{1},'matlabshared.autonomous.internal.MapLayer')
                    obj.IsMapLayer = true;
                else
                    obj.IsMapLayer = false;
                end
                switch pointType
                    case 'grid'
                        centers = varargin{2};
                    case 'local'
                        if obj.IsMapLayer
                            centers = local2grid(obj.Map,varargin{2});
                        else
                            if obj.Map.NumLayers > 0
                                centers = local2grid(obj.Map.Layers{1},varargin{2});
                            else
                                centers = varargin{2};
                            end
                        end
                    otherwise
                        if obj.IsMapLayer
                            centers = world2grid(obj.Map,varargin{2});
                        else
                            if obj.Map.NumLayers > 0
                                centers = world2grid(obj.Map.Layers{1},varargin{2});
                            else
                                centers = varargin{2};
                            end
                        end
                end
                obj.BasePoint = centers;
                obj.Radius = varargin{3};
                obj.RadiusGrid = obj.Map.counterFPECeil(obj.Radius*obj.Map.Resolution);
                
                [x,y] = meshgrid(-obj.RadiusGrid:obj.RadiusGrid);
                % finding circular indices within specified radius similar
                % to nav.algs.internal.diskstrel 
                in = find( (x.^2 + y.^2) <= (obj.RadiusGrid(1)+0.75)^2);
                % Find the index of the center of the structuring element
                obj.CircularElementCenter = [ceil(size(x,1)/2), ceil(size(x,2)/2)];
                
                % Get indices for structuring element
                [rowIdx, colIdx] = ind2sub(size(x), in);
                obj.CircularElementIndices = [rowIdx, colIdx];
                obj.NumCircles = size(obj.BasePoint,1);
                obj.CurrentCircleId = 1;
                obj.CurrentEleId = 1;
                obj.NumEle = size(obj.CircularElementIndices,1);
                obj.IsDone = false;
                obj.ComputedPoints = zeros(0,2);
                obj.CurrentPoint = nan(1,2);
            end
        end
        
        
        function pt = next(obj)
            %next Move iterator to next cell
            
            pt = nan(1,2);
            if obj.IsDone
                return;
            end
            
            while (any(isnan(pt))||any(pt<1)||any(pt>obj.Map.GridSize))&&(~obj.IsDone)
                pt(1,1:2) = [obj.BasePoint(obj.CurrentCircleId,1)-obj.CircularElementCenter(1)+ obj.CircularElementIndices(obj.CurrentEleId,1),...
                    obj.BasePoint(obj.CurrentCircleId,2)-obj.CircularElementCenter(2)+ obj.CircularElementIndices(obj.CurrentEleId,2)];
                obj.CurrentEleId = obj.CurrentEleId + 1;
                if obj.CurrentEleId > obj.NumEle
                    if obj.CurrentCircleId < obj.NumCircles
                        obj.CurrentCircleId = obj.CurrentCircleId + 1;
                        obj.CurrentEleId = 1;
                    else
                        obj.IsDone = true;
                    end
                end
            end
            obj.CurrentPoint = pt;
        end
        
        function done = isdone(obj)
            %isdone checks whether the iterator is at the end
            
            narginchk(1,1);
            done = obj.IsDone;
        end
        
        function newObj = copy(obj)
            %copy creates a deep copy of the object
            
            newObj = matlabshared.autonomous.map.internal.CircularIterator(obj,1);
            copyImpl(obj,newObj);
            newObj.BasePoint = obj.BasePoint;
            newObj.CurrentPoint = obj.CurrentPoint;
            newObj.IsDone = obj.IsDone;
            newObj.CurrentCircleId = obj.CurrentCircleId;
            newObj.CurrentEleId = obj.CurrentEleId;
            newObj.NumCircles = obj.NumCircles;
            newObj.NumEle = obj.NumEle;
            newObj.PointType = obj.PointType;
            newObj.ComputedPoints = obj.ComputedPoints;
        end
        
        function copyImpl(obj,newObj)
            %copyImpl copies some important properties to newObj
            
            newObj.CircularElementIndices = obj.CircularElementIndices;
            newObj.CircularElementCenter = obj.CircularElementCenter;
            newObj.RadiusGrid = obj.RadiusGrid;
            newObj.Radius = obj.Radius;
        end
    end
    
    methods (Access = {?matlabshared.autonomous.map.internal.InternalAccess})
        
        function gridInd = poses(obj)
            %poses Returns all the intermediate grid indices lying between
            %   the specified start and goal
            
            if ~obj.IsDone
                gridInd = zeros(size(obj.BasePoint,1)*obj.NumEle,2);
                for i = 1:obj.NumCircles
                    gridInd(((i-1)*obj.NumEle+1):(i*obj.NumEle),:) = ...
                        [obj.BasePoint(i,1)-obj.CircularElementCenter(1)+ obj.CircularElementIndices(:,1),...
                        obj.BasePoint(i,2)-obj.CircularElementCenter(2)+ obj.CircularElementIndices(:,2)];
                end
                ind = (gridInd(:,1) < 1)|(gridInd(:,2) < 1)|(gridInd(:,1)>obj.Map.GridSize(1))|(gridInd(:,2)>obj.Map.GridSize(2));
                gridInd = gridInd(~ind,:);
                gridInd = unique(gridInd,'rows');
                obj.ComputedPoints = gridInd;
                obj.CurrentCircleId = obj.NumCircles;
                obj.CurrentEleId = obj.NumEle;
                obj.CurrentPoint = gridInd(end,:);
                obj.IsDone = true;
            else
                gridInd = obj.ComputedPoints;
            end
        end
        
        function updateCenters(varargin)
            %updateCenters updates centers of the circles to iterate.
            %Useful for reusing the circular iterator to iterate over new
            %circular regions.
            
            validateattributes(varargin{2}, {'numeric'}, ...
                    {'real', 'ncols', 2, 'finite','nonempty','nonnan'}, 'CircularIterator', 'Centers');
                switch varargin{1}.PointType
                    case 'grid'
                        centers = varargin{2};
                    case 'local'
                        centers = local2grid(varargin{1}.Map,varargin{2});
                    otherwise
                        centers = world2grid(varargin{1}.Map,varargin{2});
                end
                varargin{1}.BasePoint = centers;
                varargin{1}.NumCircles = size(varargin{2},1);
                varargin{1}.CurrentEleId = 1;
        end
        
        function gridInd = getCircularIndices(obj,center)
            %getCircularIndices returns circular iteration indices lying
            %within map boundaries around center. Useful in reusing the
            %same object to iterate over new circular regions
            
            gridInd = [center(1,1)-obj.CircularElementCenter(1)+ obj.CircularElementIndices(:,1),...
                center(1,2)-obj.CircularElementCenter(2)+ obj.CircularElementIndices(:,2)];
            if any(center < (obj.RadiusGrid(1)+1))
                ind = (gridInd < 1);
                gridInd(ind) = abs(gridInd(ind)-2);
            end
            if any(center > (obj.Map.GridSize-obj.RadiusGrid(1)))
                ind1 = (gridInd(:,1) >  obj.Map.GridSize(1));
                ind2 = (gridInd(:,2) >  obj.Map.GridSize(2));
                gridInd(ind1,1) = 2*obj.Map.GridSize(1) - gridInd(ind1,1);
                gridInd(ind2,2) = 2*obj.Map.GridSize(2) - gridInd(ind2,2);
            end
            
        end
    end
end
