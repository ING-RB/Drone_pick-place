function updategrid(this,varargin)
%UPDATEGRID  Redraws custom grid.

%   Author: P. Gahinet
%   Copyright 1986-2014 The MathWorks, Inc.

% RE: Callback for LimitChanged event
if ~isempty(this.GridFcn) && strcmp(this.Grid,'on')
    
    % Clear existing grid
    cleargrid(this)

    % Evaluate GridFcn to redraw custom grid
    GridHandles = feval(this.GridFcn{:});
    set(GridHandles,'PickableParts','none');  %Grid should not take part in hittest
    this.GridLines = handle(GridHandles(:));
end