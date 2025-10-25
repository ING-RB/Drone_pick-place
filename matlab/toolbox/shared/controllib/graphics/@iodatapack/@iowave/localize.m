function localize(this)
%LOCALIZE  Determines waveform location inside axes grid.
%
%  LOCALIZE compares the axes grid's row and column names with the
%  data source's row and column names to determine the waveform
%  location.

%  Copyright 2013-2015 The MathWorks, Inc.

% Default location is upper left corner
InputIndex = 1:length(this.InputIndex);
OutputIndex = 1:length(this.OutputIndex);

% Use data source info for named-based localization
if ~isempty(this.DataSrc)
   Plot = this.Parent;
   PlotInputName = Plot.InputName;
   PlotOutputName = Plot.OutputName;
   try
      [SrcOutputName,SrcInputName] = getIONames(this.DataSrc);
      InputIndex = LocalMatchName(SrcInputName,PlotInputName);
      OutputIndex = LocalMatchName(SrcOutputName,PlotOutputName);
   end
   this.RowIndex = [OutputIndex, numel(PlotOutputName)+InputIndex];
   this.ColumnIndex = 1:(~this.DataSrc.IsReal + 1);
end

% Assign new value (turn off listener for efficiency and to prevent
% errors during plot resize)
set(this.Listeners,'Enable','off')
this.InputIndex = InputIndex;
this.OutputIndex = OutputIndex;

set(this.Listeners,'Enable','on')

% Update graphics
reparent(this)

% ------------------------------------------------------------------------%
% Purpose: Localize a given set of I/O names among plot I/O labels
% ------------------------------------------------------------------------%
function Index = LocalMatchName(Names,RefNames)

if iscell(Names) && any(cellfun('isempty',Names))
   % Not all names defined
   Index = [];
else
   [~,ia,ib] = intersect(RefNames,Names);
   [~,is] = sort(ib);
   Index = ia(is).';
end
% Use default location if not all names were matched
% REVISIT: assumes unique names!
if length(Index)<length(Names)
   Index = 1:length(Names);
end
