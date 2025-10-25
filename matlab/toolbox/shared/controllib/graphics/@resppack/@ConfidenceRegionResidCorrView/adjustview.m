function adjustview(this,Data,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once
%  the axes limits have been finalized (invoked in response, e.g., to a
%  'LimitChanged' event).

%  Copyright 2015 The MathWorks, Inc.
AxGrid = this.AxesGrid;
if strcmp(Event,'postlim') && ~isempty(Data.Data)
   % Input and output sizes
   [Ny, Nu] = size(this.UncertainPatch);
   Normalize = strcmp(AxGrid.YNormalization,'on');
   if strcmpi(this.UncertainType,'Bounds')
      set(this.UncertainLines,'Visible','off');
      set(this.UncertainPatch,'Visible','on');
      % Redraw the patch
      % Map data to curves
      
      % Plot data as a line
      for ct = 1:Ny*Nu
         sz = size(Data.Data(ct).Amplitude);
         M = round((sz(1)-1)/2);
         XVec = (-M:M)';
         SD = Data.Data(ct).AmplitudeSD;
         YData = [SD; -SD(end:-1:1)];
         if Normalize
            Xlims = get(ancestor(this.UncertainPatch(ct),'axes'),'Xlim');
            YData = normalize(Data.Parent,YData,Xlims,ct);
         end
         
         XData = [XVec; XVec(end:-1:1)];
         ZData = -2 * ones(size(XData));
         set(double(this.UncertainPatch(ct)), 'XData', XData, ...
            'YData',YData,'ZData',ZData);
      end
   else
      % AxGrid = this.AxesGrid;
      % todo
   end
end
