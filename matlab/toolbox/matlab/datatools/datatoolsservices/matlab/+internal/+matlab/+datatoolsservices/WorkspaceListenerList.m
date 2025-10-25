classdef WorkspaceListenerList < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.

    % A class defining MATLAB Workspace Listener list.  This is used in
    % conjunction with the WorkspaaceListener class.  Don't use this class
    % directly -- instead create a class which extends the WorkspaceListener
    % class, and it will do the adding/removing in the listener list itself.

    % Copyright 2019-2023 The MathWorks, Inc.

    properties(SetAccess = protected, GetAccess = public)
        ListenerList {};
        DisabledListenerList = {};
    end

    methods
        function obj = WorkspaceListenerList()
            mlock;
        end
        
        function addListener(this, listener)
            % Add a listener to the list
            if isempty(this.ListenerList)
                this.ListenerList = {listener};
            else
                this.ListenerList{end+1} = listener;
            end
        end

        % returns the listner when found and [] otherwise.
        function found = findListener(this, listener)
             found = [];
             for i=1:length(this.ListenerList)
                if this.ListenerList{i} == listener
                    found = listener;
                    break;
                end
            end
        end

        function removeListener(this, listener)
            % Remove a listener from the list
            for i=1:length(this.ListenerList)
                if this.ListenerList{i} == listener
                    this.ListenerList(i) = [];
                    break;
                end
            end
        end

        function listener = getListener(this, index)
            % Get a listener.  If the index being requested is not in the list,
            % return a NoOpWorkspaceListener which does nothing.
            if index <= this.getListenerListSize()
                listener = this.ListenerList{index};
            else
                listener = internal.matlab.datatoolsservices.NoOpWorkspaceListener;
            end
        end

        function listenerList = getDisabledListenerList(this)
            % Gets DisabledListenerList
            listenerList = this.DisabledListenerList;
        end

        function addToDisabledListenerList(this, listener)
            % Queues incoming listener to the DisabledListenerList
            this.DisabledListenerList{end+1} = listener;
        end

        function resetDisabledListenerList(this)
            % Resets DisabledListenerList to free all listener handles
            this.DisabledListenerList = {};
        end

        function s = getListenerListSize(this)
            % Return the size of the listener list
            s = length(this.ListenerList);
        end
    end
end

