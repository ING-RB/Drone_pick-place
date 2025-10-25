classdef (TruncatedProperties, CaseInsensitiveProperties) PlotOptions < handle & matlab.mixin.SetGet ...
                                                                        & matlab.mixin.Copyable
%PLOTOPTIONS class    
    
%  Copyright 1986-2015 The MathWorks, Inc.

    properties (Hidden)
        Version
        ColorMode = struct('Title',"auto",...
                           'XLabel',"auto",...
                           'YLabel',"auto",...
                           'TickLabel',"auto",...
                           'Grid',"auto");
    end
    
    properties
        Title = struct('String',     '', ...
            'FontSize',   8, ...
            'FontWeight', 'Normal', ...
            'FontAngle',  'Normal', ...
            'Color',      [0,0,0], ...
            'Interpreter', 'tex');
        
        XLabel = struct('String',     '', ...
            'FontSize',   8, ...
            'FontWeight', 'Normal', ...
            'FontAngle',  'Normal', ...
            'Color',      [0,0,0], ...
            'Interpreter', 'tex');
        
        YLabel =  struct('String',     '', ...
            'FontSize',   8, ...
            'FontWeight', 'Normal', ...
            'FontAngle',  'Normal', ...
            'Color',      [0,0,0], ...
            'Interpreter', 'tex');
        
        TickLabel = struct('FontSize',   8, ...
            'FontWeight', 'Normal', ...
            'FontAngle',  'Normal', ...
            'Color',      [0,0,0]);
        
        Grid = 'off';       
        GridColor = get(0,'DefaultAxesGridColor');       
        XLim = {[1 10]};         
        YLim = {[1 10]};       
        XLimMode = {'auto'};
        YLimMode = {'auto'};
    end
    


    
    methods
        % ------------------------------------------------------------------------%
        % Constructor
        % ------------------------------------------------------------------------%  
        function this = PlotOptions
            %PLOTOPTIONS
            
            % Set Version Number
            % Version 2.0 convert to MCOS
            this.Version = 2.0;
        end

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting Title property
        % ------------------------------------------------------------------------%          
        function set.Title(this,ProposedValue)
            this.Title = validateLabel(this,'Title',ProposedValue);
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting XLabel property
        % ------------------------------------------------------------------------%          
        function set.XLabel(this,ProposedValue)
            this.XLabel = validateLabel(this,'XLabel',ProposedValue);
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting YLabel property
        % ------------------------------------------------------------------------%          
        function set.YLabel(this,ProposedValue)
            this.YLabel = validateLabel(this,'YLabel',ProposedValue);
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting TickLabel property
        % ------------------------------------------------------------------------%          
        function set.TickLabel(this,ProposedValue)
            valueStored = this.TickLabel;
            if isstruct(ProposedValue)
                Fields = fields(ProposedValue);
                for ct = 1:length(Fields)
                    switch Fields{ct}
                        case 'FontSize'
                            valueStored.FontSize = ProposedValue.FontSize;
                        case 'FontWeight'
                            valueStored.FontWeight = ProposedValue.FontWeight;
                        case 'FontAngle'
                            valueStored.FontAngle = ProposedValue.FontAngle;
                        case 'Color'
                            if any(valueStored.Color ~= ProposedValue.Color)
                                valueStored.Color = ProposedValue.Color;
                                this.ColorMode.TickLabel = "manual";
                            end
                        otherwise
                            ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties01',Fields{ct},'TickLabel')
                    end
                end
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties02','TickLabel')
            end
            this.TickLabel = valueStored;
        end

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting Grid property
        % ------------------------------------------------------------------------%          
       function set.Grid(this,ProposedValue)
           
           if strcmpi(ProposedValue,'on') || strcmpi(ProposedValue,'off')
               this.Grid = lower(ProposedValue);
           else
               ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties10','Grid')
           end
       end

       function set.GridColor(this,ProposedValue)
           if ~isequal(this.GridColor,ProposedValue)
               this.GridColor = ProposedValue;
               this.ColorMode.Grid = "manual";
           end
       end

        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting XLim property
        % ------------------------------------------------------------------------%        
        function set.XLim(this,ProposedValue)
            this.XLim = validateLim(this,'XLim',ProposedValue);
            this.XLimMode = repmat({'manual'},size(this.XLimMode));
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting YLim property
        % ------------------------------------------------------------------------%           
        function set.YLim(this,ProposedValue)
            this.YLim = validateLim(this,'YLim',ProposedValue);
            this.YLimMode = repmat({'manual'},size(this.YLimMode));
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting XLimMode property
        % ------------------------------------------------------------------------%           
        function set.XLimMode(this,ProposedValue)
            if isstring(ProposedValue) || (iscell(ProposedValue) && isstring(ProposedValue{1}))
                % Convert to char if strings passed in
                if iscell(ProposedValue)
                    ProposedValue = cellfun(@(x) char(x),ProposedValue,UniformOutput=false);
                else
                    ProposedValue = char(ProposedValue);
                end
            end
            this.XLimMode = validateLimMode(this,'XLimMode',ProposedValue);
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting YLimMode property
        % ------------------------------------------------------------------------%          
        function set.YLimMode(this,ProposedValue)
            if isstring(ProposedValue) || (iscell(ProposedValue) && isstring(ProposedValue{1}))
                % Convert to char if strings passed in
                if iscell(ProposedValue)
                    ProposedValue = cellfun(@(x) char(x),ProposedValue,UniformOutput=false);
                else
                    ProposedValue = char(ProposedValue);
                end
            end
            this.YLimMode = validateLimMode(this,'YLimMode',ProposedValue);
        end
        

        
    end
    
    
    methods (Access = protected)
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting XLabel and YLabel property
        % ------------------------------------------------------------------------%          
        function  Label = validateLabel(this,Prop,ProposedValue)
            Label = this.(Prop);
            if isstruct(ProposedValue)
                Fields = fields(ProposedValue);
                for ct = 1:length(Fields)
                    switch Fields{ct}
                        case 'String'
                            Label.String = ProposedValue.String;
                        case 'FontSize'
                            Label.FontSize = ProposedValue.FontSize;
                        case 'FontWeight'
                            Label.FontWeight = ProposedValue.FontWeight;
                        case 'FontAngle'
                            Label.FontAngle = ProposedValue.FontAngle;
                        case 'Color'
                            if any(Label.Color ~= ProposedValue.Color)
                                Label.Color = ProposedValue.Color;
                                this.ColorMode.(Prop) = "manual";
                            end
                            
                        case 'Interpreter'
                            Label.Interpreter = ProposedValue.Interpreter;
                        otherwise
                            ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties01',Fields{ct},Prop)
                    end
                end
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties02',Prop)              
            end            
        end
        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting XLim and YLim property
        % ------------------------------------------------------------------------%           
        function Lim = validateLim(this, Prop, ProposedValue)
          
            if isnumeric(ProposedValue)
                ProposedValue = {ProposedValue};
            end

            if iscell(ProposedValue) && all(cellfun(@(x) size(x,2),ProposedValue(:))==2)
                for ct = 1:length(ProposedValue)
                    if ProposedValue{ct}(2) <= ProposedValue{ct}(1)
                        ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties04',Prop)
                    end
                end
                Lim = ProposedValue;
            else
                ctrlMsgUtils.error('Controllib:plots:PlotOptionsProperties04',Prop)
            end
        end

        
        % ------------------------------------------------------------------------%
        % Purpose:  Error handling of setting XLimMode_ and YLimMode_ property
        % ------------------------------------------------------------------------%           
        function LimMode = validateLimMode(this, Prop, ProposedValue)
            
            if ischar(ProposedValue)
                ProposedValue = {ProposedValue};
            end
            if iscell(ProposedValue) && ...
                    all(strcmpi(ProposedValue(:),{'auto'}) | strcmpi(ProposedValue(:),{'manual'}))
                LimMode = lower(ProposedValue);
            else
                ctrlMsgUtils.error('Controllib:plots:LimModeProperty1',Prop)
            end
        end
    
    
    
    end

end




