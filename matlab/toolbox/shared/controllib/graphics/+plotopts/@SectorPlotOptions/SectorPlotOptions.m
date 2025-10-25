classdef (TruncatedProperties, CaseInsensitiveProperties) SectorPlotOptions < plotopts.RespPlotOptions
%SECTORPLOTOPTIONS class

%  Copyright 2015 The MathWorks, Inc.
    
    properties
        FreqUnits = 'rad/s';
        FreqScale = 'log';
        IndexScale = 'log';
    end
    
    methods
        % ------------------------------------------------------------------------%
        % Constructor
        % ------------------------------------------------------------------------%            
        function this = SectorPlotOptions(varargin)
        
            if ~isempty(varargin) && strcmpi(varargin{1},'cstprefs')
                mapCSTPrefs(this);
            end
            
            this.Title.String = getString(message('Controllib:plots:strSectorIndexTitle'));
            this.XLabel.String = getString(message('Controllib:plots:strFrequency'));
            this.YLabel.String = getString(message('Controllib:plots:strSectorIndex'));
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting Frequency Units property
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
        % Purpose:  Error handling of setting IndexScale property
        % ------------------------------------------------------------------------%
        function set.IndexScale(this,ProposedValue)
            this.IndexScale = validateScale(this,'IndexScale',ProposedValue);
        end
    end
    
    methods (Access = private)
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting Freq and Mag scale property
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

