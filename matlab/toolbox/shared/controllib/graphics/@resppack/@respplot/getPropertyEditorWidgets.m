function widgets = getPropertyEditorWidgets(this)
% Return Property Editor Dialog widgets

%  Copyright 2021 The MathWorks, Inc.
widgets.PropertyEditorDialog = this.PropEditor;
widgets.LabelsContainer = this.AxesGrid.LabelsContainer;
widgets.XLimitsContainer = this.AxesGrid.XLimitsContainer;
widgets.YLimitsContainer = this.AxesGrid.YLimitsContainer;
widgets.UnitsContainer = this.UnitsContainer;
widgets.GridContainer = this.AxesGrid.GridContainer;
widgets.FontsContainer = this.AxesGrid.FontsContainer;
widgets.ColorContainer = this.AxesGrid.AxesStyle.ColorContainer;
widgets.NoOptionsLabel = this.NoOptionsLabel;
widgets.TimeResponseContainer = this.TimeResponseContainer;
widgets.MagnitudeResponseContainer = this.MagnitudeResponseContainer;
widgets.PhaseResponseContainer = this.PhaseResponseContainer;
widgets.ConfidenceRegionContainer = this.ConfidenceRegionContainer;
end