function func = Actions( funcname )
    % load the icons needed for these schema elements.

    im = DAStudio.IconManager;
    if ~im.hasIcon( 'Studio:New' )
        root = [matlabroot '/toolbox/shared/dastudio/resources/SLEditor/'];

        im.addFileToIcon( 'Studio:New', [root 'New_24.png']);
        im.addFileToIcon( 'Studio:Open', [root 'Open.svg']);
        im.addFileToIcon( 'Studio:Save', [root 'Save.svg']);
        im.addFileToIcon( 'Studio:Print', [root 'Print_24.png']);
        im.addFileToIcon( 'Studio:Undo', [root 'Undo_24.png']);
        im.addFileToIcon( 'Studio:Redo', [root 'Redo_24.png']);
        im.addFileToIcon( 'Studio:Cut', [root 'Cut_24.png']);
        im.addFileToIcon( 'Studio:Copy', [root 'Copy_24.png']);
        im.addFileToIcon( 'Studio:Paste', [root 'Paste_24.png']);
    end 
    
    % initialize function list
    persistent actionMap;
    if isempty(actionMap)
        actionMap = initializeActions;
    end
    
    func = {}; %#ok<NASGU>
    if actionMap.isKey( funcname )
        func = actionMap( funcname );
    else
        func = DAStudio.makeCallback( funcname, @act_ActionNotFound );
    end
end

function schema = act_ActionNotFound( funcname, ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:ActionNotFound';
    schema.label    = DAStudio.message( 'dastudio:studio:ActionNotFound' );
    schema.userdata = funcname;
    schema.callback = @cbk_ActionNotFound;
end

function cbk_ActionNotFound( cbinfo )
    funcname = cbinfo.userdata;
    warning( 'Action ''%s'' not found.', funcname );
end

function schema = act_HiddenSchema( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:HiddenSchema';
    schema.label    = DAStudio.message( 'dastudio:studio:HiddenSchema' );
    schema.state = 'Hidden';
end

function actionMap = initializeActions
    actionMap = containers.Map;
    
    actionMap('New') = @act_New;
    actionMap('Open') = @act_Open;
    actionMap('CloseTab') = @act_CloseTab;
    actionMap('CloseOtherTabs') = @act_CloseOtherTabs;
    actionMap('CloseAllTabs') = @act_CloseAllTabs;
    actionMap('CloseWindow') = @act_CloseWindow;
    actionMap('CloseAllWindows') = @act_CloseAllWindows;
    actionMap('Save') = @act_Save;
    actionMap('SaveAs') = @act_SaveAs;
    actionMap('SaveStudioLayout') = @act_SaveStudioLayout;
    actionMap('PrinterSetup') = @act_PrinterSetup;
    actionMap('Print') = @act_Print;
    actionMap('ExitMatlab') = @act_ExitMatlab;
    actionMap('Undo') = @act_Undo;
    actionMap('Redo') = @act_Redo;
    actionMap('Cut') = @act_Cut;
    actionMap('Copy') = @act_Copy;
    actionMap('Paste') = @act_Paste;
    actionMap('Clear') = @act_Clear;
    actionMap('Delete') = @act_Delete;     
    actionMap('About') = @act_About;
    actionMap('GettingStarted') = @act_GettingStarted;
    actionMap('DockWidgetSchema') = @act_DockWidgetSchema;
    actionMap('TabWidgetSchema') = @act_TabWidgetSchema;
    actionMap('StatusWidgetSchema') = @act_StatusWidgetSchema;
    actionMap('DummyWidgetSchema') = @act_DummyWidgetSchema;
    actionMap('HiddenSchema') = @act_HiddenSchema;
end

function schema = act_New( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:New';
    schema.label    = DAStudio.message( 'dastudio:studio:New' );
    schema.icon = schema.tag;
    schema.accelerator = 'Ctrl+N';
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
end

function schema = act_Open( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:Open';
    schema.label    = DAStudio.message( 'dastudio:studio:Open' );
    schema.icon = schema.tag;
    schema.accelerator = 'Ctrl+O';
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
end

%--- CloseTab ---------------------------------------------------
function schema = act_CloseTab( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:CloseTab';
    schema.label    = DAStudio.message( 'dastudio:studio:CloseTab' );
    schema.callback = @DAStudio.Callbacks.CloseTab;
end	

function schema = act_CloseOtherTabs( cbinfo )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:CloseOtherTabs';
    schema.label    = DAStudio.message( 'dastudio:studio:CloseOtherTabs' );
    if cbinfo.studio.getTabCount > 1
        schema.state = 'Enabled';
    else
        schema.state = 'Disabled';
    end
    schema.callback = @DAStudio.Callbacks.CloseOtherTabs;
end

function schema = act_CloseAllTabs( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:CloseAllTabs';
    schema.label    = DAStudio.message( 'dastudio:studio:CloseAllTabs' );
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
end

function schema = act_CloseWindow( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:CloseWindow';
    schema.label    = DAStudio.message( 'dastudio:studio:CloseWindow' );
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
end

function schema = act_CloseAllWindows( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:CloseAllWindows';
    schema.label    = DAStudio.message( 'dastudio:studio:CloseAllWindows' );
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
end		

% --- Save ------------------------------------------------------
function schema = act_Save( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:Save';
    schema.label    = DAStudio.message( 'dastudio:studio:Save' );
    schema.icon = schema.tag;
    schema.accelerator = 'Ctrl+S';
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
end

% --- SaveAs ----------------------------------------------------
function schema = act_SaveAs( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:SaveAs';
    schema.label    = DAStudio.message( 'dastudio:studio:SaveAs' );
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;%@DAStudio.Callbacks.Save;
end

function schema = act_SaveStudioLayout( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:SaveStudioLayout';
    schema.label    = DAStudio.message( 'dastudio:studio:SaveStudioLayout' );
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;            
end

% --- Page Setup -----------------------------------------------
function schema = act_PrinterSetup( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:PrinterSetup';
    schema.label    = DAStudio.message( 'dastudio:studio:PrinterSetup' );
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
end

% --- Print -----------------------------------------------------
function schema = act_Print( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:Print';
    schema.label    = DAStudio.message( 'dastudio:studio:Print' );
    schema.icon = schema.tag;
    schema.accelerator = 'Ctrl+P';
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
end

% --- Exit Matlab -----------------------------------------------
function schema = act_ExitMatlab( ~ )
    schema = DAStudio.ActionSchema;

    %schema.label = DAStudio.message('Shared:studio:msgExitMatlab');
    schema.tag      = 'Studio:ExitMatlab';
    schema.label    = DAStudio.message( 'dastudio:studio:ExitMatlab' );
    schema.accelerator = 'Ctrl+Q';
    schema.callback = @DAStudio.Callbacks.ExitMatlab;
end

% --- Undo -----------------------------------------------------
function schema = act_Undo( cbinfo )
    schema = DAStudio.ActionSchema;
    schema.tag = 'Studio:Undo';
    schema.icon = schema.tag;
    schema.accelerator = 'Ctrl+Z';
    schema.callback = @DAStudio.Callbacks.Undo;

    if( cbinfo.domain.canUndo( cbinfo.isContextMenu ) )
        schema.label = DAStudio.message('dastudio:studio:Undo',cbinfo.domain.undoDescription( cbinfo.isContextMenu ));
        schema.state = 'Enabled';
    else
        schema.label = DAStudio.message('dastudio:studio:CantUndo');
        schema.state = 'Disabled';
    end
end

% --- Redo ------------------------------------------------------
function schema = act_Redo( cbinfo )
    schema = DAStudio.ActionSchema;
    schema.tag = 'Studio:Redo';
    schema.icon = schema.tag;
    schema.accelerator = 'Ctrl+Y';
    schema.callback = @DAStudio.Callbacks.Redo;

    if( cbinfo.domain.canRedo( cbinfo.isContextMenu ) )
        schema.label = DAStudio.message('dastudio:studio:Redo',cbinfo.domain.redoDescription( cbinfo.isContextMenu ));
        schema.state = 'Enabled';
    else
        schema.label = DAStudio.message('dastudio:studio:CantRedo');
        schema.state = 'Disabled';
    end
end

% --- Cut -------------------------------------------------------
function schema = act_Cut( cbinfo )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:Cut';
    schema.label    = DAStudio.message( 'dastudio:studio:Cut' );
    schema.icon = schema.tag;
    schema.accelerator = 'Ctrl+X';
    schema.callback = @DAStudio.Callbacks.Cut;
    if cbinfo.domain.canCut( cbinfo.isContextMenu ) 
        schema.state = 'Enabled';
    else
        schema.state = 'Disabled';
    end
end

% --- Copy ----------------------------------------------------------------
function schema = act_Copy( cbinfo )
    schema = DAStudio.ActionSchema;
    schema.tag = 'Studio:Copy';
    schema.icon     = schema.tag;
    schema.label    = DAStudio.message( 'dastudio:studio:Copy' );
    schema.accelerator = 'Ctrl+C';
    schema.callback = @DAStudio.Callbacks.Copy;
    if cbinfo.domain.canCopy( cbinfo.isContextMenu ) 
        schema.state = 'Enabled';
    else
        schema.state = 'Disabled';
    end
end

% --- Paste -----------------------------------------------------
function schema = act_Paste( cbinfo )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:Paste';
    schema.label    = DAStudio.message( 'dastudio:studio:Paste' );
    schema.icon = schema.tag;
    schema.accelerator = 'Ctrl+V';
    schema.callback = @DAStudio.Callbacks.Paste;
    if cbinfo.domain.canPaste( cbinfo.isContextMenu ) 
        schema.state = 'Enabled';
    else
        schema.state = 'Disabled';
    end
end

% --- Clear -----------------------------------------------------
function schema = act_Clear( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:Clear';
    schema.label    = DAStudio.message( 'dastudio:studio:Clear' );
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
    % We are not sure what to do with this, so I am hiding it for
    % now.
    schema.state = 'Hidden';
end

 % --- Delete ---------------------------------------------------
function schema = act_Delete( cbinfo )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:Delete';
    schema.label    = DAStudio.message( 'dastudio:studio:Delete' );
    schema.accelerator = 'delete';
    
    if ~cbinfo.domain.canDelete( cbinfo.isContextMenu )
        schema.state = 'Disabled';
    end
    
    schema.callback = @DAStudio.Callbacks.Delete;
end       

% --- About -----------------------------------------------------
function schema = act_About( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:About';
    schema.label    = DAStudio.message( 'dastudio:studio:About' );
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
end

% --- Getting Started -------------------------------------------
function schema = act_GettingStarted( ~ )
    schema = DAStudio.ActionSchema;
    schema.tag      = 'Studio:GettingStarted';
    schema.label    = DAStudio.message( 'dastudio:studio:GettingStarted' );
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
end

% --- DockWidget -------------------------------------------
function schema = act_DockWidgetSchema( widget, cbinfo )
    schema = DAStudio.ToggleSchema;
    schema.label = widget.getName;
    schema.tag = [ 'Studio:View:' schema.label ];
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
    schema.checked = cbinfo.studio.getMenuChecked(schema.tag);            
end

% --- TabWidget -------------------------------------------
function schema = act_TabWidgetSchema( widget, cbinfo )
    schema = DAStudio.ActionSchema;
    schema.label = widget.getName;
    schema.tag = [ 'Studio:View:' schema.label ];
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback; 
    schema.checked = cbinfo.studio.getMenuChecked(schema.tag);     
end

% --- StatusWidget -------------------------------------------
function schema = act_StatusWidgetSchema( widget, cbinfo )
    schema = DAStudio.ToggleSchema;
    schema.label = widget.getName;
    schema.tag = [ 'Studio:View:' schema.label ];
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
    schema.checked = cbinfo.studio.getMenuChecked( schema.tag );            
end

% --- Dummy View Schema ----------------------------------------
function schema = act_DummyWidgetSchema( name, ~ )
    schema = DAStudio.ActionSchema;
    schema.label = name;
    schema.tag = [ 'Studio:View:' schema.label ];
    schema.userdata = schema.tag;
    schema.callback = DAStudio.getDefaultCallback;
    schema.state = 'Disabled';            
end			

