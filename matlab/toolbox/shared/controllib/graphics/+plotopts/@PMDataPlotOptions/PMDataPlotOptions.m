classdef (TruncatedProperties, CaseInsensitiveProperties) PMDataPlotOptions < plotopts.IOTimePlotOptions
   % PMDataPlotOptions class
   
   %  Copyright 2017 The MathWorks, Inc.
   
   properties
      MaxSamples = 1000;
      MaxMembers = 50;
   end
   
   methods
      % ------------------------------------------------------------------------%
      % Constructor
      % ------------------------------------------------------------------------%
      
      function this = PMDataPlotOptions(varargin)
         this = this@plotopts.IOTimePlotOptions(varargin{:});
      end
   end
   
   methods (Access = protected)
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting XLim and YLim property
      % ------------------------------------------------------------------------%
      function Lim = validateLim(this, Prop, ProposedValue)
         if isnumeric(ProposedValue)
            ProposedValue = {ProposedValue};
         end
         
         if iscell(ProposedValue) && all(cellfun(@(x) size(x,2),ProposedValue)==2)
            for ct = 1:length(ProposedValue)
               if ProposedValue{ct}(2) <= ProposedValue{ct}(1)
                  ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties04',Prop)
               end
            end
            Lim = ProposedValue;
         else
            ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties04',Prop)
         end
      end
   end
end
