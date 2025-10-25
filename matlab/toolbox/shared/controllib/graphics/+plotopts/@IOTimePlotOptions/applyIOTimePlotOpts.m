function applyIOTimePlotOpts(this,h,varargin)
%APPLYIOTIMEPLOTOPTS  Set iotimeplot properties.

%  Copyright 2013-2014 The MathWorks, Inc.
if isempty(varargin)
   allflag = false;
else
   allflag = varargin{1};
end

switch this.Orientation
   case 'two-row'
      Or = '2row';
   case 'two-column'
      Or = '2col';
   case 'single-row'
      Or = '1row';
   case 'single-column'
      Or = '1col';
end

h.AxesGrid.Orientation = Or;

h.Options.ConfidenceNumSD = this.ConfidenceRegionNumberSD;
if strcmpi(this.TimeUnits,'auto')
   try
      h.setAutoTimeUnits;
   catch E
      disp('This plot type does not support auto units.')
   end
else
   h.AxesGrid.XUnits = this.TimeUnits;
end

h.AxesGrid.YNormalization = this.Normalize;
if allflag
   % Apply IO Grouping settings
   h.IOGrouping = this.IOGrouping;
   
   % Apply IO Visibility settings
   if all(size(h.InputVisible) == size(this.InputVisible))
      h.InputVisible = this.InputVisible;
   else
      if length(this.InputVisible) == 1
         h.InputVisible(:) = this.InputVisible;
      else
         ctrlMsgUtils.warning('Controllib:plots:SetOptionsIncorrectSize','InputVisible')
      end
   end
   
   if all(size(h.OutputVisible) == size(this.OutputVisible))
      h.OutputVisible = this.OutputVisible;
   else
      if length(this.OutputVisible) == 1
         %numi = length(h.OutputVisible);
         h.OutputVisible(:) = this.OutputVisible;
      else
         ctrlMsgUtils.warning('Controllib:plots:SetOptionsIncorrectSize','OutputVisible')
      end
   end   
   applyPlotOpts(this,h);   
end
