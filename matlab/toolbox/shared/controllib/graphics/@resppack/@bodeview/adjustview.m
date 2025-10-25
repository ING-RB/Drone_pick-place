function adjustview(this,~,~,NormalRefresh)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits. 
%
%  ADJUSTVIEW(VIEW,DATA,'prelim') hides HG objects that might interfer with 
%  limit picking.
%
%  ADJUSTVIEW(VIEW,DATA,'postlimit') adjusts the HG object extent once the 
%  axes limits have been finalized (invoked in response, e.g., to a 
%  'LimitChanged' event).

%  Copyright 1986-2021 The MathWorks, Inc.
if NormalRefresh
   % 'postlim' event (BODE does not listen to PreLimitChanged)
   AxGrid = this.AxesGrid;
   if strcmp(AxGrid.XScale{1},'log') && any(this.Frequency<0)
      % Show arrows when negative frequencies are present
      XLim = getxlim(AxGrid);
      YLim = getylim(AxGrid);
      [Ny, Nu] = size(this.MagCurves);
      RAS = (0.5+this.MagCurves(1).LineWidth)/150;
      X = this.MagCurves(1).XData;
      for j=1:Nu
         for i=1:Ny
            % Magnitude
            Y = this.MagCurves(i,j).YData;
            [ia1,ia2] = resppack.getArrowLocation(X,Y,XLim{j},YLim{2*i-1});
            resppack.drawArrow(this.MagNegArrows(i,j),X(ia1),Y(ia1),RAS);
            resppack.drawArrow(this.MagPosArrows(i,j),X(ia2),Y(ia2),RAS);
            % Phase
            Y = this.PhaseCurves(i,j).YData;
            [ia1,ia2] = resppack.getArrowLocation(X,Y,XLim{j},YLim{2*i});
            resppack.drawArrow(this.PhaseNegArrows(i,j),X(ia1),Y(ia1),RAS);
            resppack.drawArrow(this.PhasePosArrows(i,j),X(ia2),Y(ia2),RAS);
         end
      end
   else
      % Hide arrows
      set(double([this.MagPosArrows(:);this.MagNegArrows(:);...
         this.PhasePosArrows(:);this.PhaseNegArrows(:)]),'XData',[],'YData',[])
   end
end