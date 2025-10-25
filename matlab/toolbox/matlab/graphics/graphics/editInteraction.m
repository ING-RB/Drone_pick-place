function interaction = editInteraction(varargin)
%EDITINTERACTION Create an edit interaction object
%   E = EDITINTERACTION creates an EditInteraction object which enables you
%   to edit text by clicking or tapping a text object. To enable
%   interactive editing, set the Interactions property of the text to the
%   object returned by this function.
%
%   Example:
%       t = text(.3, .4, 'A simple plot');
%       e = editInteraction;
%       t.Interactions = e;

%   Copyright 2020 The MathWorks, Inc.

interaction = matlab.graphics.interaction.interactions.EditInteraction;

end

