function mRoot = addEditTimeMenu(this)

% Copyright 1986-2022 The MathWorks, Inc.

AxGrid = this.AxesGrid;
mRoot = AxGrid.findMenu('EditTimeDialog');  % search for specified menu (HOLD support)
if ~isempty(mRoot)
    return
end

mRoot = uimenu('Parent',this.AxesGrid.UIContextMenu,...
            'callback',{@localOpenTimeEditor this},...
            'Label',[getString(message('Controllib:plots:strSpecifyTime')),' ...'],...
            'Tag','EditTimeDialog','Visible','on');
end

function localOpenTimeEditor(~,~,this)
% Create new dialog the first time
if isempty(this.TimeEditorDialog)
    % Check if any system in the plot is sparse. Disable auto option if it is
    isAnySystemSparse = any(arrayfun(@(k) issparse(this.Responses(k).DataSrc.Model),1:length(this.Responses)));
    this.TimeEditorDialog = controllib.chart.internal.widget.TimeEditorDialog(Time=this.UserSpecifiedTime,...
        EnableAuto=~isAnySystemSparse);
    this.TimeEditorDialog.Title = ...
        [getString(message('Controllib:plots:strSpecifyTime')),': ',this.AxesGrid.Title];

    % Add listener to delete dialog when plot is deleted
    this.TimeEditorDialogCleanupListener = ...
        handle.listener(this,'ObjectBeingDestroyed',@(es,ed) delete(this.TimeEditorDialog));

    % Add listener to update Time in the plot when OK or Apply button is clicked in the dialog
    addlistener(this.TimeEditorDialog,'TimeChanged',@(es,ed) localUpdateTime(this,es));

    % Make dialog visible
    show(this.TimeEditorDialog);
    pack(this.TimeEditorDialog);
else
    show(this.TimeEditorDialog);
end
end

function localUpdateTime(this,es)
% Clear data
this.cleardata('Time');

% Update time for each Response
for k = 1:length(this.Responses)
    if ~isempty(es.Time)
        t = tunitconv(es.TimeUnits,this.Responses(k).Data.TimeUnits)*es.Time;
    else
        t = es.Time;
    end
    this.Responses(k).Context.Time = t;
    timeresp(this.Responses(k).DataSrc,this.Tag,this.Responses(k));
end

% Update time focus
if ~isempty(es.Time)
    setTimeFocus(this,es.Time,es.TimeUnits);
else
    % If auto option is chosen, update focus based on the computed focus of each response.
    minFocus = min(arrayfun(@(k) this.Responses(k).Data.Focus(1),1:length(this.Responses)));
    maxFocus = max(arrayfun(@(k) this.Responses(k).Data.Focus(2),1:length(this.Responses)));
    setTimeFocus(this,[minFocus,maxFocus]);
end

% Update property
this.UserSpecifiedTime = es.Time;

% Draw
draw(this);
end