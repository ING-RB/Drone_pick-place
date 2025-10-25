function p = getoptions(this,varargin)
%GETOPTIONS  Get plot options from disk margin plot.
%
%  P = GETOPTIONS(H) returns the plot options P for a disk margin with 
%  handle H. 
%
%  P = GETOPTIONS(H,PropertyName) returns the specified options property. 
% 
%  See also DISKMARGINPLOT, DISKMARGINOPTIONS, SETOPTIONS.

%  Copyright 1986-2021 The MathWorks, Inc.

if length(varargin)>1
    error(message('Controllib:general:OneOrTwoInputsRequired','getoptions','wrfc/getoptions'))
end
    
p = plotopts.DiskMarginOptions;
p.getDiskMarginPlotOpts(this,true); 

if ~isempty(varargin)
    try
        p = p.(varargin{1});
    catch
        error(message('Controllib:plots:getoptions1','diskmarginoptions'))
    end
end