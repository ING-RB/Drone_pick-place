function setoptions(this,varargin)
%SETOPTIONS  set sigmaplot properties

%  Copyright 1986-2021 The MathWorks, Inc.
if ~isempty(varargin)
    if ~isa(varargin{1},'plotopts.DiskMarginOptions')
        p = plotopts.DiskMarginOptions;
        p.getDiskMarginPlotOpts(this,true);
    else
        p = varargin{1};
        varargin(1) = [];
    end
end
applyPropertyPairs(p, varargin{:});
applyDiskMarginPlotOpts(p,this,true);