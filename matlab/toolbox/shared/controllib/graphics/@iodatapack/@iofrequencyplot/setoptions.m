function setoptions(this,varargin)
%SETOPTIONS  set iofrequencyplot properties

%  Copyright 2014 The MathWorks, Inc.
if ~isempty(varargin)
   if ~isa(varargin{1},'plotopts.IOFrequencyPlotOptions')
      p = plotopts.IOFrequencyPlotOptions;
      p.getIOFrequencyPlotOpts(this,true);
   else
      p = varargin{1};
      varargin(1) = [];
   end
end
applyPropertyPairs(p, varargin{:});
applyIOFrequencyPlotOpts(p,this,true);
