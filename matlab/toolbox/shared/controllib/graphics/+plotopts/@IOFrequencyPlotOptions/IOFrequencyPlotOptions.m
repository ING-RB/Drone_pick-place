classdef (TruncatedProperties, CaseInsensitiveProperties) IOFrequencyPlotOptions < plotopts.BodeOptions
   %IOFrequencyPlotOptions class
   
   %  Copyright 2015-2024 The MathWorks, Inc.
   
   properties (Hidden) % deprecated in R2025a
      Orientation = 'two-row';
   end
   
   methods
      % ------------------------------------------------------------------%
      % Constructor
      % ------------------------------------------------------------------%
      function this = IOFrequencyPlotOptions(varargin)
         
         % default mag unit is 'abs' unless overridden by cstprefs
         this.MagUnits = 'abs';
         
         if ~isempty(varargin) && strcmpi(varargin{1},'cstprefs')
            mapCSTPrefs(this);
         end
         
         this.Title.String = ctrlMsgUtils.message('Controllib:plots:strIODataFreq');
         this.XLabel.String = ctrlMsgUtils.message('Controllib:plots:strFrequency');
         this.YLabel.String = {ctrlMsgUtils.message('Controllib:plots:strMagnitude'), ...
            ctrlMsgUtils.message('Controllib:plots:strPhase')};
      end
      
      % ------------------------------------------------------------------%
      % Purpose:  Error handling of setting Orientation property
      % ------------------------------------------------------------------%
      function set.Orientation(this,ProposedValue)
         
         OrientationChoices = {'two-row','two-column','single-row','single-column'};
         Or = localMatchKey(ProposedValue,OrientationChoices);
         if ~isempty(Or)
            this.Orientation = Or;
         else
            error(message('Controllib:plots:PlotOptionsProperties11'))
         end
      end
      
   end
   
end

%--------------------------------------------------------------------------
function strOut = localMatchKey(str,StrList)
strOut = '';
if ischar(str)
   idx = find(strncmpi(str,StrList,max(1,length(str))));
   nhit = length(idx);
   if nhit==1
      strOut = StrList{idx};
   elseif nhit>1
      % Look for exact match
      idxe = find(strcmpi(str,StrList(idx)));
      if isscalar(idxe)
         strOut = StrList{idx(idxe)};
      end
   end
end
end
