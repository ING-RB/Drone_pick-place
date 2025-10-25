function dialogCallback(dlg, callbackType)
% dialog callback triggerd by Simulink preference dialogs

% Copyright 2022 The MathWorks, Inc.
import simulink.online.internal.keyboard.*;

switch callbackType
    case 'apply'
        handleApply(dlg);
    case 'layoutChange'
        handleLayoutChange(dlg);
    case {'revert', 'close'}
        % clear selection cache
        prefDlg.keyboardSelection([]);
    otherwise
        error([callbackType ' is invalid']);
end

end


function handleApply(dlg)
import simulink.online.internal.keyboard.prefDlg.*;

layoutlabel = dlg.getComboBoxText('KeyboardCombobox');
layout = Util.getLayoutValue(layoutlabel);

optionlabel = dlg.getComboBoxText('OptionCombobox');
option = Util.getOptionValue(layout, optionlabel);

prefVal = layout;
if ~strcmp(option, 'default')
    prefVal = [layout '.' option];
end

simulink.online.internal.keyboard.set(prefVal);
% clear selection cache
keyboardSelection([]);
end

function handleLayoutChange(dlg)
import simulink.online.internal.keyboard.prefDlg.Util;
import simulink.online.internal.keyboard.*;
layoutlabel = dlg.getComboBoxText('KeyboardCombobox');
% cache keyboard selection, so that the option combobox can be updated
% base on the current keyboard selection
prefDlg.keyboardSelection(Util.getLayoutValue(layoutlabel));
end