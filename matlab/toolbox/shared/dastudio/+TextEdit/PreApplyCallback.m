function [status, message] = PreApplyCallback(dlg, src)
% Function: PreApplyCallback ==============================================
% Abstract:
%   Main callback entry point for pre-applying the user selections in
%   DAStudio dialogs to rich text annotations.

%   Copyright 2013-2023 The MathWorks, Inc.

    fncList = { ...
        { 'ParaProps',         @paraProps      } ...
        { 'TableInsert',       @tableInsert    } ...
        { 'TableProps',        @tableProps     } ...
        { 'TableCellSplit',    @tableCellSplit } ...        
        { 'TableCellProps',    @tableCellProps } ...
        { 'HyperlinkEdit',     @hyperlinkEdit  } ...
    };

    for index = 1:numel( fncList )
        if strcmp( src.cab.Command, fncList{ index }{ 1 } )
            [status, message] = fncList{ index }{ 2 }( dlg, src.canvas, src.cab );
            break;
        end
    end
end

function [status, message] = paraProps( dlg, canvas, cab )
% Function: paraProps =====================================================
% Abstract:
%   Fills in the paragraph properties CAB from the dialog widgets and 
%   executes the ParaProps cab command 

    assert( strcmp( cab.Command, 'ParaProps' ) );
    
    status  = true;
    message = '';

    cab.Alignment = dlg.getWidgetValue('PARAPROPS_ALIGNMENT');
    cab.Direction = dlg.getWidgetValue('PARAPROPS_DIRECTION');
    
    canvas.executeTextEditCommand( cab );
end    

function [status, message] = tableInsert( dlg, canvas, cab )
% Function: tableInsert ===================================================
% Abstract:
%   Fills in the table insert CAB from the dialog widgets and executes the 
%   TableInsert cab command 

    assert( strcmp( cab.Command, 'TableInsert' ) );
    
    cab.RowSize = dlg.getWidgetValue('TABLEINSERT_ROWS');
    cab.ColSize = dlg.getWidgetValue('TABLEINSERT_COLS');
    cab.AutoFit = dlg.getWidgetValue('TABLEINSERT_AUTOFIT');
    
    if ~(cab.ColSize > 0 && cab.ColSize < 64)
        status  = false;
        message = DAStudio.message('mg:textedit:errOutOfRangeTableColumns');
    elseif ~(cab.RowSize > 0 && cab.RowSize < 128)
        status  = false;
        message = DAStudio.message('mg:textedit:errOutOfRangeTableRows');
    else
        status  = true;
        message = '';
        canvas.executeTextEditCommand( cab );
    end
end

function [status, message] = tableProps( dlg, canvas, cab )
% Function: tableProps ====================================================
% Abstract:
%   Fills in the table properties CAB from the dialog widgets and executes
%   the TableProps cab command 

    assert( strcmp( cab.Command, 'TableProps' ) );

    status  = true;
    message = '';

    colorIndex = dlg.getWidgetValue( 'TABLEPROPS_COLOR' );
    bcUserData = dlg.getUserData( 'TABLEPROPS_COLOR' );

    if colorIndex == TextEdit.TextEditDialog.CUSTOM_COLOR_ITEM
        color = bcUserData.color;
    else
        color = TextEdit.TextEditDialog.getIndexColorName( colorIndex );
    end

    cab.BorderColor = color;
    cab.AutoFit     = dlg.getWidgetValue( 'TABLEPROPS_AUTOFIT' );

    canvas.executeTextEditCommand( cab );
end

function [status, message] = tableCellSplit( dlg, canvas, cab )
% Function: tableProps ====================================================
% Abstract:
%   Fills in the table cell split CAB from the dialog widgets and executes
%   the TableCellSplit cab command 

    assert( strcmp( cab.Command, 'TableCellSplit' ) );
    
    status  = true;
    message = '';

    cab.RowSize = dlg.getWidgetValue('TABLECELLSPLIT_ROWS');
    cab.ColSize = dlg.getWidgetValue('TABLECELLSPLIT_COLS');
    
    canvas.executeTextEditCommand( cab );    
end

function [status, message] = tableCellProps( dlg, canvas, cab )
% Function: tableCellProps ================================================
% Abstract:
%   Fills in the table cell properties CAB from the dialog widgets and 
%   executes the TableCellProps cab command 

    assert( strcmp( cab.Command, 'TableCellProps' ) );
    
    status  = true;
    message = '';

    colorIndex = dlg.getWidgetValue( 'TABLECELLPROPS_COLOR' );
    fcUserData = dlg.getUserData( 'TABLECELLPROPS_COLOR' );

    if colorIndex == TextEdit.TextEditDialog.CUSTOM_COLOR_ITEM
        color = fcUserData.color;
    else
        color = TextEdit.TextEditDialog.getIndexColorName( colorIndex );
    end
    
    cab.FillColor = color;
    cab.HorzAlign = dlg.getWidgetValue('TABLECELLPROPS_HALIGN');
    cab.VertAlign = dlg.getWidgetValue('TABLECELLPROPS_VALIGN');
    cab.Scope     = logical(dlg.getWidgetValue('TABLECELLPROPS_SCOPE'));
    
    canvas.executeTextEditCommand( cab );
end    

function [status, message] = hyperlinkEdit( dlg, canvas, cab )
% Function: hyperlinkEdit==================================================
% Abstract:
%   Fills in the hyperlink edit CAB from the dialog widgets and executes
%   the HyperlinkEdit cab command

    assert( strcmp( cab.Command, 'HyperlinkEdit' ) );
    
    status  = true;
    message = '';

    cab.ReplaceText = dlg.getUserData('HYPERLINK_TEXT').replaceText;
    cab.Text        = dlg.getWidgetValue('HYPERLINK_TEXT');
    cab.Target      = logical(dlg.getWidgetValue('HYPERLINK_TARGET'));
    cab.Code        = dlg.getWidgetValue('HYPERLINK_CODE');
    
    if isempty( cab.Text ) || isempty( cab.Code )
        status      = false;
    else
        canvas.executeTextEditCommand( cab );     
    end
end
