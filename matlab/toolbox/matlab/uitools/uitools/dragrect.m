function [finalRects] = dragrect(initialRectangles, step)
%DRAGRECT Drag XOR rectangles with mouse.
%   DRAGRECT(RECTS) allows the rectangles specified in the
%   N-by-4 matrix RECTS to be dragged with the mouse while a mouse
%   button is down.  Rectangles can be dragged anywhere on the
%   screen.
%
%   DRAGRECT(RECTS, STEPSIZE) moves the rectangles only in increments
%   of STEPSIZE.  The lower-left corner of the first rectangle
%   is constrained to the grid of size STEPSIZE starting at the
%   lower-left corner of the figure, and all other rectangles
%   maintain their original offset from the first rectangle.
%
%   RECTS2=DRAGRECT(...) returns the final positions of the rectangles
%   specified in RECTS when the mouse button is released.
%
%   Each row of RECTS must contain the initial rectangle position
%   as [left bottom width height].  DRAGRECT returns the final
%   position of the rectangles.  If the drag ends over a
%   figure window, the positions of the rectangles  are
%   returned in that figure's coordinate system.  If the drag ends
%   over a part of the screen not contained within a figure window,
%   the rectangles are returned in the coordinate system of the
%   figure over which the drag began.  DRAGRECT returns immediately
%   if a mouse button is not down.
%
%   Note that you cannot use normalized figure units with DRAGRECT.
%   
%   Examples:
%       dragrect(BoxPos);
%       dragrect(BoxPos, 2.0);
%       NewBoxPos=dragrect(BoxPos);
%
%   See also RBBOX.

%   Copyright 1984-2020 The MathWorks, Inc.


arguments
   initialRectangles {mustBeNumeric, mustBeNonempty, mustBeNonNan, mustBeReal, mustHave4Columns}
   step (1, 1) {mustBeNumeric, mustBeNonNan, mustBeReal} = 1 
end

stepSize = 1;
if nargin == 2
    stepSize = step;
end

% Make sure the input arguments are doubles
initialRectangles = double(initialRectangles);
stepSize = double(stepSize);

f = gcf;

% If the mouse button is not down when calling dragrect, return early
if(~matlab.graphics.interaction.internal.rbbox.isMouseDown())
    finalRects = initialRectangles;
    return;
end

mouseDownPoint = f.CurrentPoint;
mouseDownPointInPixels = hgconvertunits(f, [mouseDownPoint 0 0], f.Units, 'pixels', f);
mouseDownPoint = mouseDownPointInPixels(1:2);

[numBoxes, ~] = size(initialRectangles);
boxes = matlab.graphics.interaction.internal.rbbox.Rectangle.empty(0, 0);
startPoints = zeros(numBoxes, 2);
dimensions = zeros(numBoxes, 2);

for i = 1:numBoxes
    initialRectangle = initialRectangles(i, :);
    box = matlab.graphics.interaction.internal.rbbox.Rectangle(f, initialRectangle);
    
    startPoint = initialRectangle(1:2);
    widthAndHieght = initialRectangle(3:4);
    
    startPoints(i, :) = startPoint;
    dimensions(i, :) = widthAndHieght;
    
    boxes(end + 1) = box;
    
    box.draw();
    box.show();
end

% Add the mouse move and mouse up listeners
mouseMoveListener = event.listener(f, 'WindowMouseMotion', ...
                    @(~, eventdata) mousemove(eventdata.Point, mouseDownPoint, ...
                    startPoints, dimensions, boxes, stepSize, numBoxes, f));
                
mouseUpListener = event.listener(f, 'WindowMouseRelease', @(~,~) mouseup(boxes));

% Handle cleanup
cleanupObj = onCleanup(@()cleanupFcn(mouseMoveListener, mouseUpListener, boxes));

% Block execution until mouse up
waitfor(boxes(end), 'Visible', false);

% Get the final position of the rectangles
finalRects = arrayfun(@(box) box.getPosition(), boxes, 'UniformOutput', false);
finalRects = cell2mat(finalRects');

end

% Custom validator function
function mustHave4Columns(arg)
    classes = {'numeric'};
    attributes = {'ncols', 4};
    funcName = 'dragrect';
    
    validateattributes(arg, classes, attributes, funcName);
end

function mousemove(currentPoint, mouseDownPoint, startPoints, dimensions, boxes, stepSize, numBoxes, f)
    currentPointInPixels = hgconvertunits(f, [currentPoint 0 0], f.Units, 'pixels', f);
    currentPoint = currentPointInPixels(1:2);
    
    offset = currentPoint - mouseDownPoint;
    remainder = mod(offset, stepSize);
    offset = offset - remainder;

    newStartPoints = startPoints + offset;

    for k = 1:numBoxes
        rect = [newStartPoints(k, :) dimensions(k, :)];
        boxes(k).setInitialPosition(rect);
        boxes(k).draw();
    end
end

function mouseup(boxes)
   arrayfun(@(box) box.hide(), boxes); 
end

function cleanupFcn(mouseMoveListener, mouseUpListener, boxes)
    % Delete the mouse move and mouse up listeners
    mouseMoveListener.delete;
    mouseUpListener.delete;

    % Delete the Rectangles
    arrayfun(@(box) box.delete(), boxes);
end
