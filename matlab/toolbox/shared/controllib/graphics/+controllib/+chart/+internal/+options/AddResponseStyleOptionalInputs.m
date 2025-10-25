classdef AddResponseStyleOptionalInputs < matlab.mixin.SetGet
    properties
        Color
        LineStyle (1,1) string = ""
        LineWidth double {mustBeScalarOrEmpty} = []
        MarkerStyle (1,1) string = ""
        MarkerSize double {mustBeScalarOrEmpty} = []
    end

    methods (Static)
        function applyToStyle(style,optionalInputs)
            arguments
                style (1,1) controllib.chart.internal.options.ResponseStyle
                optionalInputs  struct
            end
            
            fieldsToSet = fields(controllib.chart.internal.options.AddResponseStyleOptionalInputs);
            for k = 1:length(fieldsToSet)
                if isfield(optionalInputs,fieldsToSet{k}) && ~isempty(optionalInputs.(fieldsToSet{k})) && ~strcmp(optionalInputs.(fieldsToSet{k}),'')
                    style.(fieldsToSet{k}) = optionalInputs.(fieldsToSet{k});
                end
            end
        end
    end
end