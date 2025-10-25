function applyHSVPlotOpts(this,h,varargin)
%APPLYHSVPLOTOPTS  set hsvplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

% Set YScale (avoid triggering listeners)
if ~strcmp(h.AxesGrid.YScale,this.YScale)
   h.AxesGrid.YScale = this.YScale;
end
  
% Call parent class apply options
if nargin>2 && varargin{1}
   applyPlotOpts(this,h);
end

% Notify of possible limit change (e.g., to update height of red bars)
h.AxesGrid.send('PostLimitChanged')
