function openvarJSD(name, array)
    % OPENVARJSD opens workspace variable in JSD Variable Editor
    
    %   Copyright 2023-2024 The MathWorks, Inc.
    workspace = 'debug';
    name = char(name);
    baseVariableName = matlab.internal.datatoolsservices.getBaseVariableName(name);
    variableExists = evalin(workspace, ['builtin(''exist'',''' baseVariableName ''',''var'')']);
    if ~variableExists
        currentFolder = string(fullfile(matlabroot, 'toolbox', 'matlab', 'datatools', 'desktop_variableeditor', 'matlab', '+internal', '+matlab', '+desktop_variableeditor'));
        matlab.lang.internal.maskFoldersFromStack(currentFolder);
        cleanupMaskedFolders = onCleanup(@()matlab.lang.internal.unmaskFoldersFromStack(currentFolder));
        error(message('MATLAB:openvar:NonExistentVariable',name));
    end
    
    if nargin > 1 && ~isempty(array)
        data = array;
    else
        data = evalin(workspace, name);
    end
    
    userContext = 'MOTW';
    % Create a Document for the new variable
    dve = internal.matlab.desktop_variableeditor.DesktopVariableEditor.getInstance(false, true);
    if builtin('exist','internal.matlab.desktop_variableeditor.DesktopVariableEditor')
        veManager = dve.PeerManager;
    else
        veManager = dve.createInstance('/VariableEditorMOTW',false);
    end
    veManager.openvar(name,workspace,data,UserContext=userContext);

    % The plots tab listeners are initialized after opening the Variable Editor.
    internal.matlab.plotstab.PlotsTabListeners.init();
end

