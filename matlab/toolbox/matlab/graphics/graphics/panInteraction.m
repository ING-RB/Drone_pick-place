function interact = panInteraction(varargin)
%PANINTERACTION Create pan interaction object
%   P = PANINTERACTION creates a PanInteraction object which enables you to
%   pan within a chart without having to select a button in the axes
%   toolbar. To enable panning, set the Interactions property of the axes
%   to the object returned by this function. To specify multiple
%   interactions, set the Interactions property to an array of objects.    
%
%   P = PANINTERACTION('Dimensions',d) constrains panning to the specified
%   dimensions. 
%
%   Example:
%       ax = axes;
%       p = panInteraction;
%       ax.Interactions = p;

%   Copyright 2018 The MathWorks, Inc.

res = matlab.graphics.interaction.internal.parseInteractionInputs(varargin{:});

interact = matlab.graphics.interaction.interactions.PanInteraction;
interact.Dimensions = res.Dimensions;
