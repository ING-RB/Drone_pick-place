function adjustview(this,Data,Event,~)
%ADJUSTVIEW  Adjusts view prior to and after picking the axes limits.
%
%  ADJUSTVIEW(cVIEW,cDATA,'postlim') adjusts the HG object extent once
%  the axes limits have been finalized (invoked in response, e.g., to a
%  'LimitChanged' event).

%  Author(s): C. Buhr
%  Copyright 1986-2014 The MathWorks, Inc.

%  Frequency:   Nf x 1
%  Singular Values: Nf x Ns
if strcmp(Event,'prelim')
   % To show desired extent to limit picker
   this.draw(Data);
else
   AxGrid = this.AxesGrid;
   YUnits = AxGrid.YUnits;
   if ~strcmp(YUnits,'dB')
      % To accomodate deg/dB in TuningGoal.Margins view
      YUnits = 'abs';
   end
   
   % Adjust number of SV curves
   Ns = size(Data.SingularValues,2);
   Nline = length(this.Curves);
   if Ns>Nline
      % Add missing lines
      Curves = this.Curves;
      for ct=Ns:-1:Nline+1
         ax = Curves(1).Parent;
         Curves(ct,1) = controllibutils.utCustomCopyLineObj(Curves(1),ax);
      end
      this.Curves = Curves;
   end
   
   Freq = Data.Frequency*funitconv(Data.FreqUnits,AxGrid.XUnits);
   SV = unitconv(Data.SingularValues,Data.MagUnits,YUnits);
   
   % Eliminate zero frequencies in log scale
   if strcmp(AxGrid.XScale,'log')
      idxf = find(Freq>0);
      Freq = Freq(idxf);
      SV = SV(idxf,:);
   end
   
   % Map data to curves
   for ct=1:Ns
      % Create lower or upper limit value for showing patch to edge of axis
      YLims = get(ancestor(this.Curves(ct),'axes'),'Ylim');
      if strcmpi(this.BoundType,'upper')
         BoundLimit = YLims(2);
      else
         BoundLimit = YLims(1);
      end
      % REVISIT: remove conversion to double (UDD bug where XOR mode ignored)
      XData = [Freq;Freq(end:-1:1)];
      ZData = this.ZLevel * ones(size(XData));
      YData = [SV(:,ct);BoundLimit*ones(size(SV(:,ct)))];
      set(double(this.Curves(ct)), 'XData', XData, 'YData', YData,'ZData',ZData);
   end
   set(this.Curves(Ns+1:end),'XData',[],'YData',[],'ZData',[])
end