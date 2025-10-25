classdef (Sealed)SurfaceAdaptor < matlab.graphics.chart.interaction.dataannotatable.AnnotationAdaptor
    % A helper class to support Data Cursors on legacy Surface objects.
    
    %   Copyright 2010-2021 The MathWorks, Inc.
    
    properties(Access=private, Transient)
        SurfaceDataListener;
    end
    
    methods
        function hObj = SurfaceAdaptor(hSurf)
            hObj@matlab.graphics.chart.interaction.dataannotatable.AnnotationAdaptor(hSurf);
        end
        
        % DataAnnotatable interface method
        function coordinateData = createCoordinateData(hObj, valueSource, dataIndex, interpolationFactor)
            import matlab.graphics.chart.interaction.dataannotatable.internal.CoordinateData;
            % Get the data descriptors for a Line given the index and
            % interpolation factor where interpolationFactor is an optional argument
            if nargin < 4
                interpolationFactor = 0;
            end
            coordinateData = CoordinateData.empty(0,1);
            hSurface = hObj.AnnotationTarget;
            % primitive surface is not data-annotatable therefore doesnt
            % contain getReportedPosition function. Therefore, we use
            % SurfaceHelper for the same.
            vertexPosition = matlab.graphics.chart.interaction.dataannotatable.SurfaceHelper.getReportedPosition(hSurface,...
                dataIndex, interpolationFactor);
            location = vertexPosition.getLocation(hSurface);
            
            % Convert the values based on the format of the axes rulers
            [xLoc, yLoc, zLoc] = matlab.graphics.internal.makeNonNumeric(hSurface,location(1),location(2),location(3));
            calculatedPosition = {xLoc, yLoc, zLoc};
            
            % Construct default data source from DimensionNames e.g. XData,
            % YData etc.
            dimensionData = strcat(hSurface.DimensionNames,'Data');
            dimInd = strcmpi(dimensionData,valueSource);
            if any(dimInd)
                coordinateData = CoordinateData(dimensionData{dimInd}, calculatedPosition{dimInd});
            end
        end
        
        % Overridden function that returns a string array of valid valueSources
        function valueSources = getAllValidValueSources(hObj)
            hSurface = hObj.AnnotationTarget;
            valueSources = string.empty(0,1);

            dimensionNames = hSurface.DimensionNames;
            for i=1:numel(dimensionNames)
                valueSources(i,1) = strcat(dimensionNames{i},"Data");
            end
        end
    end
    
    methods(Access=protected)
        function doSetAnnotationTarget(hObj, hTarget)
            % Enforce that the target is an image
            if ~ishghandle(hTarget,'surface')
                error(message('MATLAB:specgraph:chartMixin:dataannotatable:SurfaceAdaptor:InvalidSurface'));
            end
            
            % Add a listener to the image data to fire the DataChanged event
            hObj.SurfaceDataListener = event.proplistener(hTarget, ...
                {hTarget.findprop('XData'), hTarget.findprop('YData'), hTarget.findprop('ZData')}, ...
                'PostSet',@(obj,evd)(hObj.sendDataChangedEvent));
        end
    end
    
    % For the DataAnnotatable interface methods, we will delegate to the
    % SurfaceHelper class.
    methods(Access='protected')
        function descriptors = doGetDataDescriptors(hObj, index, interpolationFactor)
            descriptors = matlab.graphics.chart.interaction.dataannotatable.SurfaceHelper.getDataDescriptors(hObj.AnnotationTarget, index, interpolationFactor);
        end
        
        function index = doGetNearestIndex(hObj, index)
            index = matlab.graphics.chart.interaction.dataannotatable.SurfaceHelper.getNearestIndex(hObj.AnnotationTarget, index);
        end
        
        function index = doGetNearestPoint(hObj, position)
            index = matlab.graphics.chart.interaction.dataannotatable.SurfaceHelper.getNearestPoint(hObj.AnnotationTarget, position);
        end
                
        function [index, interpolationFactor] = doGetInterpolatedPoint(hObj, position)
            [index, interpolationFactor] = matlab.graphics.chart.interaction.dataannotatable.SurfaceHelper.getInterpolatedPoint(hObj.AnnotationTarget, position);
        end
        
        function [index, interpolationFactor] = doGetInterpolatedPointInDataUnits(hObj, position)
            [index, interpolationFactor] = matlab.graphics.chart.interaction.dataannotatable.SurfaceHelper.getInterpolatedPointInDataUnits(hObj.AnnotationTarget, position);
        end
                
        function points = doGetEnclosedPoints(~, ~)
            % The adaptor will not participate with brushing.
            points = [];
        end
        
        function [index, interpolationFactor] = doIncrementIndex(hObj, index, direction, interpolationStep)
            [index, interpolationFactor] = matlab.graphics.chart.interaction.dataannotatable.SurfaceHelper.incrementIndex(index, direction, interpolationStep, size(hObj.AnnotationTarget.ZData));
        end
        
        function point = doGetDisplayAnchorPoint(hObj, index, interpolationFactor)
            point = matlab.graphics.chart.interaction.dataannotatable.SurfaceHelper.getDisplayAnchorPoint(hObj.AnnotationTarget, index, interpolationFactor);
        end
        
        function point = doGetReportedPosition(hObj, index, interpolationFactor)
            point = matlab.graphics.chart.interaction.dataannotatable.SurfaceHelper.getReportedPosition(hObj.AnnotationTarget, index, interpolationFactor);
        end
    end
end
