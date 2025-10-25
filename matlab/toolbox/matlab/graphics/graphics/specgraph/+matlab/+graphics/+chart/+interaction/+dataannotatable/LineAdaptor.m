classdef (Sealed)LineAdaptor < matlab.graphics.chart.interaction.dataannotatable.AnnotationAdaptor
    % A helper class to support Data Cursors on legacy Line objects.
    
    %   Copyright 2010-2021 The MathWorks, Inc.
    
    properties(Access=private, Transient)
        LineDataListener;
    end
    
    methods
        function hObj = LineAdaptor(hLine)
            hObj@matlab.graphics.chart.interaction.dataannotatable.AnnotationAdaptor(hLine);
        end
        
        % DataAnnotatable interface methods
        function coordinateData = createCoordinateData(hObj, valueSource, dataIndex, interpolationFactor)
            import matlab.graphics.chart.interaction.dataannotatable.internal.CoordinateData;
            
            % Get the coordinate for a Line given the index and
            % interpolation factor where interpolationFactor is an optional argument
            if nargin < 4
                interpolationFactor = 0;
            end
            coordinateData = CoordinateData.empty(0,1);
            
            hLine = hObj.AnnotationTarget;
            % primitive line is not data-annotatable therefore doesnt
            % contain getReportedPosition function. Therefore, we use
            % LineHelper for the same.
            vertexPosition = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getReportedPosition(hLine,dataIndex,interpolationFactor);
            location = vertexPosition.getLocation(hLine);
            % For 2d objects such as 2D line, location does not contain the
            % 3rd coordinate
            location3 = [];
            if numel(location) == 3
                location3 = location(3);
            end
            
            % Convert the values based on the format of the axes rulers
            [xLoc, yLoc, zLoc] = matlab.graphics.internal.makeNonNumeric(hLine,location(1),location(2),location3);
            calculatedPosition = {xLoc, yLoc, zLoc};
            
            % Construct default data source from DimensionNames e.g. XData,
            % YData etc.
            dimensionData = strcat(hLine.DimensionNames,'Data');
            dimInd = strcmpi(dimensionData,valueSource);
            if any(dimInd)
                coordinateData = CoordinateData(dimensionData{dimInd}, calculatedPosition{dimInd});
            end
        end
        
        % Overridden function that returns a string array of valid valueSources
        function valueSources = getAllValidValueSources(hObj)
            hLine = hObj.AnnotationTarget;
            valueSources = string.empty(0,1);
            
            dimensionNames = hLine.DimensionNames;
            for i=1:numel(dimensionNames)
                if strcmpi(dimensionNames{i},'Z') && ...
                        (~isprop(hLine,'ZData') || (isprop(hLine,'ZData') && ...
                        isempty(hLine.ZData)))
                    continue;
                end
                valueSources(i,1) = strcat(dimensionNames{i},"Data");
            end
        end
    end
    
    methods(Access=protected)
        function doSetAnnotationTarget(hObj, hTarget)
            % Enforce that the target is an image
            if ~ishghandle(hTarget,'line')
                error(message('MATLAB:specgraph:chartMixin:dataannotatable:LineAdaptor:InvalidLine'));
            end
            
            % Add a listener to the image data to fire the DataChanged event
            hObj.LineDataListener = event.proplistener(hTarget, ...
                {hTarget.findprop('XData'), hTarget.findprop('YData'), hTarget.findprop('ZData')}, ...
                'PostSet',@(obj,evd)(hObj.sendDataChangedEvent));
        end
    end  
    
    % For the DataAnnotatable interface methods, we will delegate to the
    % LineHelper class.
    methods(Access='protected')
        function descriptors = doGetDataDescriptors(hObj, index, interpolationFactor)
            descriptors = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getDataDescriptors(hObj.AnnotationTarget, index, interpolationFactor);
        end
        
        function index = doGetNearestIndex(hObj, index)
            index = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getNearestIndex(hObj.AnnotationTarget, index);
        end
        
        function index = doGetNearestPoint(hObj, position)
            index = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getNearestPoint(hObj.AnnotationTarget, position);
        end
        
        function [index, interpolationFactor] = doGetInterpolatedPoint(hObj, position)
            [index, interpolationFactor] = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getInterpolatedPoint(hObj.AnnotationTarget, position);
        end
        
        function [index, interpolationFactor] = doGetInterpolatedPointInDataUnits(hObj, position)
            [index, interpolationFactor] = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getInterpolatedPointInDataUnits(hObj.AnnotationTarget, position);
        end
        
        function points = doGetEnclosedPoints(hObj, position)
            points = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getEnclosedPoints(hObj.AnnotationTarget, position);
        end
        
        function [index, interpolationFactor] = doIncrementIndex(hObj, index, direction,int_factor)
            [index, interpolationFactor] = matlab.graphics.chart.interaction.dataannotatable.LineHelper.incrementIndex(hObj.AnnotationTarget, index, direction, int_factor);
        end
        
        function point = doGetDisplayAnchorPoint(hObj, index, interpolationFactor)
            point = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getDisplayAnchorPoint(hObj.AnnotationTarget, index, interpolationFactor);
        end
        
        function point = doGetReportedPosition(hObj, index, interpolationFactor)
            point = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getReportedPosition(hObj.AnnotationTarget, index, interpolationFactor);
        end
    end
end
