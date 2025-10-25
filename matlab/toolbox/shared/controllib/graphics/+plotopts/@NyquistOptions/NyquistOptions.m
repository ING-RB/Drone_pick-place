classdef (TruncatedProperties, CaseInsensitiveProperties) NyquistOptions < plotopts.RespPlotOptions
%NYQUISTPLOTOPTIONS class

%  Copyright 1986-2021 The MathWorks, Inc.
    
    properties
        FreqUnits = 'rad/s';
        MagUnits = 'dB';
        PhaseUnits = 'deg';
        ShowFullContour = 'on';
        ConfidenceRegionNumberSD = 1;
        ConfidenceRegionDisplaySpacing = 5;    
    end
    
    methods
        % ------------------------------------------------------------------------%
        % Constructor
        % ------------------------------------------------------------------------%        
        function this = NyquistOptions(varargin)
            
            if ~isempty(varargin) && strcmpi(varargin{1},'cstprefs')
                mapCSTPrefs(this);
            end
            
            this.Title.String = ctrlMsgUtils.message('Controllib:plots:strNyquistDiagram');
            this.XLabel.String = ctrlMsgUtils.message('Controllib:plots:strRealAxis');
            this.YLabel.String = ctrlMsgUtils.message('Controllib:plots:strImaginaryAxis');
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting ShowFullContour property
        % ------------------------------------------------------------------------%
        function set.ShowFullContour(this,ProposedValue)
            
            if strcmpi(ProposedValue,'on') || strcmpi(ProposedValue,'off')
                this.ShowFullContour = lower(ProposedValue);
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties10','ShowFullContour')
            end
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
        % Purpose:  Error handling of setting Phase Units property
        % ------------------------------------------------------------------------%
        function set.PhaseUnits(this, ProposedValue)
            
            if iscell(ProposedValue)
                ProposedValue  = ProposedValue{1};
            end
            if any(strcmpi(ProposedValue,{'rad','deg'}))
                this.PhaseUnits = lower(ProposedValue);
            else
                ctrlMsgUtils.error('Controllib:plots:PhaseUnitsProperty1','PhaseUnits')
            end
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting Magnitude Units property
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
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting ConfidenceRegionDisplaySpacing property
        % ------------------------------------------------------------------------%
        function set.ConfidenceRegionDisplaySpacing(this, ProposedValue)
            if isnumeric(ProposedValue) && isscalar(ProposedValue) && ...
                    isreal(ProposedValue) && isfinite(ProposedValue) && ...
                    (ProposedValue>0) && (rem(ProposedValue,1)==0)
                % store the value in absolute units
                this.ConfidenceRegionDisplaySpacing = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties07','ConfidenceRegionDisplaySpacing')
            end
        end
        
        
    end
    
end

