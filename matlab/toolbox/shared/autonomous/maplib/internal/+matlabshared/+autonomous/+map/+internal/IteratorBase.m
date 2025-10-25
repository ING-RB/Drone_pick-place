classdef IteratorBase < matlabshared.autonomous.map.internal.InternalAccess
%This class is for internal use only. It may be removed in the future.

%ITERATORBASE is base class for iterators

%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen
    properties (Dependent, SetAccess = {?matlabshared.autonomous.map.internal.InternalAccess})
        %GridPoses Grid indexes crossed by the lines
        GridPoses
        %WorldPoses Centers of cells crossed by the lines in world frame
        WorldPoses
        %LocalPoses Centers of cells crossed by the lines in local frame
        LocalPoses
    end
    
    properties (Access = {?matlabshared.autonomous.map.internal.InternalAccess})
        %Map current map to iterate
        Map
        %BasePoint grid index of base points line start point/ circle
        %center etc.
        BasePoint
        %CurrentPoint grid index of the current cell 
        CurrentPoint
        %IsDone flag specifying weather the iterator reached end point
        IsDone
        %IsMapLayer true if the passed map is a maplayer
        IsMapLayer
    end
    
    methods
        
        function currentPt = current(obj)
            %current Get the indexed poses currently pointed by iterator
            
            if ~isnan(obj.CurrentPoint)
                currentPt = getValueGrid(obj.Map,obj.CurrentPoint);
            else
                if obj.IsMapLayer
                    currentPt = obj.Map.DefaultValueInternal;
                else
                    currentPt = cell(1,obj.Map.NumLayers);
                    for k = 1:obj.Map.NumLayers
                        currentPt{k} = obj.Map.Layers{k}.DefaultValueInternal;
                    end
                end
            end
            
        end
        
        function gridInd = get.GridPoses(obj)
            gridInd = poses(obj);
        end
        
        function localInd = get.LocalPoses(obj)
            gridInd = poses(obj);
            if obj.IsMapLayer
                localInd = grid2local(obj.Map,gridInd);
            else
                if obj.Map.NumLayers > 0
                    localInd = grid2local(obj.Map.Layers{1},gridInd);
                else
                    localInd = zeros(0,2);
                end
            end
        end
        
        function worldInd = get.WorldPoses(obj)
            gridInd = poses(obj);
            if obj.IsMapLayer
                worldInd = grid2world(obj.Map,gridInd);
            else
                if obj.Map.NumLayers > 0
                    worldInd = grid2world(obj.Map.Layers{1},gridInd);
                else
                    worldInd = zeros(0,2);
                end
            end
        end
    end
    
    methods(Static, Hidden)
        function props = matlabCodegenNontunableProperties(~)
        % Let the coder know about non-tunable parameters
            props = {'IsMapLayer'};
        end
    end
end

