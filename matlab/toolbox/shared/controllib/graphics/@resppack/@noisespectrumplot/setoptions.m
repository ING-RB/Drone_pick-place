function setoptions(this,varargin)
%SETOPTIONS  set noisespectrumplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

if ~isempty(varargin)
   if ~isa(varargin{1},'plotopts.SpectrumOptions')
      p = plotopts.SpectrumOptions;
      p.getSpectrumPlotOpts(this,true);
   else
      p = varargin{1};
      varargin(1) = [];
   end
end
applyPropertyPairs(p, varargin{:});
applySpectrumPlotOpts(p,this,true);
