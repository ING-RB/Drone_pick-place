function applystyle(this,varargin)
%APPLYSTYLE  Applies style settings to @waveform instance.

%  Author(s): John Glass
%  Copyright 1986-2012 The MathWorks, Inc.
rdim = this.RowIndex; 
cdim = this.ColumnIndex; 
style = this.Style;

% Apply to each view
View = this.View;
for ct=1:length(View)
    View(ct).applystyle(style,rdim,cdim,ct);
end

% Apply to wave characteristics
for c=this.Characteristics'
    cView = c.View;
   for ct = 1:length(cView)
      cView(ct).applystyle(style,rdim,cdim,ct);
   end
end

% Update legend info
this.updateGroupInfo;
