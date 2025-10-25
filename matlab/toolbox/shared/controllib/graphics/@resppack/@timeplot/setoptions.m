function setoptions(this,varargin)
%SETOPTIONS  set timeplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

if ~isempty(varargin)
    if ~isa(varargin{1},'plotopts.TimeOptions')
        p = plotopts.TimeOptions;
        p.getTimePlotOpts(this,true);
    else
        p = varargin{1};
        varargin(1) = [];
    end
end

applyPropertyPairs(p, varargin{:});

applyTimePlotOpts(p,this,true);