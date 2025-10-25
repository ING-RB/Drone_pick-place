function interact = dataTipInteraction(varargin)
%DATATIPINTERACTION Create data tip interaction object
%   D = DATATIPINTERACTION creates a DataTipInteraction object which enables
%   you to display data tips within a chart without having to select a
%   button in the axes toolbar. To enable data tips, set the Interactions
%   property of the axes to the  object returned by this function. 
%   To specify multiple interactions, set the Interactions property to an 
%   array of objects. 
%
%   D = DATATIPINTERACTION('SnapToDataVertex',d) specifies whether data cursors 
%   snap to nearest data value or appear at mouse position.
%
%   Example:
%       ax = axes;
%       d = dataTipInteraction;
%       ax.Interactions = d;

%   Copyright 2018-2019 The MathWorks, Inc.

% Parse the inputs
p = inputParser;
p.StructExpand = false;
p.addParameter('SnapToDataVertex',"on");
p.parse(varargin{:});
res = p.Results;

interact = matlab.graphics.interaction.interactions.DataTipInteraction;
interact.SnapToDataVertex = res.SnapToDataVertex;