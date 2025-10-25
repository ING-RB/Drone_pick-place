classdef (Sealed)ImageAdaptor < matlab.graphics.chart.interaction.dataannotatable.AnnotationAdaptor
    % A helper class to support Data Cursors on legacy Image objects.
    
    %   Copyright 2010-2021 The MathWorks, Inc.
    
    properties(Access=private, Transient)
        ImageDataListener;
    end
    
    methods
        function hObj = ImageAdaptor(hImage)
            hObj@matlab.graphics.chart.interaction.dataannotatable.AnnotationAdaptor(hImage);
        end
        
        % DataAnnotatable interface methods
        function dataTipRows = createDefaultDataTipRows(hObj)
            % We will return one datatip row for the position and one
            % or two for the color, depending on whether the Image is
            % indexed or RGB.
            hImage = hObj.AnnotationTarget;
            dataTipRows = dataTipTextRow('[X,Y]','[X,Y]');
            
            % If we have a scaled image, we will have two coordinates - one
            % for the index, the other for the RGB value.
            if ismatrix(hImage.CData)
                if ~ishghandle(ancestor(hObj,'axes'))
                    return;
                end
                dataTipRows = [dataTipRows, ...
                    dataTipTextRow('Index','Index')];
            end
            dataTipRows = [dataTipRows, ...
                dataTipTextRow('[R,G,B]','[R,G,B]')];
        end
        
        function coordinateData = createCoordinateData(hObj, valueSource, dataIndex, ~)
            import matlab.graphics.chart.interaction.dataannotatable.internal.CoordinateData;
            % We will return one data coordinate for the position and one
            % or two for the color, depending on whether the Image is
            % indexed or RGB.
            hImage = hObj.AnnotationTarget;
            coordinateData = CoordinateData.empty(0,1);

            % Start by computing the position of the point:
            primpos = getReportedPosition(hObj, dataIndex, 0);
            location = primpos.getLocation(hImage);

            switch(valueSource)
                case '[X,Y]'
                    coordinateData = CoordinateData(valueSource,location(1:2));
                case '[R,G,B]'
                    cData = hImage.CData;
                    if all(isnan(location)) || (ismatrix(cData) && ~ishghandle(ancestor(hObj,'axes')))
                        coordinateData = CoordinateData('[R,G,B]',[NaN NaN NaN]);
                    else                        
                        colorDims = ndims(cData);
                        % If we have a scaled image, we will have two coordinates - one
                        % for the index, the other for the RGB value.
                        if colorDims == 2
                            ax = ancestor(hObj,'axes');
                            % create the iterator for data retrieval
                            hColorIter = matlab.graphics.axis.colorspace.IndexColorsIterator;
                            hColorIter.Colors = cData;
                            hColorIter.CDataMapping = hImage.CDataMapping;
                            hColorIter.Indices = dataIndex;

                            % TransformColormappedToTrueColor - is used to get the
                            % RGB values for the desired index. For large images, LOD
                            % is applied and the only way to get the correct
                            % corresponding RGB values from the downsampled image data is using the transform.
                            colorData = ax.ColorSpace.TransformColormappedToTrueColor(hColorIter);
                            coordinateData = CoordinateData('[R,G,B]',formatColorData(colorData.Data));
                        else
                            cdataSize = size(cData);
                            imageSize = cdataSize(1)*cdataSize(2);
                            actColor = reshape(cData([dataIndex, dataIndex+imageSize, dataIndex+2*imageSize]),1,3);
                            coordinateData = CoordinateData('[R,G,B]',actColor);
                        end
                    end
                case 'Index'
                    % if index is out of range    
                    cData = hImage.CData;
                    if all(isnan(location)) || (ismatrix(cData) && ~ishghandle(ancestor(hObj,'axes')))
                        coordinateData = CoordinateData('Index',cIndex);
                        return;
                    else
                        colorIndex = NaN;                        
                        if ismatrix(cData)
                            colorIndex = double(cData(dataIndex));
                        end
                        coordinateData = CoordinateData('Index',colorIndex);
                    end
            end
        end
        
        % Overridden function that returns a string array of valid valueSources
        function valueSources = getAllValidValueSources(hObj)
            valueSources = ["[X,Y]"; "[R,G,B]"];
            if ismatrix(hObj.AnnotationTarget.CData) && ishghandle(ancestor(hObj,'axes'))
                valueSources = [valueSources;"Index"];
            end
        end
    end
    
    methods(Access=protected)
        function doSetAnnotationTarget(hObj, hTarget)
            % Enforce that the target is an image
            if ~ishghandle(hTarget,'image')
                error(message('MATLAB:specgraph:chartMixin:dataannotatable:ImageAdaptor:InvalidImage'));
            end
            
            % Add a listener to the image data to fire the DataChanged event
            hObj.ImageDataListener = event.proplistener(hTarget, ...
                {hTarget.findprop('XData'), hTarget.findprop('YData'), hTarget.findprop('CData')}, ...
                'PostSet',@(obj,evd)(hObj.sendDataChangedEvent));
        end
    end
    
    
    % DataAnnotatable interface methods
    methods(Access='protected')
        function descriptors = doGetDataDescriptors(hObj, index, ~)
            % We will return one data descriptor for the position and one
            % or two for the color, depending on whether the Image is
            % indexed or RGB.
            hImage = hObj.AnnotationTarget;
            
            % Start by computing the position of the point:
            primpos = getReportedPosition(hObj, index, 0);
            location = primpos.getLocation(hImage);
            locDescriptor = matlab.graphics.chart.interaction.dataannotatable.DataDescriptor('[X,Y]',location(1:2));
            
            if all(isnan(location))
                % if index is out of rannge
                descriptors = [locDescriptor, ...
                    matlab.graphics.chart.interaction.dataannotatable.DataDescriptor('[R,G,B]',[NaN NaN NaN])];
                return;
            end
            
            
            cData = hImage.CData;
            colorDims = ndims(cData);
            
            % If we have a scaled image, we will have two descriptors - one
            % for the index, the other for the RGB value.
            if colorDims == 2
                
                ax = ancestor(hObj,'axes');
                
                if ~ishghandle(ax)
                    descriptors = locDescriptor;
                    return;
                end
                
                % create the iterator for data retrieval
                hColorIter = matlab.graphics.axis.colorspace.IndexColorsIterator;
                hColorIter.Colors = cData;
                hColorIter.CDataMapping = hImage.CDataMapping;
                hColorIter.Indices = index;
                
                % TransformColormappedToTrueColor - is used to get the
                % RGB values for the desired index. For large images, LOD
                % is applied and the only way to get the correct
                % corresponding RGB values from the downsampled image data is using the transform.
                
                colorData = ax.ColorSpace.TransformColormappedToTrueColor(hColorIter);
                colorIndex = cData(index);
                actColor = formatColorData(colorData.Data);
                descriptors = [locDescriptor, ...
                    matlab.graphics.chart.interaction.dataannotatable.DataDescriptor('Index',double(colorIndex)),...
                    matlab.graphics.chart.interaction.dataannotatable.DataDescriptor('[R,G,B]',actColor)];
                
            else
                % Otherwise, the image is a true color image: get the color
                % directly from the image
                
                cdataSize = size(cData);
                imageSize = cdataSize(1)*cdataSize(2);
                actColor = reshape(cData([index, index+imageSize, index+2*imageSize]),1,3);
                descriptors = [locDescriptor, ...
                    matlab.graphics.chart.interaction.dataannotatable.DataDescriptor('[R,G,B]',actColor)];
                
            end
        end
        
        function index = doGetNearestIndex(hObj, index)
            % If the index is in range, we will return the index.
            % Otherwise, we will error.
            % The number of points is based on the size of the Image CData.
            % We need to be robust to true color images, so a call to NUMEL
            % will not suffice.
            imSize = size(hObj.AnnotationTarget.CData);
            numPoints = imSize(1)*imSize(2);
            
            % Constrain index to be in the range [1 numPoints]
            if numPoints>0
                index = max(1, min(index, numPoints));
            end
        end
        
        function index = doGetNearestPoint(hObj, position)
            
            % We want to treat the x and y directions as two separate 1D line
            % interpolation problems, with each line using the min and max
            % of the face vertices in that direction as its endpoints.
            
            hImage = hObj.AnnotationTarget;
            
            % Form basis vectors in data units
            [basis_row, basis_col, origin] = localGetBasisVectors(hImage);
            
            % Transform the data into pixel points in the viewer.
            % Transformations must be done on points, not the vectors
            % themselves, so first we need to convert back to the corner
            % points.
            rowPoint = origin + basis_row;
            colPoint = origin + basis_col;
            pixelLocations = matlab.graphics.chart.internal.convertDataSpaceCoordsToViewerCoords...
                (hImage, [origin, rowPoint, colPoint]);
            basis_row = pixelLocations(:,2) - pixelLocations(:,1);
            basis_col = pixelLocations(:,3) - pixelLocations(:,1);
            
            point_v = position.' - pixelLocations(:,1);
            
            index = getNearestImageIndex(hObj, point_v, basis_row, basis_col);
        end
        
        function [index, interpolationFactor] = doGetInterpolatedPoint(hObj, position)
            % An Image represents discrete quantities only. Consequently,
            % we will delegate to the "doGetNearestPoint" method.
            index = hObj.doGetNearestPoint(position);
            interpolationFactor = 0;
        end
        
        function [index, interpolationFactor] = doGetInterpolatedPointInDataUnits(hObj, position)
            % An Image represents discrete quantities only. Consequently,
            % we will delegate to the "doGetNearestPoint" method.
            % Image requires the interpolated point to be in pixels always,
            % thats why conversion is needed here
            figPoint = matlab.graphics.chart.internal.convertDataSpaceCoordsToViewerCoords(hObj.Parent,position(:));
            hFigure = ancestor(hObj.Parent,'figure');
            figPoint = figPoint';
            figPoint = hgconvertunits(hFigure,[figPoint 0 0],get(hFigure,'Units'),'pixels',hFigure);
            position = figPoint(1:2);
            index = hObj.doGetNearestPoint(position);
            interpolationFactor = 0;
        end
        
        function points = doGetEnclosedPoints(~, ~)
            % The adaptor will not participate with brushing.
            points = [];
        end
        
        function [index, interpolationFactor] = doIncrementIndex(hObj, index, direction, ~)
            % The index will be treated as an index into the CData, which is a matrix.
            dataSize = size(hObj.AnnotationTarget.CData);
            % We need to protect against true color CData, so we will only
            % look at the first two dimensions.
            dataSize = dataSize(1:2);
            [currRow, currCol] = ind2sub(dataSize, index);
            
            ax = ancestor(hObj.AnnotationTarget, 'axes');
            if ~isempty(ax)
                if strcmp(ax.XDir, 'reverse')
                    direction = localFlipDirection(direction, 'left', 'right');
                end
                if strcmp(ax.YDir, 'reverse')
                    direction = localFlipDirection(direction, 'up', 'down');
                end
            end
            
            retInd = index;
            try
                switch(direction)
                    case 'up'
                        % This should increment the row.
                        newRow = currRow + 1;
                        modVal = mod(newRow-1,dataSize(1))+1;
                        addVal = ~(modVal==newRow);
                        newRow = modVal;
                        % If we saturate the row, increment the column:
                        newCol = currCol + addVal;
                    case 'down'
                        % This should decrement the row
                        newRow = currRow-1;
                        % If we saturate the row, decrement the column:
                        addVal = ~(newRow>0);
                        newRow = newRow + dataSize(1)*addVal;
                        newCol = currCol - addVal;
                    case 'left'
                        % This should decrement the column
                        newCol = currCol-1;
                        % If we saturate the column, decrement the row:
                        addVal = ~(newCol>0);
                        newCol = newCol + dataSize(2)*addVal;
                        newRow = currRow - addVal;
                    case 'right'
                        % This should increment the column.
                        newCol = currCol + 1;
                        modVal = mod(newCol-1,dataSize(2))+1;
                        addVal = ~(modVal==newCol);
                        newCol = modVal;
                        % If we saturate the column, increment the row:
                        newRow = currRow + addVal;
                end
                retInd = sub2ind(dataSize, newRow, newCol);
            catch E %#ok<NASGU>
                % We will do nothing here as the index can not be incremented.
            end
            index = retInd;
            interpolationFactor = 0;
        end
        
        function point = doGetDisplayAnchorPoint(hObj, index, ~)
            % The display anchor point is simply the location with the
            % z-coordinate at 0.
            hImage = hObj.AnnotationTarget;
            cData = hImage.CData;
            
            dataSize = size(cData);
            dataSize = dataSize(1:2);
            if index<=prod(dataSize) && index>0
                [yInd,xInd] = ind2sub(dataSize,index);
            else
                xInd = NaN;
                yInd = NaN;
            end

            if isempty(hImage.getXExtents()) || isempty(hImage.getYExtents())
                % If there are no extents, we may not have run an update yet.
                drawnow nocallbacks;
            end
            point = matlab.graphics.shape.internal.util.ImagePoint(...
                hImage.getXExtents(), ...
                hImage.getYExtents(), ...
                dataSize, xInd, yInd);
        end
        
        function point = doGetReportedPosition(hObj, index, ~)
            % The reported position is the same as the anchor point.
            point = doGetDisplayAnchorPoint(hObj, index, 0);
            point.Is2D = true;
        end
    end
    
    
    methods(Access = private)
        function index = getNearestImageIndex(hObj, pointVect, rowBasis, colBasis)
            % Find the index of the nearest image element, given a hit
            % point and sets of x/y limits that define a reference frame
            % for the point.  The reference frame is assumed to extend from
            % the start of the first image pixel to the end of the last
            % one, i.e. it is the image limits, not the pixel centers.
            
            % Project the point vector onto each of the basis vectors
            k = [rowBasis(:), colBasis(:)]\pointVect(:);
            
            dataSize = size(hObj.AnnotationTarget.CData);
            dataSize = dataSize(1:2);
            
            % Scale to data pixels
            nRC = ceil(k.'.*dataSize);
            
            % Clamp to data size
            nRC = max(nRC, [1 1]);
            nRC = min(nRC, dataSize);
            
            % Convert to linear index
            index = sub2ind(dataSize, nRC(1), nRC(2));
        end
    end
end


function [basis_row, basis_col, origin] = localGetBasisVectors(hImage)
% Get the vectors that form the row/column edges of the image, and the
% origin they operate from.
cData = hImage.CData;
dataSize = size(cData);

% Get the image visual limits from the XData and YData and size
if isempty(hImage.getXExtents()) || isempty(hImage.getYExtents())
    % If there are no extents, we may not have run an update yet.
    drawnow nocallbacks;
end
xLims = hImage.getXExtents();
yLims = hImage.getYExtents();

% Use basis vectors that are parallel to the x and y axes since
% we are looking down on the image from straight above.
basis_col = [xLims(2)-xLims(1) ; 0; 0];
basis_row = [0 ; yLims(2)-yLims(1); 0];
origin = [xLims(1); yLims(1); 0];
end


function direction = localFlipDirection(direction, alt1, alt2)
% Flip a direction string to the opposite possibility
if strcmp(direction, alt1)
    direction = alt2;
elseif strcmp(direction, alt2)
    direction = alt1;
end
end


function actColor = formatColorData(color)
% Formats color data for represention in datadescriptors
actColor = double(color)/255;
actColor = actColor(1:3).';
end
