function mRoot = addEditFrequencyMenu(this)

AxGrid = this.AxesGrid;
mRoot = AxGrid.findMenu('EditFrequencyDialog');  % search for specified menu (HOLD support)
if ~isempty(mRoot)
    return
end

mRoot = uimenu('Parent',this.AxesGrid.UIContextMenu,...
            'callback',{@localOpenFrequencyEditor this},...
            'Label',[getString(message('Controllib:plots:strSpecifyFrequency')),' ...'],...
            'Tag','EditFrequencyDialog','Visible','on');
end

function localOpenFrequencyEditor(~,~,this)
% Create new dialog the first time
if isempty(this.FrequencyEditorDialog)
    % Check if any system in the plot is sparse. Disable auto option if it is
    isAnySystemSparse = any(arrayfun(@(k) issparse(this.Responses(k).DataSrc.Model),1:length(this.Responses)));
    this.FrequencyEditorDialog = controllib.chart.internal.widget.FrequencyEditorDialog(...
        Frequency=this.UserSpecifiedFrequency,EnableAuto=~isAnySystemSparse,EnableRange=~isAnySystemSparse);
    this.FrequencyEditorDialog.Title = ...
        [getString(message('Controllib:plots:strSpecifyFrequency')),': ',this.AxesGrid.Title];

    % Add listener to delete dialog when plot is deleted
    this.FrequencyEditorDialogCleanupListener = ...
        handle.listener(this,'ObjectBeingDestroyed',@(es,ed) delete(this.FrequencyEditorDialog));

    % Add listener to update Time in the plot when OK or Apply button is clicked in the dialog
    addlistener(this.FrequencyEditorDialog,'FrequencyChanged',@(es,ed) localUpdateFrequency(this,es));

    % Make dialog visible
    show(this.FrequencyEditorDialog);
    pack(this.FrequencyEditorDialog);
else
    show(this.FrequencyEditorDialog);
end
end

function localUpdateFrequency(this,es)
% Clear data
this.cleardata('Frequency');

% Update time for each Response
for k = 1:length(this.Responses)
    if ~isempty(es.Frequency)
        if iscell(es.Frequency)
            convFactor = funitconv(char(es.FrequencyUnits),this.Responses(k).Data.FreqUnits);
            w = {convFactor*es.Frequency{1}, convFactor*es.Frequency{2}};
        else
            w = funitconv(char(es.FrequencyUnits),this.Responses(k).Data.FreqUnits)*es.Frequency;
        end
    else
        w = es.Frequency;
    end
    dataFcn = this.Responses(k).DataFcn;
    dataFcn{5} = w;
    feval(dataFcn{:});
end

% Update time focus
if ~isempty(es.Frequency)
    setFreqFocus(this,es.Frequency,es.FrequencyUnits);
else
    % If auto option is chosen, update focus based on the computed focus of each response.
    minFocus = min(arrayfun(@(k) this.Responses(k).Data.Focus(1),1:length(this.Responses)));
    maxFocus = max(arrayfun(@(k) this.Responses(k).Data.Focus(2),1:length(this.Responses)));
    setFreqFocus(this,[minFocus,maxFocus],this.Responses(k).Data.FreqUnits);
end

% Update property
this.UserSpecifiedFrequency = es.Frequency;

% Draw
draw(this);
end