function setposition(this,varargin)
%SETPOSITION   Sets axes group position.

%   Author(s): P. Gahinet
%   Copyright 1986-2009 The MathWorks, Inc. 

% Grid position: delegate to @plotarray object
% Scaled Resize (for printing)

% Only adjust label positions during print resize
if strcmp(this.PrintLayoutManager,'off')
    this.Axes.setposition(this.Position);
    % Background axes
    set(this.BackgroundAxes,'Position',this.Position)
    % Adjust label position
end
labelpos(this);
messagepanepos(this)