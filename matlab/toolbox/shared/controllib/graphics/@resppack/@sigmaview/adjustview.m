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
   % 'postlim' event (SIGMA does not listen to PreLimitChanged)
   AxGrid = this.AxesGrid;
   if strcmp(AxGrid.XScale{1},'log') && any(this.Frequency<0)
      % Show arrows when negative frequencies are present
      XLim = getxlim(AxGrid);
      YLim = getylim(AxGrid);
      Curves = this.Curves;
      RAS = (0.5+Curves(1).LineWidth)/150;
      X = Curves(1).XData;
      for j=1:numel(Curves)
         Y = Curves(j).YData;
         [ia1,ia2] = resppack.getArrowLocation(X,Y,XLim{1},YLim{1});
         resppack.drawArrow(this.NegArrows(j),X(ia1),Y(ia1),RAS);
         resppack.drawArrow(this.PosArrows(j),X(ia2),Y(ia2),RAS);
      end
   else
      % Hide arrows
      set(double([this.PosArrows(:);this.NegArrows(:)]),'XData',[],'YData',[])
   end
end