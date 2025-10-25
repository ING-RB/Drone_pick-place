function w = addwave(this, varargin)
%ADDWAVE  Adds a new wave to a wave plot.
%
%   W = ADDWAVE(WAVEPLOT,INPUTINDEX,OUTPUTINDEX,NWAVES) adds a new wave W
%   to the wave plot WAVEPLOT.  The index vector CHANNELINDEX
%   specify the wave position in the axes grid, and NWAVES is
%   the number of waves in W (default = 1).
%
%   W = ADDWAVE(WAVEPLOT,DATASRC) adds a wave W that is linked to the
%   data source DATASRC.

%  Copyright 2013 The MathWorks, Inc.

if ~isempty(varargin) && isnumeric(varargin{1})
   % Size check
   if max(varargin{1})>this.IOSize(2) ||...
         max(varargin{2})>this.IOSize(1)
      error('Not enough axes to show requested number of inputs/outputs.')
   end
end

% Add new wave
try
   w = addwf(this,varargin{:});
catch ME
   throw(ME)
end

% Resolve unspecified name against all existing "untitledxxx" names
setDefaultName(w,this.Waves)

% Add to list of waves
this.Waves = [this.Waves ; w];
