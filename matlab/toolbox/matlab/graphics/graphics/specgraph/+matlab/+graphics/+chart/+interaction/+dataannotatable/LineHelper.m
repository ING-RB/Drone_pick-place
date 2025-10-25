classdef(Sealed = true) LineHelper < handle
    % A helper class that provides implementations of DataAnnotatable
    % interface methods for Line subclasses.
    
    %   Copyright 2010-2014 The MathWorks, Inc.
    
    methods(Access = private)
        % We will make the constructor private to prevent instantiation.
        function hObj = LineHelper
        end
    end
    
    methods(Access = public, Static = true)
        
        function [index,int_factor] = incrementIndex(hLine, index, direction,interpolation_factor)
            % get next valid index in the data : skip NaNs and Infs based
            % on the direction of the movement (up,right ,left dowm)
            
            int_factor = interpolation_factor; % we dont change the interpolation factor here, just passing through
            nextIndex = index;

            %use the DataCache properties in order to get the numeric representation of the data.
            xd = hLine.XDataCache;
            yd = hLine.YDataCache;
            zd = hLine.ZDataCache;
            indToAllow = isfinite(xd).* isfinite(yd);
            
            if ~isempty(zd)
                indToAllow = indToAllow.*isfinite(zd);
            end
            
            if strcmpi(direction,'up') || strcmpi(direction,'right')
                nextIndex = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getNearestIndex(hLine,nextIndex + 1);
                if ~indToAllow(nextIndex)
                    nextIndex = nextIndex + find(indToAllow((nextIndex+1):end), 1, 'first');
                end
                
            elseif strcmpi(direction,'down') || strcmpi(direction,'left')
                nextIndex = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getNearestIndex(hLine,nextIndex - 1);
                if ~indToAllow(nextIndex)
                    nextIndex = find(indToAllow(1:nextIndex), 1, 'last');
                end
            end
            
            if ~isempty(nextIndex)
                index = nextIndex;
            end
            
        end
   
        function descriptors = getDataDescriptors(hLine, index, interpolationFactor)
            % Get the data descriptors for a Line given the index and
            % interpolation factor.
            primpos = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getReportedPosition(hLine,index,interpolationFactor);
            pos = primpos.getLocation(hLine);
            descriptors = matlab.graphics.chart.interaction.dataannotatable.internal.createPositionDescriptors(hLine,pos);
        end        
               
        function index = getNearestIndex(hLine, index)
            % Return the nearest index to the requested input.
            
            % If the index is in range, we will return the index.
            % Otherwise, we will error.
            yd = hLine.YDataCache;
            numPoints = numel(yd);
            
            % Constrain index to be in the range [1 numPoints]
            if numPoints>0
                index = max(1, min(index, numPoints));
            end
        end
        
        function index = getNearestPoint(hLine, position)
            % Returns the index representing the point on the Line nearest
            % to a 1x2 pixel position in the figure.
            
            [index1, index2, t] = localGetNearestSegment(hLine, position, true);
            if t<=0.5
                index = index1;
            else
                index = index2;
            end
            if isempty(index)
                index = 1;
            end
        end
        
        
        
        function index = getEnclosedPoints(hLine, polygon)
            
            xd = hLine.XDataCache;
            yd = hLine.YDataCache;
            zd = hLine.ZDataCache;
            data = {xd, yd};
            if ~isempty(zd)
                data{3} = zd;
            end
            
            % Translate polygon into local container reference frame
            polygon = brushing.select.translateToContainer(hLine, polygon);
            
            % Treat data as scattered points and just look for the
            % closest
            utils = matlab.graphics.chart.interaction.dataannotatable.picking.AnnotatablePicker.getInstance();
            index = utils.enclosedPoints(hLine, polygon, data{:});
        end
        
        function [index, interpolationFactor] = getInterpolatedPoint(hLine, position)
            % Returns the index and interpolation factor representing the
            % point on the Line nearest to a 1x2 pixel position in the
            % figure.
            
            [index, ~, interpolationFactor] = localGetNearestSegment(hLine, position, true);
        end
        
        function [index, interpolationFactor] = getInterpolatedPointInDataUnits(hLine, position)
            % Returns the index and interpolation factor representing the
            % point on the Line nearest to a  data unit position in the
            % figure.
             [index, ~, interpolationFactor] = localGetNearestSegment(hLine, position, false);
            if isempty(index)
                index = 1;
            end
        end 

        function [index] = getNearestPointInDataUnits(hLine, position)
            % Returns the index and interpolation factor representing the
            % point on the Line nearest to a  data unit position in the
            % figure.
             [index1, index2, interpolationFactor] = localGetNearestSegment(hLine, position, false);
             if interpolationFactor<=0.5
                index = index1;
            else
                index = index2;
            end
            if isempty(index)
                index = 1;
            end
        end       
        
        function pos = getDisplayAnchorPoint(hLine, index, interpolationFactor)
            % Returns the position that should be used to overlay views on
            % the Line for the given index and interpolation factor.
            
            pos = matlab.graphics.shape.internal.util.LinePoint(...
                localGetPoint(hLine, index), ...
                localGetPoint(hLine, index+1), ...
                interpolationFactor);
        end
        
        function pos = getReportedPosition(hLine, index, interpolationFactor)
            % Returns the position that should be reported back to the user
            % for the given index and interpolation factor.
            
            % The reported position is the same as the anchor position,
            % except the Z value is completely dropped if there is no Z
            % data.
            pos = matlab.graphics.chart.interaction.dataannotatable.LineHelper.getDisplayAnchorPoint(hLine, index, interpolationFactor);
            zd = hLine.ZDataCache;
            if isempty(zd)
                pos.Is2D = true;
            end
        end
    end
    
    
    
    
end


function [index1, index2, t] = localGetNearestSegment(hLine, position, isPixelPoint)


xd = hLine.XDataCache;
yd = hLine.YDataCache;
zd = hLine.ZDataCache;
data = {xd, yd};

if ~isempty(zd)
    data{3} = zd;
end

% Check that data sizes are consistent
sz = cellfun(@numel, data, 'UniformOutput', true);
if ~all(sz==1 | sz==max(sz))
    index1 = 1;
    index2 = 1;
    t = 0;
    return
end

utils = matlab.graphics.chart.interaction.dataannotatable.picking.AnnotatablePicker.getInstance();
if strcmpi(hLine.LineStyle,'none')
    % Treat data as scattered points and just look for the
    % closest
    index1 = utils.nearestPoint(hLine, position, isPixelPoint, data{:});
    index2 = index1;
    t = 0;
else
    % Treat data as a sequence of line segments and pick the
    % closest segment
    isLOD = false;
    if ~isempty(hLine.Edge) && ~isempty(hLine.Edge.StripData) && isprop(hLine,'EdgeDetailLimit') && ...
            ~isempty(hLine.EdgeDetailLimit)
                        
        sizeVertexData = hLine.Edge.StripData(end)-1;                        
        
        isLOD = numel(hLine.Edge.StripData) == 2 &&...
                sizeVertexData <= hLine.EdgeDetailLimit &&...
                sizeVertexData < numel(hLine.XData) &&...
                localIsDataFinite(hLine) &&...
                localIsDataHomogeneous(hLine);
                                
        % If hLine is parented to a DataSpace, then get it. Otherwise do
        % not used the optimized LOD path
        if isLOD
            [~, ~, dataSpace, transformBelowDataSpace] = matlab.graphics.internal.getSpatialTransforms(hLine);
            if isempty(dataSpace)
                isLOD = false;
            end
        end
      
    end
    if isLOD && isequal(hLine.Edge.StripData,[1 size(hLine.Edge.VertexData,2)+1]) && ...
            isempty(hLine.Edge.VertexIndices)
        % If level of detail is on, and this is a continous line,
        % then pick the line segment in thinned coordinates for performance 
        % reasons (g1881148)
        data = matlab.graphics.internal.transformWorldToData(dataSpace, transformBelowDataSpace, ...
            hLine.Edge.VertexData);
        dataInColumns = num2cell(data',1);
        [thinnedIndex1, thinnedIndex2, t] = utils.nearestSegment(hLine, position, isPixelPoint, dataInColumns{:});
        
        % Find the indices matching thinnedIndex1, thinnedIndex2 in
        % un-thinned coordinated. Note that since thinned coordinates 
        % exactly coincide with a subset of un-thinned coordinates, this 
        % comparison will work even in nonlinear data spaces   
        if isempty(hLine.ZDataCache)
            [~,index1] = min((data(1,thinnedIndex1)-hLine.XDataCache).^2+...
                (data(2,thinnedIndex1)-hLine.YDataCache).^2);
            [~,index2] = min((data(1,thinnedIndex2)-hLine.XDataCache).^2+...
                (data(2,thinnedIndex2)-hLine.YDataCache).^2);
        else
            [~,index1] = min((data(1,thinnedIndex1)-hLine.XDataCache).^2+...
                (data(2,thinnedIndex1)-hLine.YDataCache).^2 + (data(3,thinnedIndex1)-hLine.ZDataCache).^2);
            [~,index2] = min((data(1,thinnedIndex2)-hLine.XDataCache).^2+...
                (data(2,thinnedIndex2)-hLine.YDataCache).^2 + (data(3,thinnedIndex2)-hLine.ZDataCache).^2);
        end
    else
        [index1, index2, t] = utils.nearestSegment(hLine, position, isPixelPoint, data{:});
    end
end

end


function ret = localIsDataHomogeneous(hLine)
% Returns true if all the data is of the same class 
if ~isempty(hLine.ZDataCache)
    ret  = isequal(class(hLine.XDataCache),class(hLine.YDataCache),class(hLine.ZDataCache));   
else
    ret = isequal(class(hLine.XDataCache),class(hLine.YDataCache));
end
end


function ret = localIsDataFinite(hLine)
% Returns true if all the data is finite

validInd = isfinite(hLine.XDataCache) & isfinite(hLine.YDataCache); 
 if ~isempty(hLine.ZDataCache)
     validInd = validInd & isfinite(hLine.ZDataCache);     
 end

ret = all(validInd); 
end


function pt = localGetPoint(hLine, index)
% Get the (x,y,z) values of a point on the line

pt = [0 0 0];
xd = hLine.XDataCache;
yd = hLine.YDataCache;
zd = hLine.ZDataCache;
pt(1) = localIndexData(xd, index);
pt(2) = localIndexData(yd, index);
if ~isempty(zd)
    pt(3) = localIndexData(zd, index);
end
end

function val = localIndexData(data, index)
%Index into a vector if the index is valid, return NaN otherwise.

if index>0 && index<=numel(data)
    val = data(index);
else
    val = NaN;
end
end


