function mapCSTPrefs(this,varargin)
%MAPCSTPREFS for ResidCorrPlotOptions.

%  Copyright 2015 The MathWorks, Inc.

if isempty(varargin)
    CSTPrefs = cstprefs.tbxprefs;
else
    CSTPrefs = varargin{1};
end


mapCSTPrefs@plotopts.RespPlotOptions(this,CSTPrefs);
