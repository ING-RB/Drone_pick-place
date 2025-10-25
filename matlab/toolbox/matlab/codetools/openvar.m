function openvar(name, array)
    %OPENVAR Open workspace variable in Variables editor or other graphical editing tool
    %   OPENVAR(NAME) opens the workspace variable NAME in the Variables editor for
    %   graphical editing. Changes that you make to variables in the Variables editor
    %   occur in the current workspace as soon as you enter them. NAME must be a character
    %   vector or string.
    %
    %   In some toolboxes, openvar opens a tool appropriate for viewing or editing objects
    %   indicated by NAME instead of opening the Variables editor.

    %   Copyright 1984-2025 The MathWorks, Inc.


    % Check for custom handling of data types outside variable editor
    if nargin > 1
        try
            % Workaround for tall arrays
            arrayEmpty = isempty(array);
            if ~islogical(logical(arrayEmpty))
                arrayEmpty = false;
            end
        catch
            % Assume empty if there's an error
            arrayEmpty = true;
        end
    else
        arrayEmpty = true;
    end

    % Redirect to other commands based on data type.
    if nargin > 1 && ~arrayEmpty

        % Get list of methods
        methodList = {};
        isMCOS = false;
        if isobject(array) % MCOS object or overridden isobject
            % Methods can be hidden, so get the full methods list from the class
            hClass = metaclass(array);
            isMCOS = ~isempty(hClass);
            if isMCOS
                methodList = {hClass.MethodList.Name}';
            end
        end
        if ~isMCOS && (isa(array, 'handle') || isa(array, 'opaque'))
            % Just get the public list of methods
            methodList = methods(array);
        end

        % Check if object has its own editing utility.
        try %#ok<TRYNC>
            if ismember('dialog', methodList)
                closeClientDocument(name);
                if isa(array, 'Simulink.MCOSValueBaseObject')
                    dialog(array, name, 'DLG_STANDALONE');
                elseif isa(array, 'coder.internal.NamedDialogMixin')
                    dialog(array, name);
                else
                    dialog(array);
                end
                return
            elseif ismember('getDialogSchema', methodList)
                closeClientDocument(name);
                if numel(array)==1
                    DAStudio.Dialog(array, name, 'DLG_STANDALONE');
                    return
                end
            elseif isa(array, 'handle')
                closeClientDocument(name);
                % Use similar logic as in inspect to open the inspector, while we
                % have the variable name available.  Open the inspector for graphics
                % objects (ishghandle) and for timers.
                if all(ishghandle(array)) || isa(array, 'timer') || ...
                        (((all(isa(array, 'handle')) && all(isobject(array)) && all(isvalid(array))) ...
                        || all(ishandle(array))) && useInspectorForObjects())

                    % Check if a graphic object, timer, or a non-java MCOS object is inspected,
                    % the and feature switch for inspector is turned on
                    if all(ishghandle(array)) || (~isjava(array) && isobject(array)) || isa(array, 'timer') && ...
                            ~matlab.graphics.internal.propertyinspector.PropertyInspectorManager.showJavaInspector

                        % Show old java inspector for uicomponents
                        if matlab.graphics.internal.propertyinspector.shouldShowNewInspector(array)

                            % Save the variable name argument to inspect().
                            matlab.graphics.internal.propertyinspector.PropertyInspectorManager.getInstance.setCurrentVarName(name);

                            % Show the inspector
                            matlab.graphics.internal.propertyinspector.propertyinspector('show', array);
                            % By-pass rest of the logic and early return
                            return;
                        end
                    end
                end
            end
        end
    end

    % Check for valid variable name in case openvar was called with
    % incorrect syntax.
    matlab.desktop.vareditor.VariableEditor.checkVariableName(name);

    % Check whether the JAVA VE is available for openvar
    if internal.matlab.desktop_variableeditor.openJavaVE()
        % Error handling.
        matlab.desktop.vareditor.VariableEditor.checkAvailable();

        variable = com.mathworks.mlservices.WorkspaceVariableAdaptor(name);
        com.mathworks.mlservices.MLArrayEditorServices.openVariable(variable);
    else
        % JS Variable Editor opens files from debug workspace
        if nargin > 1
            internal.matlab.desktop_variableeditor.openvarJSD(name, array);
        else
            internal.matlab.desktop_variableeditor.openvarJSD(name);
        end
    end

    % This function will fetch rootApp instance which will
    % instantiate the JS desktop in hidden mode if not already
    % instantiated. This will help with launching variable
    % editor in noDesktop mode
    if ~desktop('-inuse')
        initializeRootApp();
    end
end

function b = forceUnsupportedView(data)
    classname = class(data);
    b = any(strcmp(classname, internal.matlab.variableeditor.MLUnsupportedDataModel.ForceUnsupported));
end

function b = useInspectorForObjects()
    settingName = "UseInspectorForUnregisteredObjects";
    s = settings;
    b = false;
    if hasSetting(s.matlab.desktop.workspace, settingName)
        b = s.matlab.desktop.workspace.UseInspectorForUnregisteredObjects.ActiveValue;
    else
        addSetting(s.matlab.desktop.workspace, settingName);
        s.matlab.desktop.workspace.UseInspectorForUnregisteredObjects.PersonalValue = false;
    end
end

function closeClientDocument(name)
    % Call closeClientDocument on Manager to close the document if opened
    dve = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance(false, true);
    veManager = dve.PeerManager;
    veManager.closeClientDocument(name);
end

% Calling getInstance on RootApp will enable/instantiate the desktop in
% hidden mode if not already instantiated. This is used for opening
% variable editor in noDesktop mode
function initializeRootApp()
    try
        matlab.ui.container.internal.RootApp.getInstance();
    catch e
    end
end
