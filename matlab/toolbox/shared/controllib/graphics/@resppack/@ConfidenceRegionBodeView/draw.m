function draw(this,Data,NormalRefresh)
%DRAW  Draws uncertain view

%   Copyright 1986-2016 The MathWorks, Inc.

%OutputPlot = isprop(this.Parent,'IsIddata') && this.Parent.IsIddata;
% Input and output sizes
[Ny, Nu] = size(this.UncertainMagPatch);
%if OutputPlot, Nu = 1; end

if strcmpi(this.UncertainType,'Bounds')
   % Redraw the patch
   set(this.UncertainMagLines,'Visible','off');
   set(this.UncertainPhaseLines,'Visible','off');
   set(this.UncertainMagPatch,'Visible','on');
   set(this.UncertainPhasePatch,'Visible','on');
   if isempty(Data.Data)
      % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
      set(double(this.UncertainMagPatch),'XData',[],'YData',[],'ZData',[])
      set(double(this.UncertainPhasePatch),'XData',[],'YData',[],'ZData',[])
   else
      % Map data to curves
      for ct = 1:Ny*Nu
         if ~isempty(Data.Data(ct).MagnitudeSD)
            XData = [Data.Data(ct).Frequency;Data.Data(ct).Frequency(end:-1:1)]*funitconv('rad/TimeUnit',this.Parent.AxesGrid.xUnits,Data.TimeUnits);
            ZData = -2 * ones(size(XData));
            TempData = Data.Data(ct).Magnitude(:)-Data.Data(ct).MagnitudeSD(:);
            MagData = [ Data.Data(ct).Magnitude(:)+Data.Data(ct).MagnitudeSD(:);TempData(end:-1:1)];
            set(double(this.UncertainMagPatch(ct)), 'XData', XData, ...
               'YData',unitconv(MagData,'abs',this.Parent.AxesGrid.YUnits{1}),'ZData',ZData);
            
            TempData = Data.Data(ct).Phase(:)-Data.Data(ct).PhaseSD(:);
            PhaseData = [Data.Data(ct).Phase(:)+Data.Data(ct).PhaseSD(:);TempData(end:-1:1)];
            set(double(this.UncertainPhasePatch(ct)), 'XData', XData, ...
               'YData',unitconv(PhaseData,'rad',this.Parent.AxesGrid.YUnits{2}),'ZData',ZData);
         else
            set(double(this.UncertainPhasePatch(ct)), 'XData',[],'YData',[],'ZData',[])
         end
      end
   end   
else
   set(this.UncertainMagLines,'Visible','on');
   set(this.UncertainPhaseLines,'Visible','on');
   set(this.UncertainMagPatch,'Visible','off');
   set(this.UncertainPhasePatch,'Visible','off');
   if isempty(Data.Data)
      % RE: Defer to ADJUSTVIEW:postlim for normalized case (requires finalized X limits)
      set(double(this.UncertainMagLines),'XData',[],'YData',[],'ZData',[])
      set(double(this.UncertainPhaseLines),'XData',[],'YData',[],'ZData',[])
   else
      % Map data to curves
      for ct = 1:Ny*Nu
         % Plot data as a line
         PhaseData = [Data.Data(ct).Phase(:)-Data.Data(ct).PhaseSD(:);NaN;Data.Data(ct).Phase(:)+Data.Data(ct).PhaseSD(:)];
         MagData = [Data.Data(ct).Magnitude(:)-Data.Data(ct).MagnitudeSD(:);NaN;Data.Data(ct).Magnitude(:)+Data.Data(ct).MagnitudeSD(:)];
         XData = [Data.Data(ct).Frequency;NaN;Data.Data(ct).Frequency];
         
         XData = XData*funitconv('rad/TimeUnit',this.Parent.AxesGrid.xUnits,Data.TimeUnits);
         set(double(this.UncertainMagLines(ct)),'XData',XData,'YData',unitconv(MagData,'abs',this.Parent.AxesGrid.YUnits{1}),'ZData',-2 * ones(size(XData)))
         set(double(this.UncertainPhaseLines(ct)),'XData',XData,'YData',unitconv(PhaseData,'rad',this.Parent.AxesGrid.YUnits{2}),'ZData',-2 * ones(size(XData)))
      end
   end
end
