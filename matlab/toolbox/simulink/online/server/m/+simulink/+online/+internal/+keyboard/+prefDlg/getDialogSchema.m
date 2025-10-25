function keyboardGroup = getDialogSchema()
% function to create keyboard setting panel for Simulink preference dialog

% Copyright 2022 The MathWorks, Inc.

import simulink.online.internal.keyboard.prefDlg.*;


% see keyboardSelection for details

tempLayout = keyboardSelection();
if ~isempty(tempLayout)  % has temporary selection, meaning user changed the settings
    currOption = Util.getDefaultOption(tempLayout);
    currLayout = tempLayout;
else % new dialog, just need to reflect the os setting status
    currLayout = slonline.getXKBMapLayout();
    currOption = slonline.getXKBMapVariant();
    if isempty(currOption) % empty value in os setting means default in menu
        currOption = 'default';
    end
end


[oEntries, oLabel] = Util.getOptionEntriesAndLabel(currLayout, currOption);

keyboardLabel.Type = 'text';
keyboardLabel.Buddy = 'KeyboardCombobox';
keyboardLabel.Name = DAStudio.message('SimulinkOnline:ui:Keyboard');
keyboardLabel.ToolTip = DAStudio.message('SimulinkOnline:ui:KeyboardTooltip');
keyboardLabel.RowSpan = [1 1];
keyboardLabel.ColSpan = [1 1];

keyboardCombo.Type = 'combobox';
keyboardCombo.Entries = Util.getLayoutEntries();
keyboardCombo.Tag = 'KeyboardCombobox';
keyboardCombo.Value = Util.getLayoutLabel(currLayout);
keyboardCombo.MatlabMethod = 'simulink.online.internal.keyboard.prefDlg.dialogCallback';
keyboardCombo.MatlabArgs = {'%dialog', 'layoutChange'};
keyboardCombo.DialogRefresh = true;
keyboardCombo.RowSpan = [1 1];
keyboardCombo.ColSpan = [2 2];

optionLabel.Type = 'text';
optionLabel.Buddy = 'OptionCombobox';
optionLabel.Name = DAStudio.message('SimulinkOnline:ui:KeyboardOption');
optionLabel.ToolTip = DAStudio.message('SimulinkOnline:ui:KeyboardOptionTooltip');
optionLabel.RowSpan = [2 2];
optionLabel.ColSpan = [1 1];

optionCombo.Type = 'combobox';
optionCombo.Entries = oEntries;
optionCombo.Tag = 'OptionCombobox';
optionCombo.Value = oLabel;
optionCombo.RowSpan = [2 2];
optionCombo.ColSpan = [2 2];


keyboardGroup.Type = 'group';
keyboardGroup.LayoutGrid = [2 2];
keyboardGroup.ColStretch = [0 1];  
keyboardGroup.Name = DAStudio.message('SimulinkOnline:ui:KeyboardPanelDesc');
keyboardGroup.Items = {
    keyboardLabel, keyboardCombo, ...
    optionLabel, optionCombo};

end