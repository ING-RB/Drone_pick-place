classdef (TruncatedProperties, CaseInsensitiveProperties) TimeOptions < plotopts.RespPlotOptions
%TIMEPLOTOPTIONS class    
    
%  Copyright 1986-2021 The MathWorks, Inc.   
    
    properties
        Normalize = 'off';
        SettleTimeThreshold = .02;
        RiseTimeLimits = [.10 .90];
        TimeUnits = 'seconds';
        ConfidenceRegionNumberSD = 1;
        ComplexViewType (1,1) string {mustBeMember(ComplexViewType,["realimaginary","magnitudephase","complexplane"])} = "realimaginary"
    end
    
    
    methods
        % ------------------------------------------------------------------------%
        % Constructor
        % ------------------------------------------------------------------------%           
        function this = TimeOptions(varargin)            
            
            if ~isempty(varargin) && strcmpi(varargin{1},'cstprefs')
                mapCSTPrefs(this);
            end
            
            this.Title.String = ctrlMsgUtils.message('Controllib:plots:strTimeResponse');
            this.XLabel.String = ctrlMsgUtils.message('Controllib:plots:strTime');
            this.YLabel.String = ctrlMsgUtils.message('Controllib:plots:strAmplitude');
        end
 
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting Normalize property
        % ------------------------------------------------------------------------%
        function set.Normalize(this,ProposedValue)
            
            if strcmpi(ProposedValue,'on') || strcmpi(ProposedValue,'off')
                this.Normalize = lower(ProposedValue);
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties10','Normalize') 
            end
        end
  
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting SettleTimeThreshold property
        % ------------------------------------------------------------------------%        
        function set.SettleTimeThreshold(this, ProposedValue)
            if isnumeric(ProposedValue) && isscalar(ProposedValue) && ...
                    isreal(ProposedValue) && isfinite(ProposedValue)
                this.SettleTimeThreshold = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties08')
            end      
        end

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting RiseTimeLimits property
        % ------------------------------------------------------------------------%          
        function set.RiseTimeLimits(this, ProposedValue)
            if isnumeric(ProposedValue) && all((size(ProposedValue)==[1,2]))
                this.RiseTimeLimits = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties09')
            end
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
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
end