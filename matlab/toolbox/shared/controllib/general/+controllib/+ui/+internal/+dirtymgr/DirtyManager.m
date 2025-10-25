classdef DirtyManager < handle
% DIRTYMANAGER
%
% The DirtyManager assists with managing the "dirty" state of a UI.
% Construction of the object can be handled in two ways:
%
%   1. Create a standalone instance of the dirty manager
%       dmgr = DirtyManager();
%   2. Create a shared instances of the dirty manager contextual to a
%      UNIQUE string id.
%       dmgr = DirtyManager.getInstance("my_id")
%
% Use construction by ID when your data and UI share the same context (e.g.
% the UI is contextual to a Simulink model). Note, the ID field MUST be
% unique otherwise you run the risk of colliding with the dirty management
% of another app referencing the same ID. Best practice is to form IDs
% based on the app type (e.g. "SSM_DIRTY_MGR_FOR_VDP" is a sample ID for
% the steady state manager contextual to the model vdp).
%
% The DirtyManager dirty state can be managed using the setDirty and reset
% methods. Both methods will fire the DirtyChanged event if the dirty state
% has changed. UIs can listen to the DirtyChanged event to react to changes
% in the dirty state. The isDirty method can be used to query the dirty
% state of the manager.
%
% The method updateTitleOnDirty is provided to automatically append a "*"
% to the title of the UI when the state of the manager becomes dirty. The
% "*" is removed when the dirty state is reset. 
%
%   Example
%       % import the dirtymgr package
%       import controllib.ui.internal.dirtymgr.*
%
%       % attach app container to dirty manager
%       dmgr = DirtyManager.getInstance(id)
%       opts.Tag = "MY_TAG";
%       opts.Title = "untitled"
%       appc = matlab.ui.container.internal.AppContainer(opts);
%       dmgr.updateTitleOnDirty(appc);
%
%       % update the app title through the dirty manager
%       dmgr.BaseTitle = "MY_APP";
%
%       % set dirty on the dirty manager, the title of the app will now
%       % include an *
%       dmgr.setDirty()
%
%       % resetting the dirty manager will remove the *
%       dmgr.reset();
%
%       % when the app container is deleted, dirty is reset
%       delete(appc)
%       assert(~isDirty(dmgr));

% Revised: 1-19-2023
% Copyright 2023 The MathWorks, Inc.

    properties (SetObservable,AbortSet)
        % "Base" title of the app. A "*" will be appended to this title
        % if dirty. Change this field instead of changing the Title field
        % on the app.
        BaseTitle (1,1) string = ""
    end

    properties (Access = private)
        % dirty state
        Dirty_ (1,1) logical = false

        % object with title field (app container)
        HasTitleObject_             = []

        % internal listeners
        DirtyChangedListener_       = []
        BaseTitleChangedListener_   = []
        ObjectDestroyedListener     = []
    end

    events
        DirtyChanged
    end

    methods
        function this = DirtyManager()
            % can be constructed in isolation
        end
        function delete(this)
            deRegisterHasTitleObject_(this);
        end
        function val = isDirty(this)
            % check the value of the dirty state
            val = this.Dirty_;
        end
        function was = setDirty(this,val)
            % set the dirty state to the desired value (default = true).
            % This will fire the DirtyChanged event if the dirty state has
            % changed
            arguments
                this (1,1)
                val (1,1) logical = true
            end
            was = isDirty(this);
            this.Dirty_ = val;
            % only fire the dirty event if dirty changed
            if was ~= val
                notifyDirtyChanged_(this);
            end
        end
        function val = reset(this)
            % reset the dirty state
            val = setDirty(this,false);
        end
        function updateTitleOnDirty(this,has_title_object,title_field_name)
            % Register event listeners to automatically update the Title of
            % a handle object when the DirtyChanged event occurs. Note,
            % when this method is called, the DirtyManager effectively
            % takes ownership of the Title property from the object.
            % Therefore if you need to change the title (e.g. "untitled" to
            % "<session name>)" change the BaseTitle property of the
            % DirtyManager
            %
            %   Example
            %       % attach app container to dirty manager
            %       dmgr = DirtyManager.getInstance(id)
            %       opts.Tag = "MY_TAG";
            %       opts.Title = "untitled"
            %       appc = matlab.ui.container.internal.AppContainer(opts);
            %       dmgr.updateTitleOnDirty(appc);
            %
            %       % update the app title through the dirty manager
            %       dmgr.BaseTitle = "MY_APP";
            %
            %       % set dirty on the dirty manager
            %       dmgr.setDirty()
            %
            %       % when the app container is deleted, dirty is reset
            %       delete(appc)
            %       assert(~isDirty(dmgr));
            arguments
                this (1,1)
                has_title_object (1,1) handle
                title_field_name (1,1) string = "Title"
            end
            localMustHaveTitle(has_title_object,title_field_name);

            % clear existing listeners and title
            deRegisterHasTitleObject_(this);

            % grab the base title from the app container object
            this.BaseTitle = has_title_object.(title_field_name);

            % install the HasTitleObject/AppContainer
            this.HasTitleObject_ = has_title_object;

            % add a listener to base title changes
            weakThis = matlab.lang.WeakReference(this);
            this.BaseTitleChangedListener_ = addlistener(this,...
                "BaseTitle","PostSet",@(~,~) updateTitle_(weakThis.Handle,title_field_name));

            % listen to dirty changes
            this.DirtyChangedListener_ = addlistener(this,...
                "DirtyChanged",@(~,~) updateTitle_(weakThis.Handle,title_field_name));

            % add a listener on the has title object for de-registration on
            % destruction of the object
            this.ObjectDestroyedListener = addlistener(this.HasTitleObject_,...
                "ObjectBeingDestroyed",@(~,~) hasTitleObjectDestroyedCB_(weakThis.Handle));

            % update the title now
            updateTitle_(this,title_field_name);
        end
    end

    methods (Access = private)
        function notifyDirtyChanged_(this)
            notify(this,"DirtyChanged");
        end
        function deRegisterHasTitleObject_(this)
            % delete listeners and un-install the app container
            delete(this.DirtyChangedListener_);
            delete(this.BaseTitleChangedListener_);
            delete(this.ObjectDestroyedListener);
            this.HasTitleObject_ = [];
            % remove the base title
            this.BaseTitle = "";
        end
        function updateTitle_(this,title_field_name)
            if isempty(this.HasTitleObject_)
                return;
            end
            title = this.BaseTitle;
            if isDirty(this)
                title = title + "*";
            end
            this.HasTitleObject_.(title_field_name) = title;
        end
        function hasTitleObjectDestroyedCB_(this,~,~)
            deRegisterHasTitleObject_(this);
            % reset dirty when a registered app is destroyed
            reset(this);
        end
    end

    methods (Static)
        function this = getInstance(id)
            % dmgr = DirtyManager.getInstance(id)
            %   Get an instance to the dirty manager given a string ID
            arguments
                id (1,1) string
            end
            persistent d
            % mlock;
            if isempty(d)
                d = dictionary();
            end

            function this = nestedInertToDict()
                this = controllib.ui.internal.dirtymgr.DirtyManager();
                d(id) = this;
            end
            if isConfigured(d) && isKey(d,id)
                this = d(id);
                if ~isvalid(this)
                    this = nestedInertToDict();
                end
            else
                this = nestedInertToDict();
            end
        end
    end
end
function localMustHaveTitle(h,fname)
if ~isprop(h,fname)
    error("Controllib:general:DirtyMgrObjectMustHaveTitleField","Object must have the field ""%s""",fname);
end
end