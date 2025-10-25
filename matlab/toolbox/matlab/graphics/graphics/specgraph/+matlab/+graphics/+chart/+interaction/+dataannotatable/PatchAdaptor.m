classdef (Sealed)PatchAdaptor < matlab.graphics.chart.interaction.dataannotatable.AnnotationAdaptor
    % A helper class to support Data Cursors on legacy Patch objects.
    
    %   Copyright 2010-2021 The MathWorks, Inc.
    
    properties(Access=private, Transient)
        PatchDataListener;
    end
    
    methods
        function hObj = PatchAdaptor(hPatch)
            hObj@matlab.graphics.chart.interaction.dataannotatable.AnnotationAdaptor(hPatch);
        end
        
        % DataAnnotatable interface methods
        function coordinateData = createCoordinateData(hObj, valueSource, dataIndex, interpolationFactor)
            import matlab.graphics.chart.interaction.dataannotatable.internal.CoordinateData;
            % Get the data descriptors for a Line given the index and
            % interpolation factor.
            % interpolationFactor is optional argument
            if nargin < 4
                interpolationFactor = 0;
            end
            coordinateData = CoordinateData.empty(0,1);
            hPatch = hObj.AnnotationTarget;
            vertexPosition = matlab.graphics.chart.interaction.dataannotatable.PatchHelper.getReportedPosition(hPatch,dataIndex,interpolationFactor);
            location = vertexPosition.getLocation(hPatch);
            % For 2d objects such as 2D line, location does not contain the
            % 3rd coordinate
            location3 = [];
            if numel(location) == 3
                location3 = location(3);
            end
            
            % Convert the values based on the format of the axes rulers
            [xLoc, yLoc, zLoc] = matlab.graphics.internal.makeNonNumeric(hPatch,location(1),location(2),location3);
            calculatedPosition = {xLoc, yLoc, zLoc};            
            
            % Construct default data source from DimensionNames e.g. XData,
            % YData etc.
            dimensionData = strcat(hPatch.DimensionNames,'Data');
            dimInd = strcmpi(dimensionData,valueSource);
            if any(dimInd)
                coordinateData = CoordinateData(dimensionData{dimInd}, calculatedPosition{dimInd});
            end
        end
        
        % Overridden function that returns a string array of valid valueSources
        function valueSources = getAllValidValueSources(hObj)
            hPatch = hObj.AnnotationTarget;
            valueSources = string.empty(0,1);

            dimensionNames = hPatch.DimensionNames;
            for i=1:numel(dimensionNames)
                if strcmpi(dimensionNames{i},'Z') && ...
                        (~isprop(hPatch,'ZData') || (isprop(hPatch,'ZData') && ...
                        isempty(hPatch.ZData)))
                    continue;
                end
                valueSources(i,1) = strcat(dimensionNames{i},"Data");
            end
        end
    end
    
    methods(Access=protected)
        function doSetAnnotationTarget(hObj, hTarget)
            % Enforce that the target is an image
            if ~ishghandle(hTarget,'patch')
                error(message('MATLAB:specgraph:chartMixin:dataannotatable:PatchAdaptor:InvalidPatch'));
            end
            
            % Add a listener to the image data to fire the DataChanged event
            hObj.PatchDataListener = event.proplistener(hTarget, ...
                {hTarget.findprop('XData'), hTarget.findprop('YData'), hTarget.findprop('ZData')}, ...
                'PostSet',@(obj,evd)(hObj.sendDataChangedEvent));
        end
    end
    
    % For the DataAnnotatable interface methods, we will delegate to the
    % PatchHelper class.
    methods(Access='protected')
        function descriptors = doGetDataDescriptors(hObj, index, interpolationFactor)
            descriptors = matlab.graphics.chart.interaction.dataannotatable.PatchHelper.getDataDescriptors(hObj.AnnotationTarget, index, interpolationFactor);
        end
        
        function index = doGetNearestIndex(hObj, index)
            index = matlab.graphics.chart.interaction.dataannotatable.PatchHelper.getNearestIndex(hObj.AnnotationTarget, index);
        end
        
        function index = doGetNearestPoint(hObj, position)
            index = matlab.graphics.chart.interaction.dataannotatable.PatchHelper.getNearestPoint(hObj.AnnotationTarget, position);
        end
        
        function [index, interpolationFactor] = doGetInterpolatedPoint(hObj, position)
            [index, interpolationFactor] = matlab.graphics.chart.interaction.dataannotatable.PatchHelper.getInterpolatedPoint(hObj.AnnotationTarget, position);
        end
        
        function [index, interpolationFactor] = doGetInterpolatedPointInDataUnits(hObj, position)
            [index, interpolationFactor] = matlab.graphics.chart.interaction.dataannotatable.PatchHelper.getInterpolatedPointInDataUnits(hObj.AnnotationTarget, position);
        end
        
        function points = doGetEnclosedPoints(~, ~)
            % The adaptor does not yet participate with brushing.
            points = [];
        end
        
        function [index, interpolationFactor] = doIncrementIndex(hObj, index, direction, interpolationStep)
            [index, interpolationFactor] = matlab.graphics.chart.interaction.dataannotatable.PatchHelper.incrementIndex(hObj.AnnotationTarget, index, direction, interpolationStep);
        end
        
        function point = doGetDisplayAnchorPoint(hObj, index, interpolationFactor)
            point = matlab.graphics.chart.interaction.dataannotatable.PatchHelper.getDisplayAnchorPoint(hObj.AnnotationTarget, index, interpolationFactor);
        end
        
        function point = doGetReportedPosition(hObj, index, interpolationFactor)
            point = matlab.graphics.chart.interaction.dataannotatable.PatchHelper.getReportedPosition(hObj.AnnotationTarget, index, interpolationFactor);
        end
    end
end
