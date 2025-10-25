function finalRect = rbbox(initialRectangle, anchorPoint, step)
%RBBOX  Rubberband box.
%
%   RBBOX initializes and tracks a rubberband box in the current figure. It
%   sets the initial rectangular size of the box to 0, anchors the box at
%   the figure's CurrentPoint, and begins tracking from this point.
%
%   RBBOX(initialRect) specifies the initial location and size of the
%   rubberband box as [x y width height], where x and y define the
%   lower-left corner, and width and height define the size. initialRect is
%   in the units specified by the current figure's Units property, and
%   measured from the lower-left corner of the figure window. The corner of
%   the box closest to the pointer position follows the pointer until RBBOX
%   receives a button-up event.
%
%   RBBOX(initialRect,fixedPoint) specifies the corner of the box that
%   remains fixed. All arguments are in the units specified by the current
%   figure's Units property, and measured from the lower-left corner of the
%   figure window. fixedPoint is a two-element vector, [x y]. The tracking
%   point is the corner diametrically opposite the anchored corner defined
%   by fixedPoint.
%
%   RBBOX(initialRect,fixedPoint,stepSize) specifies how frequently the
%   rubberband box is updated. When the tracking point exceeds stepSize
%   figure units, RBBOX redraws the rubberband box. The default stepsize is
%   1.
%
%   finalRect = RBBOX(...) returns a four-element vector, [x y width
%   height], where x and y are the x and y components of the lower-left
%   corner of the box, and width and height are the dimensions of the box.
%
%   The mouse button must be down when RBBOX is called. RBBOX can be used in
%   a ButtondownFcn, or in a script or function, along with 
%   WAITFORBUTTONPRESS, to control dynamic behavior.
%
%   Example:
%
%   % Interactively plot a rectangle within an axes
%   f = figure;
%   a = axes('Parent',f);
%   disableDefaultInteractivity(a)
%   k = waitforbuttonpress;
%   point1 = a.CurrentPoint;    % button down detected
%   finalRect = rbbox;                 % return figure units
%   point2 = a.CurrentPoint;    % button up detected
%   point1 = point1(1,1:2);            % extract x and y
%   point2 = point2(1,1:2);
%   enableDefaultInteractivity(a)
%   p1 = min(point1,point2);           % calculate locations
%   offset = abs(point1-point2);       % and dimensions
%   x = [p1(1) p1(1)+offset(1) p1(1)+offset(1) p1(1) p1(1)];
%   y = [p1(2) p1(2) p1(2)+offset(2) p1(2)+offset(2) p1(2)];
%   hold on
%   axis manual
%   plot(x,y)                          % redraw in dataspace units
%
%   See also WAITFORBUTTONPRESS, DRAGRECT.

%   Copyright 1984-2020 The MathWorks, Inc.

arguments
    initialRectangle {mustBeNumeric, mustBeNonNan, mustBeReal, mustBeSize(initialRectangle, 1, 4)} = [0 0 0 0]
    anchorPoint {mustBeNumeric, mustBeNonNan, mustBeReal, mustBeSize(anchorPoint, 1, 2)} = [0 0]
    step (1, 1) {mustBeNumeric, mustBeNonNan, mustBeReal} = 1
end

if nargin == 0
    initRect = [];
    fixedPoint = [];
    stepSize = [];
elseif nargin == 1
    initRect = initialRectangle;
    fixedPoint = [];
    stepSize = [];
elseif nargin == 2
    initRect = initialRectangle;
    fixedPoint = anchorPoint;
    stepSize = [];
elseif nargin == 3
    initRect = initialRectangle;
    fixedPoint = anchorPoint;
    stepSize = step;
end

f = gcf;

% If the mouse button is not down when calling rbbox, return early
if(~matlab.graphics.interaction.internal.rbbox.isMouseDown())
    if(isempty(initRect))
        finalRect = [f.CurrentPoint 0 0];
    else
        finalRect = initRect;
    end
    return;
end

% Convert input arguments from figure's units to pixels
if(~isempty(initRect))
    initRect = double(initRect);
    initRect = hgconvertunits(f, initRect, f.Units, 'pixels', f);
end

if(~isempty(fixedPoint))
    fixedPoint = double(fixedPoint);
    fixedPointInPixels = hgconvertunits(f, [fixedPoint 0 0], f.Units, 'pixels', f);
    fixedPoint = fixedPointInPixels(1:2);
end

if(~isempty(stepSize))
    stepSize = double(stepSize);
    stepSizeInPixels = hgconvertunits(f, [stepSize 0 0 0], f.Units, 'pixels', f);
    stepSize = stepSizeInPixels(1);
else
    stepSize = 1;
end

% Create a Rectangle object to draw the rubberband box
box = matlab.graphics.interaction.internal.rbbox.Rectangle(f);
box.setStepSize(stepSize);

%Mouse button is already down, so call the mousedown function
mousedown(f, box, initRect);
%Add the mouse motion and button up listeners to the figure
mouseMoveListener = event.listener(f, 'WindowMouseMotion', ...
    @(~, eventdata) mousemove(eventdata.Point, box, fixedPoint, f));
mouseUpListener = event.listener(f, 'WindowMouseRelease', @(~, ~) mouseup(box));

% Handle cleanup
cleanupObj = onCleanup(@()cleanupFcn(mouseMoveListener, mouseUpListener, box)); 

% Block execution until rectangle is invisible on mouse up
waitfor(box, 'Visible', false);

% Get the position of the final rectangle in pixels
finalRectInPixels = box.getPosition();
% Convert to the figure's units
finalRect = hgconvertunits(f, finalRectInPixels, 'pixels', f.Units, f);

end

% Custom validator function to check array size
function mustBeSize(arg, rows, cols)
    classes = {'numeric'};
    attributes = {'nrows', rows, 'ncols', cols};
    funcName = 'rbbox';
    
    validateattributes(arg, classes, attributes, funcName);
end

function mousedown(f, box, initRect)
    fcp = f.CurrentPoint;
    fcpInPixels = hgconvertunits(f, [fcp 0 0], f.Units, 'pixels', f);
    fcp = fcpInPixels(1:2);

    if(isempty(initRect))
        initRect = [fcp(1) fcp(2) 0 0];
    end

    box.setInitialPosition(initRect);
    box.draw();
    box.show();
end

function mousemove(currentPoint, box, fixedPoint, f)
    if (~box.Visible)
        return;
    end

    if(isempty(fixedPoint))
        initialPosition = box.getInitialPosition();
        fixedPoint = [initialPosition(1) initialPosition(2)];
    end

    box.setStartPoint(fixedPoint);

    % Get the current point in pixels
    currentPointInPixels = hgconvertunits(f, [currentPoint 0 0], f.Units, 'pixels', f);
    currentPoint = currentPointInPixels(1:2);
    box.update(currentPoint);
end

function mouseup(box)
    box.hide();
end

function cleanupFcn(mouseMoveListener, mouseUpListener, box)
    % Delete the mouse move and mouse up listeners
    mouseMoveListener.delete;
    mouseUpListener.delete;

    % Delete the Rectangle used to draw the rubberband box
    box.delete();
end

