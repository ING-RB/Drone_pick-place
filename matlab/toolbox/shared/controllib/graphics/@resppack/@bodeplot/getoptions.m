function p = getoptions(this,varargin)
%GETOPTIONS  Get plot options from a Bode plot
%
%  P = GETOPTIONS(H) returns the plot options P for a Bode plot with 
%  handle H. See BODEPLOT for details on obtaining H. 
%
%  P = GETOPTIONS(H,PropertyName) returns the specified options property, 
%  for the bode plot with handle H. 
% 
%  See also BODEPLOT, BODEOPTIONS, SETOPTIONS.

%  Copyright 1986-2021 The MathWorks, Inc.

if length(varargin)>1
    ctrlMsgUtils.error('Controllib:general:OneOrTwoInputsRequired','getoptions','wrfc/getoptions')
end
    
p = plotopts.BodeOptions;
p.getBodePlotOpts(this,true);

if ~isempty(varargin)
    try
        p = p.(varargin{1});
    catch
        ctrlMsgUtils.error('Controllib:plots:getoptions1','bodeoptions')
    end
end