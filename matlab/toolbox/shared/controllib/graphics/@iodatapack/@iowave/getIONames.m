function [uNames,yNames] = getIONames(this)
%GETRCNAME  Accesses waveform's input and output names (relative to axes grid).

%  Copyright 2013 The MathWorks, Inc.

% Get IO labels of @iotimeplot (returns {} when names not relevant)
[PlotuLabels,PlotyLabels] = getIONames(this.Parent);

% Get IO labels from data source
if ~isempty(this.DataSrc)
   [SrcuLabels,SrcyLabels] = getIONames(this.DataSrc);
else
   SrcuLabels = {};
   SrcyLabels = {};
end

% Reconcile names
uNames = LocalGetName(PlotuLabels,SrcuLabels,this.InputIndex);
yNames = LocalGetName(PlotyLabels,SrcyLabels,this.OutputIndex);

%--------------------- Local Functions -----------------------

function Names = LocalGetName(Names,SrcNames,Index)
% Determine i/o names as function of data source and plot
if ~isempty(Names)
   % i/o names are meaningful
   Names = Names(Index);
   % Finalize names
   if ~isempty(SrcNames) && isa(SrcNames,'cell')
      % Use source names when available
      idx = find(cellfun('length',SrcNames)>0);
      Names(idx) = SrcNames(idx);
   end
end
