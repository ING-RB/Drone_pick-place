function draw(this,Data,~)
%DRAW  Draws uncertain view.

%   Copyright 2015 The MathWorks, Inc.

% Input and output sizes
[Ny, Nu] = size(this.UncertainPatch);

if strcmpi(this.UncertainType,'Bounds')
   set(this.UncertainLines,'Visible','off');
   set(this.UncertainPatch,'Visible','on');
   % Redraw the patch
   if strcmp(this.AxesGrid.YNormalization,'on') || isempty(Data.Data)
      % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
      set(double(this.UncertainPatch),'XData',[],'YData',[],'ZData',[])
   else
      % Plot data as a line
      for ct = 1:Ny*Nu
         sz = size(Data.Data(ct).Amplitude);
         M = round((sz(1)-1)/2);
         XVec = (-M:M)';
         SD = Data.Data(ct).AmplitudeSD;
         YData = [SD; -SD(end:-1:1)];
         XData = [XVec; XVec(end:-1:1)];
         ZData = -2 * ones(size(XData));
         set(double(this.UncertainPatch(ct)), 'XData', XData, ...
            'YData',YData,'ZData',ZData);
      end
   end
else
   % todo
end
