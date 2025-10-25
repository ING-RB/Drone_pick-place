function setoptions(this,varargin)
%SETOPTIONS  set bodeplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

if ~isempty(varargin)
    if ~isa(varargin{1},'plotopts.BodeOptions')
        p = plotopts.BodeOptions;
        p.getBodePlotOpts(this,true);
    else
        p = varargin{1};
        varargin(1) = [];
    end
end

applyPropertyPairs(p, varargin{:});

applyBodePlotOpts(p,this,true);