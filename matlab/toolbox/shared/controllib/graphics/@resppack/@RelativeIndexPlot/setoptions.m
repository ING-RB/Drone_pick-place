function setoptions(this,varargin)
%SETOPTIONS  set SectorIndex properties

%  Copyright 2015 The MathWorks, Inc.

if ~isempty(varargin)
    if ~isa(varargin{1},'plotopts.SectorPlotOptions')
        p = plotopts.SectorPlotOptions;
        p.getSectorPlotOpts(this,true);
    else
        p = varargin{1};
        varargin(1) = [];
    end
end

applyPropertyPairs(p, varargin{:});

applySectorPlotOpts(p,this,true);