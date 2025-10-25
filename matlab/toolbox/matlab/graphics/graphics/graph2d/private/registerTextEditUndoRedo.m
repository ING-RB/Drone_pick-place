function registerTextEditUndoRedo(hObj)
% This method is undocumented and will be removed in a future release.

%   Copyright 2020 The MathWorks, Inc.

% Adds text edits to the undo/redo stack

%Get the underlying text primitive. Ideally we could listen for the
%String/Editing property changes, this can be done only for labels/titles but not for
%annotations because their corresponding properties are dependent.
hText =  findobjinternal(hObj,'-isa','matlab.graphics.primitive.Text','Editing','on');

if ~isempty(hText)
    hPlotSelect = getPlotSelectMode(hObj);
    hPlotSelect.ModeStateData.OperationData.OldTextValue = string(hText.String);
    %Create a listener to register undo/redo actions for text edits
    hPlotSelect.ModeStateData.TextUndoListener = event.proplistener(hText, findprop(hText,'String'),...
        'PostSet',@(e,d)textEditingCallback(d,hPlotSelect,hObj));
end


%--------------------------------------------------------------------%
function textEditingCallback(d,hMode,hObj)

%If the old value and the new value are NOT the same, add the action to the undo stack 
newVal = string(d.AffectedObject.String);
if ~isequal(newVal,hMode.ModeStateData.OperationData.OldTextValue)
    cmd = matlab.uitools.internal.uiundo.UndoRedoCommandStructureFactory.createUndoRedoStruct(hObj, ...
        hMode,...
        'TextEdit',...
        'String',...
        hMode.ModeStateData.OperationData.OldTextValue,...
        newVal);
    % Register with undo/redo
    uiundo(hMode.FigureHandle,'function',cmd);
    
    % Inform the Live Editor if an annotation text has been edited
    if isa(hObj,'matlab.graphics.shape.internal.OneDimensional')
        matlab.graphics.interaction.generateLiveCode(ancestor(hObj, 'figure'),...
            matlab.internal.editor.figure.ActionID.ANNOTATION_EDITED);
    end
end

%delete the listener
delete(hMode.ModeStateData.TextUndoListener);
hMode.ModeStateData.OperationData.OldTextValue = '';

function hPlotSelect = getPlotSelectMode(hObj)
hPlotEditMode = plotedit(ancestor(hObj,'figure'),'getmode');
hPlotSelect = hPlotEditMode.ModeStateData.PlotSelectMode;



