function setoptions(this,varargin)
%SETOPTIONS  set hsvplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

if ~isempty(varargin)
    if ~isa(varargin{1},'plotopts.HSVOptions')
        p = plotopts.HSVOptions;
        p.getHSVPlotOpts(this,true);
    else
        p = varargin{1};
        varargin(1) = [];
    end
end

applyPropertyPairs(p, varargin{:});

applyHSVPlotOpts(p,this,true);