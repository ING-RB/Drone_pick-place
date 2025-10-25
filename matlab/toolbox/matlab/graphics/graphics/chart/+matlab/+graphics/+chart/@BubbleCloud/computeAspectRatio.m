function ar=computeAspectRatio(obj)
%

%   Copyright 2020 The MathWorks, Inc.

% Gets the current aspect ratio (of the chart). This uses the
% OuterPosition of the chart as a target ratio. OuterPosition is used so 
% that adding/removing a title does not cause a change in layout.

if isequal(obj.Units,'pixels')
    chartpos=obj.getLayout.OuterPosition;
else
    cc=ancestor(obj,'matlab.ui.internal.mixin.CanvasHostMixin');
    fig=ancestor(obj,'matlab.ui.Figure');
    chartpos=hgconvertunits(fig,obj.getLayout.OuterPosition, obj.Units, 'pixels', cc);
end
ar=chartpos(3)/chartpos(4);
end
