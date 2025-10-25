function draw(this, vertexData)
% This internal helper function may change in a future release.

% DRAW draws a region of interest (ROI) based on a brushing drag gesture.
%
% DRAW creates the Brushing ROI rectangle which is common for 2d and 3d
% figures and updates the graphics

%  Copyright 2019 The MathWorks, Inc.

if isempty(this.Graphics)
    if isvalid(this.ScribeLayer)
        
        % Create the brushing ROI rectangle (common for 2d and 3d figures)
        this.Graphics = matlab.graphics.primitive.world.LineStrip('parent',this.ScribeLayer);
        set(this.Graphics,'ColorData',uint8([255;0;0;255]),...
            'ColorBinding','object',...
            'HandleVisibility','off',...
            'Hittest','off',...
            'PickableParts','none',...
            'LineWidth',0.5,'VertexData',single(vertexData),'StripData',uint32([1 size(vertexData,2)+1]));
    end
else
    % Update the existing graphics
    set(this.Graphics,'VertexData',single(vertexData),'StripData',uint32([1 size(vertexData,2)+1]),'Visible','on');
end

end

