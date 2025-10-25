function uiFigure = createUIFigure(varargin)
% CREATEUIFIGURE
%
% Create design-time UIFigure for App Designer which is invsible
%
% Make this function as a central place to create design-time UIFigure to
% avoid modifying many places when GBT has a new design for design-time
% Figure
%
% propertyValues: pv pairs of initial properties that should be set on
% figure
%

% Copyright 2020-2021 The MathWorks, Inc.

pvPairs = [{'Visible', 'off', 'CreateFcn', []}, varargin{:}];
uiFigure = uifigure(pvPairs{:});
end


