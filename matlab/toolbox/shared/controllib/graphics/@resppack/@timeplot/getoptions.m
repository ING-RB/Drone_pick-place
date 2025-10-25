function p = getoptions(this,varargin)
%GETOPTIONS  Get plot options from a time plot
%
%  P = GETOPTIONS(H) returns the plot options P for a time plot with 
%  handle H. See LSIMPLOT, STEPPLOT, INITIALPLOT, IMPULSEPLOT for details 
%  on obtaining H. 
%
%  P = GETOPTIONS(H,PropertyName) returns the specified options property, 
%  for the time plot with handle H. 
% 
%  See also LSIMPLOT, STEPPLOT, INITIALPLOT, IMPULSEPLOT, TIMEOPTIONS, 
%  SETOPTIONS.

%  Copyright 1986-2021 The MathWorks, Inc.

if length(varargin)>1
    ctrlMsgUtils.error('Controllib:general:OneOrTwoInputsRequired','getoptions','wrfc/getoptions')
end

p = plotopts.TimeOptions;
p.getTimePlotOpts(this,true);

if ~isempty(varargin)
    try
        p = p.(varargin{1});
    catch
        ctrlMsgUtils.error('Controllib:plots:getoptions1','timeoptions')
    end
end