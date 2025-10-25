classdef TableCellSplitDialog < TextEdit.TextEditDialog
%

%   Copyright 2014-2023 The MathWorks, Inc.

    methods 
        function dlg = getDialogSchema(obj)
            RowLabel.Type           = 'text';
            RowLabel.Name           = DAStudio.message('mg:textedit:NumberOfRows');
            RowLabel.RowSpan        = [1 1];
            RowLabel.ColSpan        = [1 1];

            RowSize.Type            = 'spinbox';
            RowSize.Tag             = 'TABLECELLSPLIT_ROWS';
            RowSize.RowSpan         = [1 1];
            RowSize.ColSpan         = [2 2];
            RowSize.Value           = obj.cab.RowSize;
            RowSize.Range           = [1 127];

            ColLabel.Type           = 'text';
            ColLabel.Name           = DAStudio.message('mg:textedit:NumberOfCols');
            ColLabel.RowSpan        = [2 2];
            ColLabel.ColSpan        = [1 1];

            ColSize.Type            = 'spinbox';
            ColSize.Tag             = 'TABLECELLSPLIT_COLS';
            ColSize.RowSpan         = [2 2];
            ColSize.ColSpan         = [2 2];
            ColSize.Value           = obj.cab.ColSize;
            ColSize.Range           = [1 63];
            
            SizeGroup.Name          = DAStudio.message('mg:textedit:TableCellSizeGroup');
            SizeGroup.Type          = 'group';
            SizeGroup.LayoutGrid    = [2 2];
            SizeGroup.ColStretch    = [0 1];
            SizeGroup.Items         = {RowLabel, RowSize, ColLabel, ColSize};

            dlg.DialogTitle         = DAStudio.message('mg:textedit:TableCellSplitTitle');
            dlg.DialogTag           = 'TABLECELLSPLIT_DIALOG';
            dlg.Items               = { SizeGroup };
            dlg.StandaloneButtonSet = { 'Ok', 'Cancel' };
            dlg.PreApplyCallback    = 'TextEdit.PreApplyCallback';
            dlg.PreApplyArgs        = { '%dialog', '%source' };
            dlg.CloseCallback       = 'TextEdit.CloseCallback';
            dlg.CloseArgs           = { '%dialog' };
            dlg.Sticky              = true;
         end
    end
end
