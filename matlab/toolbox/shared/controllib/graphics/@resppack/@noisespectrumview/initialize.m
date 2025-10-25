function initialize(this,Axes)
%  INITIALIZE  Initializes @noisespectrumview objects.

%  Copyright 1986-2018 The MathWorks, Inc.

% Get axes in which responses are plotted
s = size(Axes,1);  % Ny-by-1 (each "output" is a selected spectra name)
PM = ~isempty(this.Context) && strcmp(this.Context.PlotType,'pspectrum');
if PM
   % one curve for the whole ensemble (broken by NaNs)
   nh = [s 1];
   nh2 = nh;
   IsStem = this.Context.LineTypes=="stem";
else
   nh = [s s];
   nh2 = [0 0];
end

% Create mag & nyquist lines, patches
MagCurves = repmat(wrfc.createDefaultHandle,nh);
MagNyquistLines = repmat(wrfc.createDefaultHandle,nh);
MagPatches = zeros(nh2);
MinLines = repmat(wrfc.createDefaultHandle,nh2);
MaxLines = repmat(wrfc.createDefaultHandle,nh2);
MeanLines = repmat(wrfc.createDefaultHandle,nh2);

for ct = 1:prod(nh)
   ax = Axes(ct);
   if PM
      if IsStem
         MagCurves(ct) = stem(NaN, NaN, 'Parent', ax, 'Visible', 'off',...
            'Marker','.');
      else
         MagCurves(ct) = handle(line('XData', NaN, 'YData', NaN, ...
            'Parent', ax, 'Visible', 'off'));
      end
   else
      MagCurves(ct) = handle(line('XData', NaN, 'YData', NaN, ...
         'Parent', ax, 'Visible', 'off'));
   end
   MagNyquistLines(ct) = handle(line('XData', NaN, 'YData', NaN, ...
      'Parent', ax, 'Visible', 'off' , ...
      'XlimInclude','off', 'YlimInclude','off',...
      'HandleVisibility', 'off', 'HitTest', 'off', 'Color', [0 0 0]));
end

this.MagCurves = MagCurves;
this.MagNyquistLines = MagNyquistLines;

% ensemble patches + mean+min/max lines. 
if PM
   for ct = 1:prod(nh2)
      ax = Axes(ct);
      MagPatches(ct) = patch([NaN,NaN],[NaN,NaN],[-10,-10],...
         'Parent',ax,...
         'Visible','off',...
         'Selected','off',...
         'XlimInclude','off', 'YlimInclude','on',...
         'HandleVisibility','off','HitTest','off');
      
      if IsStem
         MinLines(ct) = stem(NaN, NaN, 'Parent', ax, 'Visible', 'off','Marker','.',...
            'Linestyle','none');
         MaxLines(ct) = line(NaN, NaN, 'Parent', ax, 'Visible', 'off','Marker','.',...
            'Linestyle','none');
         MeanLines(ct) = stem(NaN, NaN, 'Parent', ax, 'Visible', 'off','Marker','.');
      else
         MinLines(ct) = handle(line('XData', NaN, 'YData', NaN, ...
            'Parent', ax, 'Visible', 'off'));
         MaxLines(ct) = handle(line('XData', NaN, 'YData', NaN, ...
            'Parent', ax, 'Visible', 'off'));
         MeanLines(ct) = handle(line('XData', NaN, 'YData', NaN, ...
            'Parent', ax, 'Visible', 'off'));
      end
   end
   
   this.MagPatches = MagPatches;
   this.MinLines = MinLines;
   this.MaxLines = MaxLines;
   this.MeanLines = MeanLines;
end
