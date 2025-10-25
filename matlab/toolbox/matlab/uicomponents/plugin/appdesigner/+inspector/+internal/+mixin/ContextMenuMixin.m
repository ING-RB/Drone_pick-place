classdef ContextMenuMixin < handle    
    %
    
    % Do not remove above space, it keeps the copyright out of the help
    % text
    %   Copyright 2019 The MathWorks, Inc.
    
    properties(SetObservable = true)
        % Temporary Data Type to make ContextMenu "enumerated"
        %
        % The possible values are adjusted in the client when inspecting
        ContextMenu inspector.internal.datatype.IconAlignment
    end        
end
