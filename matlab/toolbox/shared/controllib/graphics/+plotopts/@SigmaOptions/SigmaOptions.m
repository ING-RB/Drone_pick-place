classdef (TruncatedProperties, CaseInsensitiveProperties) SigmaOptions < plotopts.RespPlotOptions
%SIGMAPLOTOPTIONS class

%  Copyright 1986-2021 The MathWorks, Inc.  



    properties
        FreqUnits = 'rad/s';
        FreqScale = 'log';
        MagUnits = 'dB';
        MagScale = 'linear';
    end
    
    
    methods
        % ------------------------------------------------------------------------%
        % Constructor
        % ------------------------------------------------------------------------%    
        function this = SigmaOptions(varargin)
            narginchk(0,1)
            
            if ~isempty(varargin) 
                if strcmpi(varargin{1},'cstprefs')
                    mapCSTPrefs(this);
                else
                    error(message('Controllib:plots:PlotOptions01'))
                end
            end
            
            this.Title.String = ctrlMsgUtils.message('Controllib:plots:strSingularValues');
            this.XLabel.String = ctrlMsgUtils.message('Controllib:plots:strFrequency');
            this.YLabel.String = ctrlMsgUtils.message('Controllib:plots:strSingularValues');  
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting FreqUnits property
        % ------------------------------------------------------------------------%        
        function set.FreqUnits(this, ProposedValue)           
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
            this.FreqUnits = valueStored;
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
        
        
    end
    
    
    
    
    methods (Access = protected)

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting MagScale and FreqScale property
        % ------------------------------------------------------------------------%          
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
    
    
    
    
end