classdef (TruncatedProperties, CaseInsensitiveProperties) NicholsOptions < plotopts.RespPlotOptions
    %NICHOLSPLOTOPTIONS class
    
    %  Copyright 1986-2021 The MathWorks, Inc.
    
    
    properties
        FreqUnits = 'rad/s';
        MagLowerLimMode = 'auto';
        MagLowerLim = 0;
        MagUnits = 'dB';
        PhaseUnits = 'deg';
        PhaseWrapping = 'off';
        PhaseMatching = 'off';
        PhaseMatchingFreq = 0;
    end
    
    properties (Dependent)
        PhaseMatchingValue
        PhaseWrappingBranch  % units in PhaseUnits
    end
    
    properties (Access = ?plotopts.NicholsPlotOptions, Transient)
        FreqUnits_ = 'rad/s';
    end
    
    properties (Access = ?plotopts.NicholsPlotOptions)
        PhaseMatchingValue_ = 0;
        PhaseWrappingBranch_ = -pi; % units in rad
    end
    
    methods
        % ------------------------------------------------------------------------%
        % Constructor
        % ------------------------------------------------------------------------%
        function this = NicholsOptions(varargin)
            
            if ~isempty(varargin) && strcmpi(varargin{1},'cstprefs')
                mapCSTPrefs(this);
            end
            
            this.Title.String = ctrlMsgUtils.message('Controllib:plots:strNicholsChart');
            this.XLabel.String = ctrlMsgUtils.message('Controllib:plots:strOpenLoopPhase');
            this.YLabel.String = ctrlMsgUtils.message('Controllib:plots:strOpenLoopGain');
        end
        
        % ------------------------------------------------------------------------%
        % Function: LocalSetFreqUnits
        % Purpose:  Error handling of setting Frequency Units property
        % ------------------------------------------------------------------------%
        function set.FreqUnits(this, ProposedValue)
            
            try
                this.FreqUnits = setFreqUnits_(this,ProposedValue);
            catch ME
                throw(ME)
            end
        end
 
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting PhaseMatchingFreq property
        % ------------------------------------------------------------------------%           
        function set.PhaseMatchingFreq(this, ProposedValue)
            % store the value in rad/s units
            if isnumeric(ProposedValue)
                this.PhaseMatchingFreq = ProposedValue*funitconv(getFreqUnits_(this),'rad/s'); % REVISIT
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties07','PhaseMatchingFreq')
            end
        end
 
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting PhaseMatchingValue property
        % ------------------------------------------------------------------------%     
        function set.PhaseMatchingValue(this, ProposedValue)
            % store the value in rad units
            if isnumeric(ProposedValue)
                this.PhaseMatchingValue_ = unitconv(ProposedValue,this.PhaseUnits,'rad');
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties07','PhaseMatchingValue')
            end
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting Phase Units property
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
        
        
        
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting Mag lower lim mode property
        % ------------------------------------------------------------------------%
        function set.MagLowerLimMode(this, ProposedValue)
            
            if iscell(ProposedValue)
                ProposedValue  = ProposedValue{1};
            end
            if any(strcmpi(ProposedValue,{'auto','manual'}))
                this.MagLowerLimMode = lower(ProposedValue);
            else
                ctrlMsgUtils.error('Controllib:plots:LimModeProperty2','MagLowerLimMode')
            end
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting MagLowerLim property
        % ------------------------------------------------------------------------%
        function set.MagLowerLim(this, ProposedValue)
            % Note MagLowerLim is stored in dB and -inf is valid
            if isnumeric(ProposedValue) && isscalar(ProposedValue) && ...
                    isreal(ProposedValue) && (ProposedValue~=inf)
                this.MagLowerLim = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties07','MagLowerLim')
            end
        end
        
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting PhaseWrapping property
        % ------------------------------------------------------------------------%         
        function set.PhaseWrapping(this, ProposedValue)
            this.PhaseWrapping = validateOnOff(this,'PhaseWrapping',ProposedValue);
        end
        
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting PhaseWrappingBranch property
        % ------------------------------------------------------------------------% 
        function set.PhaseWrappingBranch(this, ProposedValue)
            
            if isnumeric(ProposedValue) && isscalar(ProposedValue) && ...
                    isreal(ProposedValue) && isfinite(ProposedValue)
                % store the value in absolute units
                this.PhaseWrappingBranch_ = unitconv(ProposedValue,this.PhaseUnits,'rad');
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties07','PhaseWrappingBranch')
            end
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting PhaseMatching property
        % ------------------------------------------------------------------------%           
        function set.PhaseMatching(this, ProposedValue)
            this.PhaseMatching = validateOnOff(this,'PhaseMatching',ProposedValue);
        end
        
        
        % ------------------------------------------------------------------------%
        % Purpose:  Get the value for PhaseMatchingFreq property
        % ------------------------------------------------------------------------%
        function PhaseMatchingFreq = get.PhaseMatchingFreq(this)
            % note PhaseMatchingFreq is stored in rad/s in the object
            PhaseMatchingFreq = this.PhaseMatchingFreq*funitconv('rad/s',getFreqUnits_(this));
        end
        
        
        % ------------------------------------------------------------------------%
        % Purpose:  Get the value for PhaseWrappingBranch property
        % ------------------------------------------------------------------------%
        function PhaseWrappingBranch = get.PhaseWrappingBranch(this)
            % note PhaseMatchingFreq is stored in rad in the object
            PhaseWrappingBranch = unitconv(this.PhaseWrappingBranch_,'rad',this.PhaseUnits);
        end
        
        
        
        % ------------------------------------------------------------------------%
        % Purpose:  Get the value for PhaseMatchingValue property
        % ------------------------------------------------------------------------%
        function PhaseMatchingValue = get.PhaseMatchingValue(this)
            % note PhaseMatchingFreq is stored in rad in the object
            PhaseMatchingValue = unitconv(this.PhaseMatchingValue_,'rad',this.PhaseUnits);
        end
    end
    
    
    methods (Access = protected)
        % -----------------------------------------------------------------------------------------------------%
        % Purpose:  Error handling of setting PhaseMatching, PhaseWrapping property
        % -----------------------------------------------------------------------------------------------------%         
        function flag = validateOnOff(this, Prop, ProposedValue)
            if strcmpi(ProposedValue,'on') || strcmpi(ProposedValue,'off')
                flag = lower(ProposedValue);
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties10',Prop)
            end
        end
    end
    
    methods (Access = private)
        
        % ------------------------------------------------------------------------%
        % Purpose:  Get the value for FreqUnits_ property
        % ------------------------------------------------------------------------%
        function valueStored = getFreqUnits_(this)
            % getFreqUnits returns private value FreqUnits_
            
            valueStored = this.FreqUnits_;
        end
        
        % ---------------------------------------------------------%
        % Purpose:  Error handling of FreqUnits_ property
        % ---------------------------------------------------------%
        function valueStored = setFreqUnits_(this,ProposedValue)
            % setFreqUnits returns value to be stored for frequency units for NicholsPlotOptions
            
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

