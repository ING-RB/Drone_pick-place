function getSpectrumPlotOpts(this,h,varargin)
%GETSPECTRUMPLOTOPTS Gets plot options of @spectrumplot h.

%  Author(s): C. Buhr
%  Copyright 1986-2021 The MathWorks, Inc.

if isempty(varargin) 
   allflag = false;
else
    allflag = varargin{1};
end

this.FreqUnits = h.AxesGrid.XUnits;
this.FreqScale = h.AxesGrid.XScale{1};
this.MagUnits = h.AxesGrid.YUnits;
this.MagScale = h.AxesGrid.YScale;

if strcmp(h.Options.MinGainLimit.Enable,'on')
    this.MagLowerLimMode = 'manual';
else
    this.MagLowerLimMode = 'auto';
end
this.MagLowerLim = h.Options.MinGainLimit.MinGain;


if allflag
    getRespPlotOpts(this,h,allflag);
end



