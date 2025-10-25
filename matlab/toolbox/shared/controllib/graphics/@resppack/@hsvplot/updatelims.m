function updatelims(this)
%UPDATELIMS  Limit picker for HVS plots.

%  Copyright 1986-2005 The MathWorks, Inc.
Axes = this.AxesGrid;

% X limits
if strcmp(Axes.XLimMode,'auto')
   if isempty(this.Responses)
      Xlim = [0 1];
   else
      Xlim = [0 1+length(this.Responses.Data.HSV)];
   end 
   set(getaxes(Axes),'Xlim',Xlim)
end

% Y limits: delegate to @axes
Axes.updatelims('manual',[])
