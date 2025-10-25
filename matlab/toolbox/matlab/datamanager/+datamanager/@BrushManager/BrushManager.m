classdef BrushManager < handle
   %

   % Copyright 2016-2024 The MathWorks, Inc.
    properties
        SelectionTable
        VariableNames
        DebugMFiles
        DebugFunctionNames
        ArrayEditorVariables
        ArrayEditorSubStrings
        UndoData
        ApplicationData
        FactoryValue = false
    end
    
    properties(Hidden)
       % Updates brushing for JSVariableEditor.
       VEBrushAction; 
    end
    
    methods (Access = private)
        function h = BrushManager()
        end
        
    end
    methods (Static)
        function h = getInstance(peekFlag)
            bManager = localBrushManager;
            if isempty(bManager) && ~(nargin>=1 && strcmp(peekFlag,'-peek'))
                bManager = datamanager.BrushManager();
                localBrushManager(bManager);
                % TODO: Remove this when the Java Variable Editor is
                % removed
                if ~feature('webui')
                    com.mathworks.page.datamgr.brushing.ArrayEditorManager.addArrayEditorListener;
                end
            end
            h = bManager;
        end

        function clearCurrentLinked(ax)
            fig = ancestor(ax,'figure');
            brushMgr = datamanager.BrushManager.getInstance('-peek');
            if ~isempty(brushMgr)
                brushMgr.clearLinked(fig,ax,'','');
            end
        end

        function previousBrushManager = setBrushManagerInstanceForTesting(bMgr)
            previousBrushManager = localBrushManager;
            localBrushManager(bMgr);
        end
    end    
end

function bManagerOut = localBrushManager(bManagerIn)

mlock
persistent bManager;
if nargin>=1
    bManager = bManagerIn;
end
bManagerOut = bManager;
end

