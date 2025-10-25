function draw(this,Data,~)
%DRAW  Draws uncertain view

%   Author(s): Rajiv Singh
%   Copyright 1986-2011 The MathWorks, Inc.

% Time:      Ns x 1
% Amplitude: Ns x Ny x Nu

% Input and output sizes
[Ny, ~] = size(this.UncertainMagPatch);

if strcmpi(this.UncertainType,'Bounds')
   % Redraw the patch
   set(this.UncertainMagLines,'Visible','off');
   set(this.UncertainMagPatch,'Visible','on');
   if isempty(Data.Data)
      % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
      set(double(this.UncertainMagPatch),'XData',[],'YData',[],'ZData',[])
   else
      % Map data to curves
      for ct = 1:Ny*Ny
         XData = [Data.Data(ct).Frequency;Data.Data(ct).Frequency(end:-1:1)]*funitconv('rad/TimeUnit',this.Parent.AxesGrid.xUnits,Data.TimeUnits);
         ZData = -2 * ones(size(XData));
         TempData = Data.Data(ct).Magnitude(:)-Data.Data(ct).MagnitudeSD(:);
         MagData = [ Data.Data(ct).Magnitude(:)+Data.Data(ct).MagnitudeSD(:);TempData(end:-1:1)];
         set(double(this.UncertainMagPatch(ct)), 'XData', XData, ...
            'YData',idpack.specmagunitconv(MagData,'abs',this.Parent.AxesGrid.YUnits),'ZData',ZData);
      end
   end
   
else
   set(this.UncertainMagLines,'Visible','on');
   set(this.UncertainMagPatch,'Visible','off');
   if isempty(Data.Data)
      % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
      set(double(this.UncertainMagLines),'XData',[],'YData',[],'ZData',[])
   else
      % Map data to curves
      for ct = 1:Ny*Ny
         % Plot data as a line
         MagData = [Data.Data(ct).Magnitude(:)-Data.Data(ct).MagnitudeSD(:);NaN;Data.Data(ct).Magnitude(:)+Data.Data(ct).MagnitudeSD(:)];
         XData = [Data.Data(ct).Frequency;NaN;Data.Data(ct).Frequency];
         
         XData = XData*funitconv('rad/TimeUnit',this.Parent.AxesGrid.xUnits,Data.TimeUnits);
         set(double(this.UncertainMagLines(ct)),'XData',XData,'YData',idpack.specmagunitconv(MagData,'abs',this.Parent.AxesGrid.YUnits{1}),'ZData',-2 * ones(size(XData)))
      end
   end
end
