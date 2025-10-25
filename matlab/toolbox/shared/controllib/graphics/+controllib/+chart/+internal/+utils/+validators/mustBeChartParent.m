function mustBeChartParent(parent,optionalInput)
    arguments
        parent
        optionalInput.ErrorMsg message = message.empty
    end
    if ~isempty(parent) && ~(isa(parent,"matlab.ui.Figure") || isa(parent,"matlab.ui.container.Panel") ||...
        isa(parent,"matlab.ui.container.Tab") || isa(parent,"matlab.ui.container.GridLayout") ||...
        isa(parent,"matlab.graphics.layout.TiledChartLayout") || isa(parent,"matlab.graphics.axis.Axes"))
        if isempty(optionalInput.ErrorMsg)
            error(message('Controllib:plots:mustBeChartParent'))
        else
            error(optionalInput.ErrorMsg)
        end
    end
end