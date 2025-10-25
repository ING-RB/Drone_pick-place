function interact = rulerPanInteraction(varargin)
%RULERPANINTERACTION Create ruler pan interaction object
%   RP = RULERPANINTERACTION creates a RulerPanInteraction object which
%   enables you to pan a ruler without having to select a button in the
%   axes toolbar. To enable ruler panning, set the Interactions property of
%   the axes to the object returned by this function. To specify multiple 
%   interactions, set the Interactions property to an array of objects.  
%
%   RP = RULERPANINTERACTION('Dimensions',d) constains panning to the
%   specified rulers.
%
%   Example:
%       ax = axes;
%       rp = rulerPanInteraction;
%       ax.Interactions = rp;

%   Copyright 2018 The MathWorks, Inc.

res = matlab.graphics.interaction.internal.parseInteractionInputs(varargin{:});

interact = matlab.graphics.interaction.interactions.RulerPanInteraction;
interact.Dimensions = res.Dimensions;
