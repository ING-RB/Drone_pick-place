classdef (TruncatedProperties, CaseInsensitiveProperties) DiskMarginOptions < plotopts.RespPlotOptions
   % DISKMARGINPLOTOPTIONS class
   
   %  Copyright 1986-2021 The MathWorks, Inc.
   
   properties
      FreqUnits = 'rad/s';
      FreqScale = 'log';
      MagUnits = 'dB';
      MagScale = 'linear';
      PhaseUnits = 'deg';
   end
   
   properties (Access = private, Transient)
      FreqUnits_ = 'rad/s';
   end
   
   
   methods
      % ------------------------------------------------------------------------%
      % Constructor
      % ------------------------------------------------------------------------%
      function this = DiskMarginOptions(varargin)
         
         narginchk(0,1)
         
         if ~isempty(varargin)
            if strcmpi(varargin{1},'cstprefs')
               mapCSTPrefs(this);
            else
               error(message('Controllib:plots:PlotOptions01'))
            end
         end
         
         this.Title.String = ctrlMsgUtils.message('Controllib:plots:strDiskMarginTitle');
         this.XLabel.String = ctrlMsgUtils.message('Controllib:plots:strFrequency');
         this.YLabel.String = {ctrlMsgUtils.message('Controllib:plots:strDiskMarginMag');...
            ctrlMsgUtils.message('Controllib:plots:strDiskMarginPhase')};
      end
      
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting FreqUnits property
      % ------------------------------------------------------------------------%
      function set.FreqUnits(this,ProposedValue)
         try
            this.FreqUnits = validateFreqUnits_(this,ProposedValue);
         catch ME
            throw(ME)
         end
      end
      
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting FreqScale property
      % ------------------------------------------------------------------------%
      function set.FreqScale(this,ProposedValue)
         this.FreqScale = validateScale(this,'FreqScale',ProposedValue);
      end
      
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting MagScale property
      % ------------------------------------------------------------------------%
      function set.MagScale(this,ProposedValue)
         this.MagScale = validateScale(this,'MagScale',ProposedValue);
      end
      
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting MagUnits property
      % ------------------------------------------------------------------------%
      function set.MagUnits(this, ProposedValue)
         if iscell(ProposedValue)
            ProposedValue  = ProposedValue{1};
         end
         if strcmpi(ProposedValue,'dB')
            valueStored = 'dB';
         elseif strcmpi(ProposedValue,'abs')
            valueStored = 'abs';
         else
            ctrlMsgUtils.error('Controllib:plots:MagUnitsProperty1')
         end
         this.MagUnits = valueStored;
      end
      
      
      % ------------------------------------------------------------------------%
      % Purpose:  Error handling of setting PhaseUnits property
      % ------------------------------------------------------------------------%
      function set.PhaseUnits(this, ProposedValue)
         if iscell(ProposedValue)
            ProposedValue  = ProposedValue{1};
         end
         if any(strcmpi(ProposedValue,{'deg','rad'}))
            this.PhaseUnits = lower(ProposedValue);
         else
            ctrlMsgUtils.error('Controllib:plots:PhaseUnitsProperty1','PhaseUnits')
         end
      end
      
   end
   
   
   methods (Access = protected)
      % -----------------------------------------------------------------------------------------------------%
      % Purpose:  Error handling of setting MagVisisble, PhaseVisible, PhaseMatching, PhaseWrapping property
      % -----------------------------------------------------------------------------------------------------%
      function flag = validateOnOff(~, Prop, ProposedValue)
         if strcmpi(ProposedValue,'on') || strcmpi(ProposedValue,'off')
            flag = lower(ProposedValue);
         else
            ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties10',Prop)
         end
      end
      
      % ---------------------------------------------------------%
      % Purpose:  Error handling of MagScale, FreqScale property
      % ---------------------------------------------------------%
      function scale = validateScale(~, Prop, ProposedValue)
         
         if iscell(ProposedValue)
            ProposedValue  = ProposedValue{1};
         end
         if any(strcmpi(ProposedValue,{'log','linear'}))
            scale = lower(ProposedValue);
         else
            ctrlMsgUtils.error('Controllib:plots:ScaleProperty1',Prop)
         end
      end
      
   end
   
   
   methods (Access = private)
      
      % ------------------------------------------------------------------------%
      % Purpose:  Get the value for FreqUnits_ property
      % ------------------------------------------------------------------------%
      function valueStored = getFreqUnits_(this)
         % getFreqUnits_ returns private value FreqUnits_
         valueStored = this.FreqUnits_;
      end
      
      % ---------------------------------------------------------%
      % Purpose:  Error handling of FreqUnits_ property
      % ---------------------------------------------------------%
      function valueStored = validateFreqUnits_(this,ProposedValue)
         % validateFreqUnits_ returns value to be stored for frequency units
         if iscell(ProposedValue)
            ProposedValue  = ProposedValue{1};
         end
         FrequencyUnits = controllibutils.utGetValidFrequencyUnits;
         ValidFrequencyUnits = ['auto';FrequencyUnits(:,1)];
         
         if strcmpi(ProposedValue,'rad/sec')
            valueStored = 'rad/s';
         elseif any(strcmpi(ProposedValue,ValidFrequencyUnits))
            valueStored = ProposedValue;
         else
            StringList = sprintf('"%s"',ValidFrequencyUnits{1});
            for ct = 2:length(ValidFrequencyUnits)
               StringList = [StringList,', ', sprintf('"%s"',ValidFrequencyUnits{ct})]; %#ok<AGROW>
            end
            ctrlMsgUtils.error('Controllib:plots:PropertyMultipleStrings','FreqUnits',StringList)
         end
         if ~strcmpi(valueStored,'auto')
            this.FreqUnits_ = valueStored;
         end
      end
      
   end
   
end