function hDA = createDataAnnotatable(hTarget)
%createDataAnnotatable Create a DataAnnotatable for a target
%
%  createDataAnnotatable is a factory function that creates a correct
%  DataAnnotatable instance for a given target.  If no suitable
%  DataAnnotatable implementation is known then an empty matrix will be
%  returned.

%  Copyright 2014-2019 The MathWorks, Inc.

% Returns a DataAnnotatable object representing the target (if possible).

if isa(hTarget,'matlab.graphics.chart.interaction.DataAnnotatable')
    % If the target implements DataAnnotatable then just return it
    hDA = hTarget;
    % If the primitive target has DataTipTemplate property, then use the
    % existing DataTipTemplate's Parent property which stores Adaptor class.
elseif ~isempty(hTarget) && (ishghandle(hTarget,'line') || ishghandle(hTarget,'surface') || ishghandle(hTarget,'image') || ...
        ishghandle(hTarget,'patch') || isa(hTarget, 'matlab.graphics.primitive.Polygon')) && ...
        isprop(hTarget,'DataTipTemplate') && isvalid(hTarget.DataTipTemplate)
    hDA = hTarget.DataTipTemplate.Parent;
    % If the target is a known type then create the correct adaptor
elseif ishghandle(hTarget,'line')
    hDA = matlab.graphics.chart.interaction.dataannotatable.LineAdaptor(hTarget);
elseif ishghandle(hTarget,'surface')
    hDA = matlab.graphics.chart.interaction.dataannotatable.SurfaceAdaptor(hTarget);
elseif ishghandle(hTarget,'image')
    hDA = matlab.graphics.chart.interaction.dataannotatable.ImageAdaptor(hTarget);
elseif ishghandle(hTarget,'patch')
    hDA = matlab.graphics.chart.interaction.dataannotatable.PatchAdaptor(hTarget);
elseif isa(hTarget, 'matlab.graphics.primitive.Polygon')
    hDA = matlab.graphics.chart.interaction.dataannotatable.PolygonAdaptor(hTarget);
else
    % Return an empty
    hDA = [];
end
