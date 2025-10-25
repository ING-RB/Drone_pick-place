function index = nearestPoint(obj, hContext, point, pointPixel, varargin)
%nearestPoint Find the index of the nearest point
%
%  nearestPoint(obj, hContext, point, pointPixel, data) returns the index
%  of the point in the 2D or 3D data array that is visually closest to the
%  provided point. The data array should be of size (Nx2) or (Nx3) and the
%  point should be either a data point or a pixel point.  The type of
%  target is specified by setting pointPixel to true or false.
% 
%  nearestPoint(obj, hContext, point, pointPixel, xdata, ydata, zdata)
%  performs the same operation on separate X, Y, and (optional) Z data
%  vectors.
%
%  nearestPoint(..., metric) specifies a distance metric to use for the
%  comparison.  Valid options are 'euclidean', 'x' and 'y'.

%  Copyright 2013-2018 The MathWorks, Inc.

if ischar(varargin{end})
    % Use the specified metric
    metric = varargin{end};
    varargin(end) = [];
               
    if strcmpi(metric,'x')
        % create a unit vector and transform it to test its resulting angle in the current view
        xUnit = [1,0,0];
        ThetaInDegrees = getAngleInViewSpace(hContext,xUnit);
        % switch automatically to the y metric for angles greater than 45 deg.
        if ThetaInDegrees > 45
            metric = 'y';
        end
    elseif strcmpi(metric,'y')
        % create a unit vector and transform it to test its resulting angle in the current view
        yUnit = [0,1,0];
        ThetaInDegrees = getAngleInViewSpace(hContext,yUnit);
        % switch automatically to the x metric for angles greater than 45 deg.
        if ThetaInDegrees > 45
            metric = 'x';
        end
    end
    
else
    % Default to euclidean measure
    metric = 'euclidean';
end

index = zeros(1,0);

% Convert target to picking space
point = obj.targetPointToPickSpace(hContext, point, pointPixel);

% Filter out non-visible data
valid = obj.isValidInPickSpace(hContext, varargin{:});

if any(valid) && all(isfinite(point))
    % Transform data into pixel locations
    pixelLocations = obj.convertToPickSpace(hContext, varargin, valid);
    
    index = matlab.graphics.chart.interaction.dataannotatable.picking.nearestPoint(point, pixelLocations, metric);
    
    if ~all(valid)
        % Map back to data index
        validInd = find(valid, index);
        index = validInd(index);
    end
end
end

%Calculates the angle between the specified unit vector and the view by
%projecting the unit vector to the current view
function angleDegrees = getAngleInViewSpace(hContext,unitVector)
angleDegrees = 0;
hAx = ancestor(hContext,'axes','node');
if ~isempty(hAx)
    [az,el] = view(hAx);
    % get the current view transform matrix
    T = viewmtx(az,el);
    % transform the unit vector to get its resulting angle in the current view
    vResult = T*[unitVector,1]';
    % norm of unit vector is 1 so the dot product will result in cos(Theta)
    CosTheta = dot(unitVector,vResult(1:3));
    angleDegrees = acosd(CosTheta);
end
end


