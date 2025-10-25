function p = getoptions(this,varargin)
%GETOPTIONS  Get plot options from a Pole/Zero plot
%
%  P = GETOPTIONS(H) returns the plot options P for a Pole/Zero plot with 
%  handle H. See PZPLOT and IOPZPLOT for details on obtaining H. 
%
%  P = GETOPTIONS(H,PropertyName) returns the specified options property, 
%  for the Pole/Zero plot with handle H. 
% 
%  See also IOPZPLOT, PZPLOT, PZOPTIONS, SETOPTIONS.

%  Copyright 1986-2021 The MathWorks, Inc.

if length(varargin)>1
    ctrlMsgUtils.error('Controllib:general:OneOrTwoInputsRequired','getoptions','wrfc/getoptions')
end

p = plotopts.PZOptions;
p.getPZMapOpts(this,true);

if ~isempty(varargin)
    try
        p = p.(varargin{1});
    catch
        ctrlMsgUtils.error('Controllib:plots:getoptions1','pzoptions')
    end
end