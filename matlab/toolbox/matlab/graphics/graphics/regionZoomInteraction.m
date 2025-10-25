function interact = regionZoomInteraction(varargin)
%REGIONZOOMINTERACTION Create region zoom interaction object
%   RZ = REGIONZOOMINTERACTION creates a RegionZoomInteraction object which
%   enables you to zoom into a region by dragging within a chart without
%   having to select a button in the axes toolbar. To enable region
%   zooming, set the Interactions property of the axes to the object
%   returned by this function. To specify multiple interactions, set the
%   Interactions property to an array of objects. 
%
%   RZ = REGIONZOOMINTERACTION('Dimensions',d) constrains zooming to the
%   specified dimensions.
%
%   Example:
%       ax = axes;
%       rz = regionZoomInteraction;
%       ax.Interactions = rz;

%   Copyright 2018 The MathWorks, Inc.

res = matlab.graphics.interaction.internal.parseInteractionInputs(varargin{:});

interact = matlab.graphics.interaction.interactions.RegionZoomInteraction;
interact.Dimensions = res.Dimensions;
