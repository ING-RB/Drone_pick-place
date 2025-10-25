function setoptions(this,varargin)
%SETOPTIONS  set Nyquistplot properties

%  Copyright 1986-2021 The MathWorks, Inc.

if ~isempty(varargin)
    if ~isa(varargin{1},'plotopts.NyquistOptions')
        p = plotopts.NyquistOptions;
        p.getNyquistPlotOpts(this,true);
    else
        p = varargin{1};
        varargin(1) = [];
    end
end


applyPropertyPairs(p, varargin{:});

applyNyquistPlotOpts(p,this,true);