classdef TablePropsDialog < TextEdit.TextEditDialog 
    methods 
        function dlg = getDialogSchema(obj)
            % Border Color
            BorderColorLabel.Type       = 'text';
            BorderColorLabel.Name       = DAStudio.message('mg:textedit:Color');
            BorderColorLabel.RowSpan    = [1 1];
            BorderColorLabel.ColSpan    = [1 1];
            
            BorderColor.Type            = 'combobox';
            BorderColor.Tag             = 'TABLEPROPS_COLOR';
            BorderColor.Entries         = TextEdit.TextEditDialog.getColorNameList();
            BorderColor.RowSpan         = [1 1];
            BorderColor.ColSpan         = [2 2];
            BorderColor.Value           = TextEdit.TextEditDialog.getColorNameIndex(obj.cab.BorderColor);
            BorderColor.MatlabMethod    = 'TextEdit.TablePropsDialog_cb';
            BorderColor.MatlabArgs      = {'%dialog','doBorderColor'};
            bcUserData.index            = BorderColor.Value;
            bcUserData.color            = obj.cab.BorderColor;
            BorderColor.UserData        = bcUserData;
            
            % Border group
            BorderGroup.Name            = DAStudio.message('mg:textedit:BorderGroup');
            BorderGroup.Type            = 'group';
            BorderGroup.LayoutGrid      = [4 2];
            BorderGroup.ColStretch      = [0 1];
            BorderGroup.Items           = { BorderColorLabel, BorderColor };
            
            % AutoFit group            
            AutoFitGroup.Name           = DAStudio.message('mg:textedit:AutoFitGroup');
            AutoFitGroup.Type           = 'radiobutton';
            AutoFitGroup.Tag            = 'TABLEPROPS_AUTOFIT';
            AutoFitGroup.Entries        = { DAStudio.message('mg:textedit:AutoFitWindow'),...
                                            DAStudio.message('mg:textedit:AutoFitContents'),...
                                            DAStudio.message('mg:textedit:AutoFitFixed') };
            AutoFitGroup.Value          = obj.cab.AutoFit;
            AutoFitGroup.RowSpan        = [2 2];
            AutoFitGroup.ColSpan        = [1 1];

            dlg.DialogTitle             = DAStudio.message('mg:textedit:TablePropsTitle');            
            dlg.DialogTag               = 'TABLEPROPS_DIALOG';            
            dlg.Items                   = { BorderGroup, AutoFitGroup };
            dlg.StandaloneButtonSet     = { 'Ok', 'Cancel'};
            dlg.PreApplyCallback        = 'TextEdit.PreApplyCallback';
            dlg.PreApplyArgs            = {'%dialog', '%source'};
            dlg.CloseCallback           = 'TextEdit.CloseCallback';
            dlg.CloseArgs               = {'%dialog'};
            dlg.Sticky                  = true;
         end
    end
end

