function setoptions(this,varargin)
%SETOPTIONS  set nicholsplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

if ~isempty(varargin)
    if ~isa(varargin{1},'plotopts.NicholsOptions')
        p = plotopts.NicholsOptions;
        p.getNicholsPlotOpts(this,true);
    else
        p = varargin{1};
        varargin(1) = [];
    end
end

applyPropertyPairs(p, varargin{:});

applyNicholsPlotOpts(p,this,true);