classdef HyperlinkEditDialog < TextEdit.TextEditDialog
    methods 
        function dlg = getDialogSchema(obj)
            TextLabel.Name                  = DAStudio.message('mg:textedit:Display');
            TextLabel.Type                  = 'text';
            TextLabel.WordWrap              = false;
            TextLabel.Tag                   = 'TextLabel';
            TextLabel.RowSpan               = [1 1];
            TextLabel.ColSpan               = [1 1];  

            TextEdit.Name                   = '';
            TextEdit.Tag                    = 'TextEdit';
            TextEdit.Type                   = 'edit';
            TextEdit.RowSpan                = [1 1];
            TextEdit.ColSpan                = [2 2];
            TextEdit.Tag                    = 'HYPERLINK_TEXT';
            textud.createText               = isempty(obj.cab.Text);
            textud.replaceText              = isempty(obj.cab.Text);
            textud.text                     = obj.cab.Text;
            TextEdit.UserData               = textud;
            TextEdit.Value                  = obj.cab.Text;
            TextEdit.RespondsToTextChanged  = true;
            TextEdit.MatlabMethod           = 'TextEdit.HyperlinkEditDialog_cb';
            TextEdit.MatlabArgs             = {'%dialog','doTextEdit'};

            TargetLabel.Name                = DAStudio.message('mg:textedit:Target');
            TargetLabel.Type                = 'text';
            TargetLabel.WordWrap            = false;
            TargetLabel.Tag                 = 'AddressLabel';
            TargetLabel.RowSpan             = [3 3];
            TargetLabel.ColSpan             = [1 1];  

            TargetRadio.Type                = 'radiobutton';
            TargetRadio.Name                = '';
            TargetRadio.Tag                 = 'HYPERLINK_TARGET';
            TargetRadio.Entries             = { DAStudio.message('mg:textedit:HyperlinkURLAddress'), ...
                                                DAStudio.message('mg:textedit:HyperlinkMatlabCode') };
            TargetRadio.Value               = obj.cab.Target + 0;
            
            CodeLabel.Name                  = DAStudio.message('mg:textedit:Code');
            CodeLabel.Type                  = 'text';
            CodeLabel.WordWrap              = false;
            CodeLabel.Tag                   = 'CodeLabel';
            CodeLabel.RowSpan               = [4 4];
            CodeLabel.ColSpan               = [1 1];  
            
            CodeEdit.Name                   = '';
            CodeEdit.Tag                    = 'CodeEdit';
            CodeEdit.Type                   = 'editarea';
            CodeEdit.RowSpan                = [4 4];
            CodeEdit.ColSpan                = [2 2];
            CodeEdit.Tag                    = 'HYPERLINK_CODE';
            CodeEdit.Value                  = obj.cab.Code;
            CodeEdit.RespondsToTextChanged  = true;
            CodeEdit.MatlabMethod           = 'TextEdit.HyperlinkEditDialog_cb';
            CodeEdit.MatlabArgs             = {'%dialog','doCodeEdit'};
            
            LinkToGroup.Type                = 'group';
            LinkToGroup.Name                = DAStudio.message('mg:textedit:LinkToGroup');
            LinkToGroup.Flat                = false;
            LinkToGroup.Items               = { TextLabel, TextEdit };
            LinkToGroup.ToolTip             = DAStudio.message('mg:textedit:LinkToGroup');
            LinkToGroup.LayoutGrid          = [2 2];
            LinkToGroup.ColStretch          = [0 1];
            LinkToGroup.RowSpan             = [1 1];
            LinkToGroup.Tag                 = 'LinkToGroup';

            LinkGroup.Type                  = 'group';
            LinkGroup.Name                  = DAStudio.message('mg:textedit:LinkGroup');
            LinkGroup.Flat                  = false;
            LinkGroup.Items                 = { TargetLabel, TargetRadio, CodeLabel, CodeEdit };
            LinkGroup.ToolTip               = DAStudio.message('mg:textedit:LinkGroup');
            LinkGroup.LayoutGrid            = [2 2];
            LinkGroup.ColStretch            = [0 1];
            LinkGroup.RowSpan               = [2 2];
            LinkGroup.Tag                   = 'LinkGroup';
            
            dlg.DialogTitle                 = DAStudio.message('mg:textedit:HyperlinkEditTitle');
            dlg.DialogTag                   = 'HYPERLINK_DIALOG';
            dlg.Items                       = { LinkToGroup, LinkGroup };
            dlg.LayoutGrid                  = [4 2];            
            dlg.StandaloneButtonSet         = { 'Ok', 'Cancel'};
            dlg.PreApplyCallback            = 'TextEdit.PreApplyCallback';
            dlg.PreApplyArgs                = {'%dialog', '%source'};
            dlg.CloseCallback               = 'TextEdit.CloseCallback';
            dlg.CloseArgs                   = {'%dialog'};
            dlg.Sticky                      = true;
         end
    end
end
