classdef UniformInflator < matlabshared.autonomous.map.internal.InflatorBase
%This class is for internal use only. It may be removed in the future.   
    
%UNIFORMINFLATOR inflates uniformly around specified points
 
%   Copyright 2019-2020 The MathWorks, Inc.

%#codegen
    
    methods
        function obj = UniformInflator(radius)
            %UNIFORMINFLATOR Construct an instance of this class
            
            obj.InflateRadius = radius;
        end
        
        function  inflate(obj, origLayer, inflateLayer,ind,varargin)
            %inflate inflates the region around the specified ind
            %
            %   inflate(INFLATOR, SOURCE, TARGET) inflates the whole SOURCE 
            %   map and writes the result into TARGET map
            %
            %   inflate(INFLATOR, SOURCE, TARGET, WORLDCOORDINATES) inflates 
            %   the subsect of SOURCE map identified by WORLDCOORDINATES
            %
            %   inflate(INFLATOR, SOURCE, TARGET, LOCALCOORDINATES, 'local') 
            %   inflates the subsect of SOURCE map identified by LOCALCOORDINATES
            %
            %   inflate(INFLATOR, SOURCE, TARGET, GRIDCOORDINATES, 'grid') 
            %   inflates the subsect of SOURCE map identified by GRIDCOORDINATES
            %
            %   note: inflate always writes into the TARGET map based on SOURCE map values at same world coordinates regardless of the coordinate format selected.

            narginchk(3,5);
            inflateEntireMap = false;
            validateattributes(origLayer, {'matlabshared.autonomous.internal.MapLayer',...
                    }, {},'UniformInflator','SourceMap');
                validateattributes(inflateLayer, {'matlabshared.autonomous.internal.MapLayer',...
                    }, {},'UniformInflator','TargetMap');
                if nargin < 4
                    inflateEntireMap = true;
                    [indX,indY] = meshgrid(1:origLayer.GridSize(1),1:origLayer.GridSize(2));
                    ind = [indX(:),indY(:)];
                    pointType = 'grid';
                elseif nargin < 5
                    validateattributes(ind, {'numeric'}, ...
                    {'nonempty','real','nonnan', 'finite', 'ncols', 2}, 'UniformInflator', 'LOCALCOORDINATES');
                    pointType = 'world';
                else
                    validateattributes(ind, {'numeric'}, ...
                    {'nonempty','real','nonnan', 'finite', 'ncols', 2}, 'UniformInflator', 'LOCALCOORDINATES');
                    pointType = validatestring(varargin{1},{'grid','local','world'},'UniformInflator','pointType');
                end
                
                
            circularIterator = matlabshared.autonomous.map.internal.CircularIterator(origLayer,ind,obj.InflateRadius,pointType);
            if inflateEntireMap
                gInd = ind;
            else
                gInd = circularIterator.GridPoses;
            end
            for k = 1:size(gInd,1)
                gridInd = circularIterator.getCircularIndices(gInd(k,:));
                setValueGrid(inflateLayer, gInd(k,:),max(getValueGrid(origLayer,gridInd)));
            end
        end
        
        
        function newObj = copy(obj)
            %copy creates a deep copy of this object
            
            newObj = matlabshared.autonomous.map.internal.UniformInflator(obj.InflateRadius);
        end
    end
end

