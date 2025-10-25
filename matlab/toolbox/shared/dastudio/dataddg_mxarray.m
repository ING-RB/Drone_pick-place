function dlgstruct = dataddg_mxarray(h)
%

% Copyright 2004-2022 The MathWorks, Inc.

  hasArgument = false;
  viewProxy = [];
  isStructInput = false; 
  
  if isstruct(h) && ...
          all(isfield(h, {'Name','Value', 'DataType','Dimensions','Complexity'}))
      objName = h.Name;
      objValue = h.Value;
      objDataType = h.DataType;
      objDimensions = h.Dimensions;
      objComplexity = h.Complexity;
      isStructInput = true;
  else
      objName = h.getDisplayLabel;
      objValue = h.getPropValue('Value');
      objDataType = h.getPropValue('DataType');
      objDimensions = h.getPropValue('Dimensions');
      objComplexity = h.getPropValue('Complexity');
      if h.isValidProperty('Argument')
          hasArgument = true;
          viewProxy   = h.getSlidViewProxy;
      end      
  end
   
  %-----------------------------------------------------------------------
  % First Row contains:
  % - Values label widget
  % - Values edit widget
  %-----------------------------------------------------------------------  
  valueText.Name          = DAStudio.message('dastudio:ddg:WSOValue');
  valueText.RowSpan       = [1 1];
  valueText.ColSpan       = [1 1];
  valueText.Type          = 'text';
  
  valueEdit.RowSpan       = [1 1];
  valueEdit.ColSpan       = [2 2];
  valueEdit.Type          = 'edit';
  valueEdit.Tag           = 'value_tag';
  
  if isStructInput
      valueEdit.Value          = objValue;
  else
      valueEdit.ObjectProperty= 'Value';
  end
  valueEdit.Mode          = 1;
  valueEdit.DialogRefresh = true;
  try
      if any(strcmp(methods(h), 'isReadonlyProperty')) && h.isReadonlyProperty('Value')
          valueEdit.Enabled = false;
      end
      if any(strcmp(methods(h), 'getPropertyStyle'))
          style = DAStudio.PropertyStyle;
          h.getPropertyStyle('Value', style);
          valueEdit.ToolTip = style.Tooltip;
      end
  catch
  end
  if hasArgument && viewProxy.isReadonlyProperty('Value')
      valueEdit.Enabled = false;
  end
  
  %-----------------------------------------------------------------------
  % Second Row contains:
  % - dataType label widget
  % - dataType edit widget
  %-----------------------------------------------------------------------  
  dataTypeText.Name       = DAStudio.message('dastudio:ddg:WSODataType');
  dataTypeText.Type       = 'text';
  dataTypeText.RowSpan    = [2 2];
  dataTypeText.ColSpan    = [1 1];
  
  dataType.RowSpan        = [2 2];
  dataType.ColSpan        = [2 2];
  dataType.Type           = 'edit';
  dataType.Tag            = 'dataType_tag';
  dataType.Enabled        = 0;
  dataType.Value          = objDataType;
  dataType.DisablePropertyActions = true;

 %-----------------------------------------------------------------------
  % Third Row contains:
  % - Dimension label widget
  %-----------------------------------------------------------------------  
  dimensionsText.Name       = DAStudio.message('dastudio:ddg:WSODimensions');
  dimensionsText.Type       = 'text';
  dimensionsText.RowSpan    = [3 3];
  dimensionsText.ColSpan    = [1 1];
  
  dimensions.RowSpan        = [3 3];
  dimensions.ColSpan        = [2 2];
  dimensions.Type           = 'edit';
  dimensions.Tag            = 'dimension_tag';
  dimensions.Enabled        = 0;
  dimensions.Value          = objDimensions;
  dimensions.DisablePropertyActions = true;
   
  %-----------------------------------------------------------------------
  % Fourth Row contains:
  % - Complexity label widget
  %-----------------------------------------------------------------------  
  complexityText.Name       = DAStudio.message('dastudio:ddg:WSOComplexity');
  complexityText.Type       = 'text';
  complexityText.RowSpan    = [4 4];
  complexityText.ColSpan    = [1 1];
  
  complexity.RowSpan        = [4 4];
  complexity.ColSpan        = [2 2];
  complexity.Type           = 'edit';
  complexity.Tag            = 'complexity_tag';
  complexity.Enabled        = 0;
  complexity.Value          = objComplexity;
  complexity.DisablePropertyActions = true;


  % Model-owned parameters has the need to configure whether
  % they are arguments.
  if hasArgument
      % If a MATLAB variable has 'Argument', it must be in model workspace.
      argument.Name               = DAStudio.message('Simulink:dialog:ArgumentText');
      argument.ObjectProperty     = 'Argument';
      
      argument.Tag                = 'chkArgument';
      argument.Type               = 'checkbox';
      argument.Source             = viewProxy;
      
      argument.Enabled            = true;
      if viewProxy.isReadonlyProperty('Argument')
          argument.Enabled        = false;
      end
      argument.RowSpan            = [5 5];
      argument.ColSpan            = [1 1];
      dlgstruct.SmartApply        = 0;
      dlgstruct.PostApplyCallback = 'dataddg_mxarray_cb';
      dlgstruct.PostApplyArgs     = {'%dialog', 'postapply_cb', h};
  end
  
  %-----------------------------------------------------------------------
  % Fifth Row contains:
  % - spacer panel to absorb extra space
  %-----------------------------------------------------------------------  
  spacer.Type             = 'panel';
  spacer.RowSpan          = [5 5];
  spacer.ColSpan          = [1 2];
  if hasArgument
     spacer.RowSpan       = [5 5];
     spacer.ColSpan       = [2 2];
     
  end
  
  lutViewer = getLUTViewer(h, valueEdit.Tag);

  %-----------------------------------------------------------------------
  % Assemble main dialog struct
  %-----------------------------------------------------------------------  
  dlgstruct.SmartApply       = 0;
  dlgstruct.DialogTag        = 'dataddg_mxarray';
  dlgstruct.DialogTitle      = [DAStudio.message('dastudio:ddg:DialogTitle'), ' ', objName];
  spacer2.Type               = 'panel';
  spacer2.ColSpan            = [1 2];
  lutViewer.ColSpan          = [1 2];
  if hasArgument
      spacer2.RowSpan            = [6 6];
      lutViewer.RowSpan          = [7 8];
      dlgstruct.LayoutGrid       = [8 2];
      dlgstruct.ColStretch       = [0 1];
      dlgstruct.RowStretch       = [0 0 0 0 0 0 0 1];
      dlgstruct.Items            = {valueText, valueEdit,...
                                    dataTypeText, dataType, ...
                                    dimensionsText, dimensions, ...
                                    complexityText, complexity, ...
                                    argument, spacer, ...
                                    spacer2, ...
                                    lutViewer};
  else
      lutViewer.RowSpan          = [6 7];
      dlgstruct.LayoutGrid       = [7 2];
      dlgstruct.ColStretch       = [0 1];
      dlgstruct.RowStretch       = [0 0 0 0 0 0 1];
      dlgstruct.Items            = {valueText, valueEdit,...
                                    dataTypeText, dataType, ...
                                    dimensionsText, dimensions, ...
                                    complexityText, complexity, ... 
                                    spacer, ...
                                    lutViewer};
  end
  
  dlgstruct.HelpMethod = 'helpview';
  dlgstruct.HelpArgs   = {'simulink', 'matlab_variable'};

end
%--------------------End of Main function --------------------------------
function container = getLUTViewer(h, valueTag)

    container.Type = 'panel';
    container.LayoutGrid = [2 2];
    container.Tag = 'matrixcontainer_tag';

    if any(strcmp(methods(h), 'getPropValue'))
        valStr = h.getPropValue('Value');
        try
            value = eval(valStr);
        catch
            value = [];
        end
    else
        value = [];
    end

    if ~isequal(slfeature('MWSValueSource'),2) || ...
            numel(value) < 2 || ~isnumeric(value) || ...
            iscell(value) || isstruct(value)
        container.Items = {};
        return;
    end

    % Create LUT Widget Plug-in client
    lutw = LUTWidget.Connector;
    dimensions = size(value);
    if isvector(value)
        dimensions = numel(value);
    end
    for idx=1:numel(dimensions)
        lutw.Axes(idx).Value = uint8(1:dimensions(idx));
    end
    lutw.Table.Value = value;
    lutw.clearHistory;

    % disable some features
    lutwDisableAxes = LUTWidget.DisableAxesEdit;
    lutw.addFeature(lutwDisableAxes);
    lutwDisableMLBox = LUTWidget.DisableMATLABExpressionBox;
    lutw.addFeature(lutwDisableMLBox);

    lutWidget.Enabled = true;
    addlistener(lutw, 'IsUndoActionAvailable', 'PostSet', @(src, evnt)valueChangeCallback(src, evnt, h, lutw, valueTag));
    lutWidget.Enabled = true;

    lutWidget.Type = 'webbrowser';
    lutWidget.DisableContextMenu = true;
    lutWidget.Tag = 'lutwidget_tag';
    lutWidget.ColSpan = [1 2];
    lutWidget.MinimumSize = [200 300];
    lutWidget.RowSpan = [1 2];
    lutWidget.Visible = true;  

    lutWidget.UserData = lutw;
    lutWidget.Url = lutw.getWidgetUrl();

    container.Items = {lutWidget};
end
%
function valueChangeCallback(~, ~, h, lutw, valueTag)
    if any(strcmp(methods(h), 'isReadonlyProperty'))
        enabled = ~h.isReadonlyProperty('Value');
    else
        enabled = false;
    end

    if ~enabled
        valStr = h.getPropValue('Value');
        try
            lutw.Table.Value = eval(valStr);
        catch
        end
        lutw.clearHistory;
        warndlg(message('Simulink:dialog:NoEditingSupport').getString,...
            [DAStudio.message('dastudio:ddg:DialogTitle'), ' ', h.getDisplayLabel()]);
    else
        % take value from lutViewer and put into dialog widget
        valStr = MxStringConversion.convertToString(lutw.Table.Value);
        dlgs = DAStudio.ToolRoot.getOpenDialogs(h);
        for i=1:numel(dlgs)
            dlgs(i).setWidgetValue(valueTag, valStr);
            dlgs(i).setWidgetDirty(valueTag)
            dlgs(i).enableApplyButton(true);
        end
    end
end

  
% LocalWords:  ddg chk cb postapply
