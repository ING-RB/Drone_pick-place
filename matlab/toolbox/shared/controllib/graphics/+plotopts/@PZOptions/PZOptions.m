classdef (TruncatedProperties, CaseInsensitiveProperties) PZOptions < plotopts.RespPlotOptions
%PZMAPOPTIONS class

%  Copyright 1986-2021 The MathWorks, Inc.
    
    properties
        FreqUnits = 'rad/s';
        TimeUnits = 'seconds';
        ConfidenceRegionNumberSD = 1;
    end
    
    methods
        % ------------------------------------------------------------------------%
        % Constructor
        % ------------------------------------------------------------------------%            
      
        function this = PZOptions(varargin)
         
            if ~isempty(varargin) && strcmpi(varargin{1},'cstprefs')
                mapCSTPrefs(this);
            end
            
            this.Title.String = ctrlMsgUtils.message('Controllib:plots:strPoleZeroMap');
            this.XLabel.String = ctrlMsgUtils.message('Controllib:plots:strRealAxis');
            this.YLabel.String = ctrlMsgUtils.message('Controllib:plots:strImaginaryAxis');
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
        % Purpose:  Error handling of setting TimeUnits property
        % ------------------------------------------------------------------------%
        function set.TimeUnits(this, ProposedValue)
            
            ValidValues = {'auto','nanoseconds', 'microseconds', 'milliseconds', ...
                'seconds', 'minutes', 'hours', 'days', 'weeks', 'months','years'};

            if ischar(ProposedValue) && ismember(ProposedValue,ValidValues)
                this.TimeUnits = ProposedValue;
            else
                % need to add error message
                ctrlMsgUtils.error('Controllib:plots:TimeUnitsProperty','TimeUnits')
            end
        end
        
        % ------------------------------------------------------------------------%
        % Function: LocalSetConfidenceRegionNumberSD
        % Purpose:  Error handling of setting ConfidenceRegionNumberSD property
        % ------------------------------------------------------------------------%
        function set.ConfidenceRegionNumberSD(this, ProposedValue)
            if isnumeric(ProposedValue) && isscalar(ProposedValue) && ...
                    isreal(ProposedValue) && isfinite(ProposedValue) && (ProposedValue>=0)
                % store the value in absolute units
                this.ConfidenceRegionNumberSD  = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties07','ConfidenceRegionNumberSD')
            end
        end
        
    end
    
end

