function setoptions(this,varargin)
%SETOPTIONS  set pzplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

if ~isempty(varargin)
    if ~isa(varargin{1},'plotopts.PZOptions')
        p = plotopts.PZOptions;
        p.getPZMapOpts(this,true);
    else
        p = varargin{1};
        varargin(1) = [];
    end
end

applyPropertyPairs(p, varargin{:});

applyPZMapOpts(p,this,true);