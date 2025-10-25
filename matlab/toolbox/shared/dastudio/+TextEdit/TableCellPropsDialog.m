classdef TableCellPropsDialog < TextEdit.TextEditDialog
    methods 
        function dlg = getDialogSchema(obj)
            % Fill color
            FillColorLabel.Type     = 'text';
            FillColorLabel.Name     = DAStudio.message('mg:textedit:Color');
            FillColorLabel.RowSpan  = [1 1];
            FillColorLabel.ColSpan  = [1 1];
            
            FillColor.Type          = 'combobox';
            FillColor.Tag           = 'TABLECELLPROPS_COLOR';
            FillColor.Entries       = TextEdit.TextEditDialog.getColorNameList();
            FillColor.RowSpan       = [1 1];
            FillColor.ColSpan       = [2 2];
            FillColor.Value         = TextEdit.TextEditDialog.getColorNameIndex(obj.cab.FillColor);
            FillColor.MatlabMethod    = 'TextEdit.TableCellPropsDialog_cb';
            FillColor.MatlabArgs      = {'%dialog','doFillColor'};
            fcUserData.index          = FillColor.Value;
            fcUserData.color          = obj.cab.FillColor;
            FillColor.UserData        = fcUserData;
            
            % Fill group
            FillGroup.Name          = DAStudio.message('mg:textedit:FillGroup');
            FillGroup.Type          = 'group';
            FillGroup.LayoutGrid    = [1 2];
            FillGroup.ColStretch    = [0 1];
            FillGroup.Items         = { FillColorLabel, FillColor };
            
            % Horizontal alignment
            HAlignLabel.Type        = 'text';
            HAlignLabel.Name        = DAStudio.message('mg:textedit:HorizontalAlignment');
            HAlignLabel.RowSpan     = [1 1];
            HAlignLabel.ColSpan     = [1 1];
            
            HAlign.Type             = 'combobox';
            HAlign.Tag              = 'TABLECELLPROPS_HALIGN';
            HAlign.Entries          = { DAStudio.message('mg:textedit:AlignmentLeft'),...
                                        DAStudio.message('mg:textedit:AlignmentCenter'),...
                                        DAStudio.message('mg:textedit:AlignmentRight') };
            HAlign.Value            = obj.cab.HorzAlign;
            HAlign.RowSpan          = [1 1];
            HAlign.ColSpan          = [2 2];
            
            % Vertical alignment
            VAlignLabel.Type        = 'text';
            VAlignLabel.Name        = DAStudio.message('mg:textedit:VerticalAlignment');
            VAlignLabel.RowSpan     = [2 2];
            VAlignLabel.ColSpan     = [1 1];
            
            VAlign.Type             = 'combobox';
            VAlign.Tag              = 'TABLECELLPROPS_VALIGN';
            VAlign.Entries          = { DAStudio.message('mg:textedit:AlignmentTop'),...
                                        DAStudio.message('mg:textedit:AlignmentMiddle'),...
                                        DAStudio.message('mg:textedit:AlignmentBottom') };
            VAlign.Value            = obj.cab.VertAlign;
            VAlign.RowSpan          = [2 2];
            VAlign.ColSpan          = [2 2];
            
            % Alignment group            
            AlignGroup.Name         = DAStudio.message('mg:textedit:AlignmentGroup');
            AlignGroup.Type         = 'group';
            AlignGroup.LayoutGrid   = [2 2];
            AlignGroup.ColStretch   = [0 1];
            AlignGroup.Items        = { HAlignLabel, HAlign, VAlignLabel, VAlign };

            ScopeGroup.Name         = DAStudio.message('mg:textedit:ScopeGroup');
            ScopeGroup.Type         = 'radiobutton';
            ScopeGroup.Tag          = 'TABLECELLPROPS_SCOPE';
            ScopeGroup.Entries      = { DAStudio.message('mg:textedit:ScopeTable'),...
                                        DAStudio.message('mg:textedit:ScopeCell') };
            ScopeGroup.Value        = obj.cab.Scope + 0;
            ScopeGroup.RowSpan      = [3 3];
            ScopeGroup.ColSpan      = [1 1];
            
            dlg.DialogTitle         = DAStudio.message('mg:textedit:TableCellPropsTitle');
            dlg.DialogTag           = 'TABLECELLPROPS_DIALOG';
            dlg.Items               = { FillGroup, AlignGroup, ScopeGroup };
            dlg.StandaloneButtonSet = { 'Ok', 'Cancel'};
            dlg.PreApplyCallback    = 'TextEdit.PreApplyCallback';
            dlg.PreApplyArgs        = {'%dialog', '%source'};
            dlg.CloseCallback       = 'TextEdit.CloseCallback';
            dlg.CloseArgs           = {'%dialog'};
            dlg.Sticky              = true;
         end
    end
end

