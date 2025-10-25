function setoptions(this,varargin)
%SETOPTIONS  set sigmaplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

if ~isempty(varargin)
    if ~isa(varargin{1},'plotopts.SigmaOptions')
        p = plotopts.SigmaOptions;
        p.getSigmaPlotOpts(this,true);
    else
        p = varargin{1};
        varargin(1) = [];
    end
end

applyPropertyPairs(p, varargin{:});

applySigmaPlotOpts(p,this,true);