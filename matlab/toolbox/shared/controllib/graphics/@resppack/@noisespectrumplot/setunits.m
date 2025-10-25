function setunits(this,property,value)
% SETUNITS is a method that applies the units to the plot. The units are
% obtained from the view preferences. Since this method is plot specific,
% not all fields of the Units structure are used.

%   Authors: Kamesh Subbarao
%   Copyright 1986-2007 The MathWorks, Inc.

% Prevent negative data ignore warning when switching between abs/logscale
% to dB
[lastmsg,lastid]=lastwarn;
sw = warning('query','MATLAB:Axes:NegativeDataInLogAxis');
warning('off','MATLAB:Axes:NegativeDataInLogAxis')

switch property
   case 'FrequencyUnits'
      if strcmpi(value,'auto')
         this.setAutoFrequencyUnits;
      else
         this.AxesGrid.XUnits = value;
      end
   case 'MagnitudeUnits'
      this.AxesGrid.YUnits = {value, this.AxesGrid.YUnits{2}};
   case 'FrequencyScale'
      this.AxesGrid.XScale = {value};
   case 'MagnitudeScale'
      this.AxesGrid.YScale = {value, this.AxesGrid.YScale{2}};
end

warning(sw.state,'MATLAB:Axes:NegativeDataInLogAxis')
lastwarn(lastmsg,lastid);