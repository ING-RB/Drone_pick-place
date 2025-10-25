function h = ghandles(this)
%GHANDLES  Returns an array of handles of graphical objects associated
%          with a spectrumview object.

%  Copyright 1986-2018 The MathWorks, Inc.
h = cat(3,this.MagCurves, this.MagNyquistLines);
if ~isempty(this.Context) && strcmp(this.Context.PlotType,'pspectrum')
   a1 = this.MinLines;
   a2 = this.MaxLines;
   a3 = this.MeanLines;
   a4 = this.MagPatches;
   A = {a1,a2,a3,a4};
   I = cellfun(@(x)idIsValidHandle(x),A);
   A = A(I);
   h2 = cat(3,A{:});
   h = cat(3,h,h2);
end
