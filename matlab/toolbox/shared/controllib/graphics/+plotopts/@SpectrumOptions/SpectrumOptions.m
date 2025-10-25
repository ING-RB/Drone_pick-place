classdef (TruncatedProperties, CaseInsensitiveProperties) SpectrumOptions < plotopts.RespPlotOptions
%SPECTRUMPLOTOPTIONS class

%  Copyright 2015-2021 The MathWorks, Inc.       
    
    properties
        FreqUnits = 'rad/s';
        FreqScale = 'log';
        MagUnits = 'dB';
        MagScale = 'linear';
        MagLowerLimMode = 'auto';
        ConfidenceRegionNumberSD = 1;
    end
    
    
    properties (Access = ?plotopts.SpectrumPlotOptions, Transient)
        FreqUnits_ = 'rad/s';
    end
    
    properties (Dependent)
        MagLowerLim
    end
    
    properties (Access = ?plotopts.SpectrumPlotOptions)
        MagLowerLim_ = 0
    end
    
    
    methods
        % ------------------------------------------------------------------------%
        % Constructor
        % ------------------------------------------------------------------------% 
        function this = SpectrumOptions(varargin)
            
           varargin = controllib.internal.util.hString2Char(varargin);
           
            if ~isempty(varargin) && any(strcmpi(varargin{1},{'cstprefs','identpref'}))
                mapCSTPrefs(this);
            end
            
            this.Title.String = ctrlMsgUtils.message('Controllib:plots:strPowerSpectrum');
            this.XLabel.String = ctrlMsgUtils.message('Controllib:plots:strFrequency');
            this.YLabel.String = ctrlMsgUtils.message('Controllib:plots:strPower');
        end

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting Frequency Units property
        % ------------------------------------------------------------------------%      
        function set.FreqUnits(this, ProposedValue)
            
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
        % Purpose:  Error handling of setting Magnitude Units property
        % ------------------------------------------------------------------------%
        function set.MagUnits(this, ProposedValue)
            
            if iscell(ProposedValue)
                ProposedValue  = ProposedValue{1};
            end
            if any(strcmpi(ProposedValue,{'dB','abs'}))
                this.MagUnits = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:MagUnitsProperty1')
            end
        end

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting MagLowerLim property
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
        % Purpose:  Get MagLowerLim property
        % ------------------------------------------------------------------------%
        function MagLowerLim = get.MagLowerLim(this)
            % note MagLowerLim is stored in abs in the object
             MagLowerLim = unitconv(this.MagLowerLim_,'abs',this.MagUnits);
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting Mag lower lim mode property
        % ------------------------------------------------------------------------%
        function set.MagLowerLimMode(this, ProposedValue)
            
            if iscell(ProposedValue)
                ProposedValue  = ProposedValue{1};
            end
            if any(strcmpi(ProposedValue,{'auto','manual'}))
                this.MagLowerLimMode = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:LimModeProperty2','MagLowerLimMode')
            end
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting ConfidenceRegionNumberSD property
        % ------------------------------------------------------------------------%
        function set.ConfidenceRegionNumberSD(this, ProposedValue)
            if isnumeric(ProposedValue) && isscalar(ProposedValue) && ...
                    isreal(ProposedValue) && isfinite(ProposedValue) && (ProposedValue>=0)
                % store the value in absolute units
                this.ConfidenceRegionNumberSD = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties07','ConfidenceRegionNumberSD')
            end
        end

    end
    
    methods (Access = protected)
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting Frequency and Magnitude Scale property
        % ------------------------------------------------------------------------%
        function scale = validateScale(this, Prop, ProposedValue)
            
            if iscell(ProposedValue)
                ProposedValue  = ProposedValue{1};
            end
            if any(strcmpi(ProposedValue,{'log','linear'}))
                scale = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:ScaleProperty1',Prop)
            end
        end
        
        
    end
    
    methods (Access = private)
        
        function valueStored = validateFreqUnits_(this,ProposedValue)
            % validateFreqUnits returns value to be stored for frequency units for SpectrumPlotOptions

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

