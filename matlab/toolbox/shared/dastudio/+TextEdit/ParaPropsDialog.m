classdef ParaPropsDialog < TextEdit.TextEditDialog
    methods 
        function dlg = getDialogSchema(obj)
            % General group
            AlignLabel.Type         = 'text';
            AlignLabel.Name         = DAStudio.message('mg:textedit:Alignment');
            AlignLabel.RowSpan      = [1 1];
            AlignLabel.ColSpan      = [1 1];
            
            Align.Type              = 'combobox';
            Align.Tag               = 'PARAPROPS_ALIGNMENT';
            Align.Entries           = { DAStudio.message('mg:textedit:AlignmentLeft'),...
                                        DAStudio.message('mg:textedit:AlignmentCenter'),...
                                        DAStudio.message('mg:textedit:AlignmentRight'),...
                                        DAStudio.message('mg:textedit:AlignmentJustify')};
            Align.Value             = obj.cab.Alignment;
            Align.RowSpan           = [1 1];
            Align.ColSpan           = [2 2];

            DirectionLabel.Type     = 'text';
            DirectionLabel.Name     = DAStudio.message('mg:textedit:Direction');
            DirectionLabel.RowSpan  = [2 2];
            DirectionLabel.ColSpan  = [1 1];
            
            Direction.Type          = 'combobox';
            Direction.Tag           = 'PARAPROPS_DIRECTION';
            Direction.Entries       = { DAStudio.message('mg:textedit:DirectionLeftToRight'),...
                                        DAStudio.message('mg:textedit:DirectionRightToLeft'),...
                                        DAStudio.message('mg:textedit:DirectionAuto')};
            Direction.Value         = obj.cab.Direction;
            Direction.RowSpan       = [2 2];
            Direction.ColSpan       = [2 2];
            
            GeneralGroup.Name       = DAStudio.message('mg:textedit:GeneralGroup');
            GeneralGroup.Type       = 'group';
            GeneralGroup.LayoutGrid = [2 2];
            GeneralGroup.ColStretch = [0 1];
            GeneralGroup.Items      = { AlignLabel, Align, DirectionLabel, Direction };
            
            dlg.DialogTitle         = DAStudio.message('mg:textedit:ParaPropsTitle');
            dlg.DialogTag           = 'PARAPROPS_DIALOG';
            dlg.Items               = { GeneralGroup };
            dlg.StandaloneButtonSet = { 'Ok', 'Cancel'};
            dlg.PreApplyCallback    = 'TextEdit.PreApplyCallback';
            dlg.PreApplyArgs        = { '%dialog', '%source' };
            dlg.CloseCallback       = 'TextEdit.CloseCallback';
            dlg.CloseArgs           = { '%dialog' };
            dlg.Sticky              = true;
         end
    end
end

