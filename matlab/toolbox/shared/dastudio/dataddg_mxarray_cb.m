function [varargout] = dataddg_mxarray_cb(dlgH, action, varargin)

switch action
    case 'postapply_cb'
        dispatcher = DAStudio.EventDispatcher;
        obj = varargin{1};
        dispatcher.broadcastEvent('PropertyChangedEvent', obj);
        dlgs = DAStudio.ToolRoot.getOpenDialogs(obj);
        for i = 1:numel(dlgs)
            dlg = dlgs(i);
            dlg.refresh;
        end
        varargout = {true, ''};
end
