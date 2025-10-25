classdef (Abstract) MapInterface < handle
    %MapInterface Abstract class to be derived by vehicleCostMap in
    %driving, and robotics.algs.internal.OccupancyGridBase in robotics.
    
    % Copyright 2018 The MathWorks, Inc.
    
    %#codegen
    
    properties (Abstract, Dependent, SetAccess = protected)
        %MapExtent Extent of map, specified as [xmin,xmax,ymin,ymax] in
        %meters
        MapExtent
    end
    
    properties (Abstract, SetAccess = private)
        %CellSize  A scalar representing the square side length of each
        %   cell in world units. Smaller values improve the resolution of
        %   the search space, at the cost of increased memory consumption.
        %   For example, a cell length of 1 implies a grid where each cell
        %   is a square of size 1m-by-1m.
        CellSize
    end
    
    methods (Abstract)
        %checkFreePoses Returns scalar/vector of logical
        %0(Occupied)/1(Free)
        results = checkFreePoses(obj, poses)
    end
end