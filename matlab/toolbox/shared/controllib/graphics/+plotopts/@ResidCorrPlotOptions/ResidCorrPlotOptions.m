classdef (TruncatedProperties, CaseInsensitiveProperties) ResidCorrPlotOptions < plotopts.RespPlotOptions
%ResidCorrPlotOptions class

%  Copyright 2015 The MathWorks, Inc.
    
    properties
        Normalize = 'off';
        ConfidenceRegionNumberSD = 2.5758;
    end
    
    methods
        
        % ------------------------------------------------------------------------%
        % Constructor
        % ------------------------------------------------------------------------%   
        function this = ResidCorrPlotOptions(varargin)
            
            if ~isempty(varargin) && strcmpi(varargin{1},'cstprefs')
                mapCSTPrefs(this);
            end
            
            this.Title.String = ctrlMsgUtils.message('Ident:plots:msgResidCorr');
            this.XLabel.String = 'Lag';
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
        % Purpose:  Error handling of setting ConfidenceRegionNumberSD property
        % ------------------------------------------------------------------------%         
        function set.ConfidenceRegionNumberSD(this, ProposedValue)
            
            if isnumeric(ProposedValue) && isscalar(ProposedValue) && ...
                    isreal(ProposedValue) && isfinite(ProposedValue) && (ProposedValue>=0)
                % store the value in absolute units
                this.ConfidenceRegionNumberSD = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties07',...
                    'ConfidenceRegionNumberSD')
            end
        end
        
    end
    

    

    
end

