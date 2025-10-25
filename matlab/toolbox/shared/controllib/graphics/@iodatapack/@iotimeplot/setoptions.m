function setoptions(this,varargin)
%SETOPTIONS  set iotimeplot properties

%  Copyright 2013 The MathWorks, Inc.
if ~isempty(varargin)
    if ~isa(varargin{1},'plotopts.IOTimePlotOptions')
        p = plotopts.IOTimePlotOptions;
        p.getIOTimePlotOpts(this,true);
    else
        p = varargin{1};
        varargin(1) = [];
    end
end

applyPropertyPairs(p, varargin{:});

applyIOTimePlotOpts(p,this,true);