classdef AbstractDialog < handle

% ABSTRACTDIALOG  Ancestor of all dialogs providing common utilities
%
 
% Copyright 2011-2015 The MathWorks, Inc.

properties(GetAccess = protected, SetAccess = protected)
    TCPeer
    APIListeners
    GUIPeer
    GUIListeners
end
methods
    function setPeer(this,peer)
        this.GUIPeer = peer;
    end
    function peer = getPeer(this)
        peer = this.GUIPeer;
    end
    function addCallbackListener(this, cb, fcn)
        lsnr = handle.listener( handle(cb), 'delayed', {@cbBridge, fcn} );
        this.GUIListeners = [this.GUIListeners; lsnr];
    end   
    function show(this)
        show(getPeer(this));        
    end
    function dispose(this)
        dispose(this.getPeer);
        delete(this);
    end
    function tc = getTC(this)
        %GETTC Return tool-component of this dialog
        tc = this.TCPeer;
    end
end
end
function cbBridge(es,ed,fcn)
feval( fcn{1}, java(es), ed.JavaEvent, fcn{2:end} );
end

