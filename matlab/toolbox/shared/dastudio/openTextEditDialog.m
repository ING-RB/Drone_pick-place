function openTextEditDialog( canvas, cab )
% Function: openTextEditDialog ============================================
% Abstract:
%   Main entry point for launching all the modal dialogs needed for rich 
%   text annotations in both Simulink and Stateflow.
%
    fncList = { ...
        { 'FontProps',         @fontProps      } ...
        { 'FontForeColor',     @fontForeColor  } ...
        { 'FontBackColor',     @fontBackColor  } ...
        { 'ParaProps',         @paraProps      } ...
        { 'ImageInsert',       @imageInsert    } ...
        { 'TableInsert',       @tableInsert    } ...
        { 'TableProps',        @tableProps     } ...
        { 'TableCellSplit',    @tableCellSplit } ...
        { 'TableCellProps',    @tableCellProps } ...
        { 'HyperlinkEdit',     @hyperlinkEdit  } ...
    };

    for index = 1:numel( fncList )
        if strcmp( cab.Command, fncList{ index }{ 1 } )
            try
                fncList{ index }{ 2 }( canvas, cab );
            catch
                % The timer above will fire and run inside an unpredictable 
                % MATLAB function. Squash exceptions to avoid propagating them
                % into random code.
            end
            break;
        end
    end
end

function fontProps( canvas, cab )
% Function: fontProps =====================================================
% Abstract: 
%   Launches the Qt font picker dialog. It will execute the FontProps cab
%   command if the user clicks OK for the font dialog.

    font        = MG2.Font;
    font.Family = cab.Family;
    font.Weight = cab.Weight;
    font.Style  = cab.Style;
    font.Size   = cab.Size;
    font = GLUE2.Util.invokeFontPicker(font);
    if font.isValid()
        cab.Family  = font.Family;
        cab.Weight  = font.Weight;
        cab.Style   = font.Style;
        cab.Size    = font.Size;
        canvas.executeTextEditCommand(cab);
    end
end

function fontForeColor( canvas, cab )
% Function: fontForeColor =================================================
% Abstract:
%   Launches the Qt color picker dialog. It will execute the FontForeColor
%   cab command if the user clicks OK for the color dialog.

    if ~isequal(cab.Color,[ 0 0 0 0 ])
        color = GLUE2.Util.invokeColorPicker(cab.Color);
    else
        color = GLUE2.Util.invokeColorPicker;
    end

    if ~isempty(color)
        cab.Color = color;
        canvas.executeTextEditCommand(cab);                
    end
end    

function fontBackColor( canvas, cab )
% Function: fontBackColor =================================================
% Abstract:
%   Launches the Qt color picker dialog. It will execute the BackForeColor
%   cab command if the user clicks OK for the color dialog.

    if ~isequal(cab.Color,[ 0 0 0 0 ])
        color = GLUE2.Util.invokeColorPicker(cab.Color);
    else
        color = GLUE2.Util.invokeColorPicker;
    end

    if ~isempty(color)
        cab.Color = color;                
        canvas.executeTextEditCommand(cab);                
    end
end

function paraProps( canvas, cab )
% Function: paraProps =====================================================
% Abstract:
%   Launches the DAStudio paragraph properties dialog. The PreApplyCallback
%   of this dialog will execute the ParaProps cab command.

    assert( strcmp( cab.Command, 'ParaProps' ) );
    
    hDlg = TextEdit.ParaPropsDialog;
    hDlg.canvas = canvas;
    hDlg.cab = cab;
    dlg = DAStudio.Dialog( hDlg );

    % Block execution until the dialog is closed.
    waitfor( dlg, 'dialogTag', '' );
end    
            
function imageInsert( canvas, cab )
% Function: imageInsert ===================================================
% Abstract:
%   Launches the system file open dialog. It will execute the ImageInsert
%   cab command if the user selects one or more image files and clicks OK. 

    assert( strcmp( cab.Command, 'ImageInsert' ) );
    
    [filenames, cancelled]= uigetimagefile('MultiSelect', 'on');
    if ~cancelled
        if ~iscell(filenames)
            cab.FileNames = { filenames };
        else
            cab.FileNames = filenames; 
        end
        canvas.executeTextEditCommand(cab);
    end
end    
            
function tableInsert( canvas, cab )
% Function: tableInsert ===================================================
% Abstract:
%   Launches the DAStudio table insert dialog. The PreApplyCallback of this
%   dialog will execute the TableInsert cab command.

    assert( strcmp( cab.Command, 'TableInsert' ) );
    
    hDlg = TextEdit.TableInsertDialog;
    hDlg.canvas = canvas;
    hDlg.cab = cab;
    dlg = DAStudio.Dialog( hDlg );

    % Block execution until the dialog is closed.
    waitfor( dlg );
end    

function tableProps( canvas, cab )
% Function: tableProps ====================================================
% Abstract:
%   Launches the DAStudio table properties dialog. The PreApplyCallback of
%   this dialog will execute the TableProps cab command.

    assert( strcmp( cab.Command, 'TableProps' ) );
    
    hDlg = TextEdit.TablePropsDialog;
    hDlg.canvas = canvas;
    hDlg.cab = cab;
    dlg = DAStudio.Dialog( hDlg );

    % Block execution until the dialog is closed.
    waitfor( dlg );
end    

function tableCellSplit( canvas, cab )
% Function: tableCellProps ================================================
% Abstract:
%   Launches the DAStudio table cell split dialog. The PreApplyCallback
%   of this dialog will execute the TableCellSplit cab command.

    assert( strcmp( cab.Command, 'TableCellSplit' ) );

    hDlg = TextEdit.TableCellSplitDialog;
    hDlg.canvas = canvas;
    hDlg.cab = cab;
    dlg = DAStudio.Dialog( hDlg );

    % Block execution until the dialog is closed.
    waitfor( dlg );
end
 
 function tableCellProps( canvas, cab )
% Function: tableCellProps ================================================
% Abstract:
%   Launches the DAStudio table cell properties dialog. The PreApplyCallback
%   of this dialog will execute the TableCellProps cab command.

    assert( strcmp( cab.Command, 'TableCellProps' ) );
    
    hDlg = TextEdit.TableCellPropsDialog;
    hDlg.canvas = canvas;
    hDlg.cab = cab;
    dlg = DAStudio.Dialog( hDlg );

    % Block execution until the dialog is closed.
    waitfor( dlg );
 end
            
function hyperlinkEdit( canvas, cab )
% Function: hyperlinkEdit==================================================
% Abstract:
%   Launches the DAStudio hyperlink edit dialog. The PreApplyCallback
%   of this dialog will execute the HyperlinkEdit cab command.

    assert( strcmp( cab.Command, 'HyperlinkEdit' ) );
    
    hDlg = TextEdit.HyperlinkEditDialog;
    hDlg.canvas = canvas;
    hDlg.cab = cab;
    dlg = DAStudio.Dialog( hDlg );
    
    % move the focus to the code editor if the text editor is empty
    if isempty( dlg.getWidgetValue('HYPERLINK_TEXT') )
        dlg.setFocus( 'HYPERLINK_CODE' );
    end
    
    % Block execution until the dialog is closed.
    waitfor( dlg );
 end    
