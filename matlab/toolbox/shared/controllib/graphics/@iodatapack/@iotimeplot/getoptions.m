function p = getoptions(this, varargin)
%GETOPTIONS  Get plot options from data plot
%
%  P = GETOPTIONS(H) returns the plot options P for an input-output data
%  plot with handle H. See IODATAPLOT for details on obtaining H.
%
%  P = GETOPTIONS(H,PropertyName) returns the specified options property, 
%  for the iodata plot with handle H. 
% 
%  See also IODATAPLOT, IODATAPLOTOPTIONS, SETOPTIONS.

%  Copyright 2013 The MathWorks, Inc.
if length(varargin)>1
    ctrlMsgUtils.error('Controllib:general:OneOrTwoInputsRequired','getoptions','wrfc/getoptions')
end

p = plotopts.IOTimePlotOptions;
p.getIOTimePlotOpts(this,true);

if ~isempty(varargin)
    try
        p = p.(varargin{1});
    catch
        ctrlMsgUtils.error('Controllib:plots:getoptions1','iodataPlotOptions')
    end
end
