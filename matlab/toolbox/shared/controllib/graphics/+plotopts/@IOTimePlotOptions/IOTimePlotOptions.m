classdef (TruncatedProperties, CaseInsensitiveProperties) IOTimePlotOptions < plotopts.RespPlotOptions
   %IOTimePlotOptions class
   
   %  Copyright 2013-2023 The MathWorks, Inc.
   
   properties
      Orientation = 'two-row';
      TimeUnits = 'seconds';
      Normalize = 'off';
      ConfidenceRegionNumberSD = 1;
      InputInterSample char {mustBeMember(InputInterSample,{'auto','zoh','foh','bl'})} = 'auto';
   end
   
   methods
      % ------------------------------------------------------------------------%
      % Constructor
      % ------------------------------------------------------------------------%
      
      function this = IOTimePlotOptions(varargin)
         
         if ~isempty(varargin) && strcmpi(varargin{1},'cstprefs')
            mapCSTPrefs(this);
         end
         
         this.Title.String = getString(message('Controllib:plots:strIOData'));
         this.XLabel.String = ctrlMsgUtils.message('Controllib:plots:strTime');
         this.YLabel.String = ctrlMsgUtils.message('Controllib:plots:strAmplitude');
         this.Version = localver();
      end
      
      
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting TimeUnits property
      % ------------------------------------------------------------------------%
      function set.TimeUnits(this, ProposedValue)
         % React to time unit assignment.         
         this.TimeUnits = checkTimeUnits(this, ProposedValue);
      end
      
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting Orientation property
      % ------------------------------------------------------------------------%
      function set.Orientation(this,ProposedValue)
         
         OrientationChoices = {'two-row','two-column','single-row','single-column'};
         Or = this.matchKey(ProposedValue,OrientationChoices);
         
         if ~isempty(Or)
            this.Orientation = Or;
         else
            ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties11')
         end
      end
      
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting Normalize property
      % ------------------------------------------------------------------------%
      function set.Normalize(this,ProposedValue)
         
         if strcmpi(ProposedValue,'on') || strcmpi(ProposedValue,'off')
            this.Normalize = lower(ProposedValue);
         else
            ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties03','Normalize')
         end
      end
      
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting ConfidenceRegionNumberSD property
      % ------------------------------------------------------------------------%
      function set.ConfidenceRegionNumberSD(this, ProposedValue)
         if isnumeric(ProposedValue) && isscalar(ProposedValue) &&...
               isreal(ProposedValue) && isfinite(ProposedValue) && (ProposedValue>=0)
            % store the value in absolute units
            this.ConfidenceRegionNumberSD = ProposedValue;
         else
            ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties07',...
               'ConfidenceRegionNumberSD')
         end
      end      
      
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting InputInterSample property
      % ------------------------------------------------------------------------%
      function set.InputInterSample(this,ProposedValue)
         % Default implementation of the "InputInterSample" property SET method.
         
         % if numel(ProposedValue)>1 || ~any(strcmp(ProposedValue,{'zoh','foh','bl','auto'}))
         %    error(message('Ident:utility:InputInterSampleValue1'))
         % end
         if ~isrow(ProposedValue)
            error(message('Ident:utility:InputInterSampleValue1'))
         end
         this.InputInterSample = ProposedValue;
      end

      function TU = checkTimeUnits(this, ProposedValue)
         % React to time unit assignment
         
         ValidValues = ['auto'; ltipack.getValidTimeUnits()];
         TU = this.matchKey(ProposedValue, ValidValues);
         
         if isempty(TU)
            error(message('Controllib:plots:TimeUnitsProperty','TimeUnits'))
         end
      end
      
   end
   
   methods(Static)
      function opt = loadobj(s)
         opt = s;
         opt.Version = localver();
      end
      
      function strOut = matchKey(str,StrList)
         strOut = '';
         if ischar(str)
            idx = find(strncmpi(str,StrList,max(1,length(str))));
            nhit = length(idx);
            if nhit==1
               strOut = StrList{idx};
            elseif nhit>1
               % Look for exact match
               idxe = find(strcmpi(str,StrList(idx)));
               if length(idxe)==1
                  strOut = StrList{idx(idxe)};
               end
            end
         end
      end
      
   end
   
end

function ver = localver()
% generate a version number
% can't use ltipack.ver()
ver = 20; % r2018a;
end
