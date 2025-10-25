function p = getoptions(this,varargin)
%GETOPTIONS  Get plot options from a sector index plot
%
%  P = GETOPTIONS(H) returns the plot options P for a sector index plot
%  with handle H. See sectorplot for details on obtaining H. 
%
%  P = GETOPTIONS(H,PropertyName) returns the specified options property, 
%  for the sector index plot with handle H. 
% 
%  See also SectorIndexPlot, SectorIndexPlotOptions, setoptions.

%  Copyright 2015 The MathWorks, Inc.

if length(varargin)>1
    ctrlMsgUtils.error('Controllib:general:OneOrTwoInputsRequired','getoptions','wrfc/getoptions')
end

p = plotopts.SectorPlotOptions;
p.getSectorPlotOpts(this,true);

if ~isempty(varargin)
    try
        p = p.(varargin{1});
    catch
        ctrlMsgUtils.error('Controllib:plots:getoptions1','SectorPlotOptions')
    end
end