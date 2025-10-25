function getmargin(this, MarginType, cd, ArrayIndex, w)
%  GETMARGIN  Update all data (@chardata) of the datavie (h = @dataview)
%  using the response source (this = @respsource).

%  Author(s): John Glass
%   Copyright 1986-2021 The MathWorks, Inc.
if nargin<4
    ArrayIndex = 1;
end

% Get stability margin data
s = this.Cache(ArrayIndex).Margins;
if isempty(s)
   % Recompute margins
   D = getModelData(this,ArrayIndex);
   % NOTE: May error, e.g., for sparse models
   s = allmargin(D,ltioptions.margin,w);
   this.Cache(ArrayIndex).Margins = s;
end
    
% Update the data.
if strcmp(MarginType,'min')
   s = utGetMinMargins(s);
end
cd.GainMargin  = s.GainMargin;
cd.GMFrequency = s.GMFrequency;
cd.GMPhase = s.GMPhase;
cd.PhaseMargin = s.PhaseMargin;
cd.PMFrequency = s.PMFrequency;
cd.PMPhase = s.PMPhase;
cd.DelayMargin = s.DelayMargin;
cd.DMFrequency = s.DMFrequency;
cd.Stable = s.Stable;
% Store the sample rate in the characteristic data object so that the
% proper units will be displayed in the tip function for the
% phase margin characteristic points.
cd.Ts = this.Model.Ts;

TimeUnits = getTimeUnits(this);
if strcmpi(TimeUnits,'seconds')
    FrequencyUnits = 'rad/s';
else
    FrequencyUnits = ['rad/',TimeUnits(1:end-1)];
end
cd.FreqUnits = FrequencyUnits;
cd.TimeUnits = TimeUnits;
