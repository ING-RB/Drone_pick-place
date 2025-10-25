classdef (TruncatedProperties, CaseInsensitiveProperties) RespPlotOptions < plotopts.PlotOptions
%RESPPLOTOPTIONS class

%  Copyright 1986-2015 The MathWorks, Inc.

    properties
        IOGrouping = 'none';
        InputLabels = struct('FontSize',   8, ...
                        'FontWeight', 'Normal', ...
                        'FontAngle',  'Normal', ...
                        'Color',      [0.4,0.4,0.4], ...
                        'Interpreter', 'tex');
        OutputLabels = struct('FontSize',   8, ...
                        'FontWeight', 'Normal', ...
                        'FontAngle',  'Normal', ...
                        'Color',      [0.4,0.4,0.4], ...
                        'Interpreter', 'tex');
       InputVisible = {'on'};     
       OutputVisible = {'on'};
    end
    
    methods
        % ------------------------------------------------------------------------%
        % Constructor
        % ------------------------------------------------------------------------%        
        function this = RespPlotOptions
            this.ColorMode.InputLabels = "auto";
            this.ColorMode.OutputLabels = "auto";
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting IOGrouping property
        % ------------------------------------------------------------------------%
        function set.IOGrouping(this,ProposedValue)
            valueStored = this.IOGrouping;
            
            if ischar(ProposedValue) && any(strcmpi(ProposedValue, {'none','all','inputs','outputs'}))
                valueStored = lower(ProposedValue);
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties05')
            end
            
            this.IOGrouping = valueStored;
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting InputLabels property
        % ------------------------------------------------------------------------%
        function set.InputLabels(this,ProposedValue)
            this.InputLabels = validateIOLabel(this,'InputLabels',ProposedValue);
        end

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting OutputLabels property
        % ------------------------------------------------------------------------%
        function set.OutputLabels(this,ProposedValue)
            this.OutputLabels = validateIOLabel(this,'OutputLabels',ProposedValue);
        end

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting InputVisible property
        % ------------------------------------------------------------------------%
        function set.InputVisible(this,ProposedValue)
            this.InputVisible = validateIOVisible(this,'InputVisible',ProposedValue);
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting OutputVisible property
        % ------------------------------------------------------------------------%
        function set.OutputVisible(this,ProposedValue)
            this.OutputVisible = validateIOVisible(this,'OutputVisible',ProposedValue);
        end
        
    end
    
    methods (Access = protected)

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting InputLabels and OutputLabels property
        % ------------------------------------------------------------------------%
        function IOLabel = validateIOLabel(this, Prop, ProposedValue)            
            IOLabel = this.(Prop);
            if isstruct(ProposedValue)
                Fields = fields(ProposedValue);
                for ct = 1:length(Fields)
                    switch Fields{ct}
                        case 'FontSize'
                            IOLabel.FontSize = ProposedValue.FontSize;
                        case 'FontWeight'
                            IOLabel.FontWeight = ProposedValue.FontWeight;
                        case 'FontAngle'
                            IOLabel.FontAngle = ProposedValue.FontAngle;
                        case 'Color'
                            if any(IOLabel.Color ~= ProposedValue.Color)
                                IOLabel.Color = ProposedValue.Color;
                                this.ColorMode.(Prop) = "manual";
                            end
                        case 'Interpreter'
                            IOLabel.Interpreter = ProposedValue.Interpreter;
                        otherwise
                            ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties01',Fields{ct},Prop)
                    end
                end
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties02',Prop)
            end
        end
    
        % ---------------------------------------------------------------------------%
        % Purpose:  Error handling of setting InputVisible and OutputVisible property
        % ---------------------------------------------------------------------------%    
        function IOVisible = validateIOVisible(this, Prop, ProposedValue)            
            if iscell(ProposedValue) && ...
                    all(strcmpi(ProposedValue,{'on'}) | strcmpi(ProposedValue,{'off'}))
                IOVisible = lower(ProposedValue(:));
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties03',Prop)
            end
        end
        
    end   
    
    
    
 
end

