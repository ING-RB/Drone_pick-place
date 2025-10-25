classdef (TruncatedProperties, CaseInsensitiveProperties) BodeOptions < plotopts.RespPlotOptions
%BODEPLOTOPTIONS class

%  Copyright 1986-2021 The MathWorks, Inc.    
  
    
    properties
        FreqUnits = 'rad/s';
        FreqScale = 'log';
        MagUnits = 'dB';
        MagScale = 'linear';
        MagVisible = 'on';
        MagLowerLimMode = 'auto';
        PhaseUnits = 'deg';
        PhaseVisible = 'on';
        PhaseWrapping = 'off';
        PhaseMatching = 'off';
        PhaseMatchingFreq = 0;
        ConfidenceRegionNumberSD = 1;
    end
    
    properties (Dependent)
        MagLowerLim
        PhaseMatchingValue
        PhaseWrappingBranch % units in PhaseUnits
    end
    
    properties (Access = ?plotopts.BodePlotOptions, Transient)
        FreqUnits_ = 'rad/s'; 
    end
    
    properties (Access = ?plotopts.BodePlotOptions)
        MagLowerLim_ = 0;
        PhaseMatchingValue_ = 0;
        PhaseWrappingBranch_ = -pi; % units in rad
    end
    
    
    
    
    methods
        % ------------------------------------------------------------------------%
        % Constructor
        % ------------------------------------------------------------------------%   
        function this = BodeOptions(varargin)
       
           narginchk(0,1)
            
            if ~isempty(varargin) 
                if strcmpi(varargin{1},'cstprefs')
                    mapCSTPrefs(this);
                else
                    error(message('Controllib:plots:PlotOptions01'))
                end
            end
            
            this.Title.String = ctrlMsgUtils.message('Controllib:plots:strBodeDiagram');
            this.XLabel.String = ctrlMsgUtils.message('Controllib:plots:strFrequency');
            this.YLabel.String = {ctrlMsgUtils.message('Controllib:plots:strMagnitude'), ...
                ctrlMsgUtils.message('Controllib:plots:strPhase')};
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
        % Purpose:  Error handling of setting MagLowerLim_ property
        % ------------------------------------------------------------------------%       
        function set.MagLowerLim(this, ProposedValue)
            if isnumeric(ProposedValue) && isscalar(ProposedValue) && ...
                    isreal(ProposedValue) && ~(ProposedValue==inf)
                % store the value in absolute units
                this.MagLowerLim_ = unitconv(ProposedValue,this.MagUnits,'abs');
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties07','MagLowerLim')
            end
        end

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting MagLowerLimMode property
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
        % Purpose:  Error handling of setting MagVisible property
        % ------------------------------------------------------------------------%          
        function set.MagVisible(this, ProposedValue)
            this.MagVisible = validateOnOff(this,'MagVisible',ProposedValue);
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
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting PhaseVisible property
        % ------------------------------------------------------------------------%          
        function set.PhaseVisible(this, ProposedValue)
            this.PhaseVisible = validateOnOff(this,'PhaseVisible',ProposedValue);
        end

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting PhaseWrapping property
        % ------------------------------------------------------------------------%         
        function set.PhaseWrapping(this, ProposedValue)
            this.PhaseWrapping = validateOnOff(this,'PhaseWrapping',ProposedValue);
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting PhaseMatching property
        % ------------------------------------------------------------------------%           
        function set.PhaseMatching(this, ProposedValue)
            this.PhaseMatching = validateOnOff(this,'PhaseMatching',ProposedValue);
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
        % Purpose:  Error handling of setting ConfidenceRegionNumberSD property
        % ------------------------------------------------------------------------% 
        function set.ConfidenceRegionNumberSD(this, ProposedValue)

            if isnumeric(ProposedValue) && isscalar(ProposedValue) && ...
                    isreal(ProposedValue) && isfinite(ProposedValue) && (ProposedValue>=0)
                % store the value in absolute units
                valueStored = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties07','ConfidenceRegionNumberSD')
            end
            this.ConfidenceRegionNumberSD = valueStored;
        end
        
        
        
        
        % ------------------------------------------------------------------------%
        % Purpose:  Get the value for MagLowerLim property
        % ------------------------------------------------------------------------%         
        function MagLowerLim = get.MagLowerLim(this)
            % note MagLowerLim is stored in abs in the object
            MagLowerLim = unitconv(this.MagLowerLim_,'abs',this.MagUnits);
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
        % Purpose:  Error handling of setting MagVisisble, PhaseVisible, PhaseMatching, PhaseWrapping property
        % -----------------------------------------------------------------------------------------------------%         
        function flag = validateOnOff(this, Prop, ProposedValue)
            if strcmpi(ProposedValue,'on') || strcmpi(ProposedValue,'off')
                flag = lower(ProposedValue);
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties10',Prop)
            end
        end
        
        % ---------------------------------------------------------%
        % Purpose:  Error handling of MagScale, FreqScale property
        % ---------------------------------------------------------%                 
        function scale = validateScale(this, Prop, ProposedValue)
            
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