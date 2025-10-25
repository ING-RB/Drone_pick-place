function getHSVPlotOpts(this,h,varargin)
%GETHSVPLOTOPTS  get hsvplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

% Get YScale
this.YScale = h.AxesGrid.YScale;

% Get Parent Properties
if nargin>2 && varargin{1}
   getPlotOpts(this,h);
end