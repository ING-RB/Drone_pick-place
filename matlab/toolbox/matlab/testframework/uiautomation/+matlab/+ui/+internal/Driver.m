classdef Driver < handle
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2017-2024 The MathWorks, Inc.
    
    methods
        function press(driver, H, varargin)
            driver.doGesture(@uipress, H, varargin{:});
        end
        function doublepress(driver, H, varargin)
            driver.doGesture(@uidoublepress, H, varargin{:});
        end
        function choose(driver, H, varargin)
            driver.doGesture(@uichoose, H, varargin{:});
        end
        function contextmenu(driver, H, varargin)
            driver.doGesture(@uicontextmenu, H, varargin{:});
        end
        function drag(driver, H, varargin)
            driver.doGesture(@uidrag, H, varargin{:});
        end
        function type(driver, H, varargin)
            driver.doGesture(@uitype, H, varargin{:});
        end
        function hover(driver, H, varargin)
            driver.doGesture(@uihover, H, varargin{:});
        end
        function dismissAlert(driver, H, varargin)
            driver.doGesture(@dismissAlert, H, varargin{:});
        end
        function scroll(driver, H, varargin)
            driver.doGesture(@uiscroll, H, varargin{:});
        end
        function lock(driver, FIG)
            driver.doLock(FIG, true);
        end
        function unlock(driver, container)
            driver.doLock(container, false);
        end
        function chooseDialog(driver, dialogType, varargin)
            if (isa(varargin{1}, "matlab.ui.Figure"))
                % Dialog has parent figure
                driver.doGesture(@chooseDialog, varargin{1}, dialogType, varargin{2:end});
            else
                driver.chooseNoParentDialog(dialogType, varargin{:});
            end
        end
        function dismissDialog(driver, dialogType, varargin)
            if (isa(varargin{1}, "matlab.ui.Figure"))
                % Dialog has parent figure
                driver.doGesture(@dismissDialog, varargin{1}, dialogType, varargin{2:end});
            else
                driver.dismissNoParentDialog(dialogType, varargin{:});
            end
        end
    end
    
    methods (Access = protected)

        function doGesture(driver, gesture, H, varargin)
            import matlab.uiautomation.internal.InteractorFactory;
            
            if ~haveDisplayAndFigureEnabled
                e = MException( message('MATLAB:uiautomation:Driver:NoDisplay') );
                throwAsCaller(e);
            end
            
            if ~isscalar(H) && ~isa(H, "matlab.ui.container.TreeNode")
                e = MException( message('MATLAB:uiautomation:Driver:MustBeScalar') );
                throwAsCaller(e);
            end
            
            if ~isArrayOfValidHGHandles(H)
                e = MException( message('MATLAB:uiautomation:Driver:MustBeValidHGHandle') );
                throwAsCaller(e);
            end
            
            if ~isRootDescendant(H)
                e = MException( message('MATLAB:uiautomation:Driver:RootDescendant') );
                throwAsCaller(e);
            end

            if isTabDescendant(H) && ~isParentTabSelected(H)
               e = MException( message('MATLAB:uiautomation:Driver:ParentTabUnselected') );
               throwAsCaller(e);
            end
            
            try
                if isa(H, "matlab.ui.container.TreeNode") && strcmp(func2str(gesture), "uichoose")
                    if ~isscalar(H) && ~driver.hasSingularParent(H)
                        throw(MException(message('MATLAB:uiautomation:Driver:MustHaveSingularParent')));
                    end
                    actor = InteractorFactory.getInteractorForHandle(H(1));
                    gesture(actor, H, varargin{:});
                else
                    actor = InteractorFactory.getInteractorForHandle(H);
                    gesture(actor, varargin{:});
                end
                
            catch e
                throwAsCaller(e);
            end
        end

        function doLock(driver, container, bool)
            try
                container = container(:).';
                container = unique(container, 'stable');
                if isa(container, 'matlab.ui.container.internal.AppContainer') 
                    hasValidAppContainerForLock(container);
                    % For the matlab.uitest.unlock API, we need to check if figure documents or panels exist.
                    % If they do not, we should simply return without proceeding to our client.
                    % Currently, the ATF client startup is dependent on the instantiation of figures.
                    % As a result, the ATF client will not load if figures are not present.
                    if ~driver.hasFigureDocuments(container) && ~driver.hasFigurePanels(container)
                        return;
                    end
                    driver.dispatch(container, bool);
                    return;
                end
    
               hasValidFigureContainerForLock(container);           
               driver.dispatch(container, bool);

            catch e
                throwAsCaller(e);
            end
            
        end

        function dispatch(driver, container, bool)
            import matlab.uiautomation.internal.InteractorFactory;

            try
                dispatcher = driver.getDispatcherForLock();
                for f = container
                    actor = InteractorFactory.getInteractorForHandle(f, dispatcher);
                    uilock(actor, bool);
                end
            catch e
                throwAsCaller(e);
            end
        end

        function dispatcher = getDispatcherForLock(~)
            import matlab.uiautomation.internal.UIDispatcher;

            dispatcher = UIDispatcher.forUILock();
        end

        function chooseNoParentDialog(driver, dialogType, varargin)
            
            arguments
                driver
                dialogType {mustBeTextScalar}
            end

            arguments (Repeating)
                varargin
            end
            
            % Get the dialog interactor of the specific dialogType
            dialogInteractor = driver.getNoParentDialogInteractor(dialogType);
            dialogInteractor.chooseDialog(varargin{:});
        end

        function dismissNoParentDialog(driver, dialogType, varargin)
            
            arguments
                driver
                dialogType {mustBeTextScalar}
            end

            arguments (Repeating)
                varargin
            end
            
            % Get the dialog interactor of the specific dialogType
            dialogInteractor = driver.getNoParentDialogInteractor(dialogType);
            dialogInteractor.dismissDialog(varargin{:});
        end

        function bool = hasFigureDocuments(~, container)
            docs = container.getDocuments();
            bool = any(cellfun(@(x) isa(x, 'matlab.ui.internal.FigureDocument'), docs));
        end

        function bool = hasFigurePanels(~, container)
            panels = container.getPanels();
            bool = any(cellfun(@(x) isa(x, 'matlab.ui.internal.FigurePanel'), panels));
        end
    end

    methods(Access=private)
        function bool = hasSingularParent(~, treeNodes)
            parentTreeNodes = ancestor(treeNodes, 'uitree')';
            bool = isscalar(unique([parentTreeNodes{:}]));
        end

        function dialogInteractor = getNoParentDialogInteractor(~, dialogType)
            import matlab.unittest.internal.services.ServiceFactory;
            import matlab.automation.internal.services.ServiceLocator;
            
            liaison = matlab.uiautomation.internal.InteractorLookupLiaison;
            liaison.ComponentClass = string(dialogType);
            namespace = "matlab.uiautomation.internal.interactors.dialogServices";
            locator = ServiceLocator.forNamespace(matlab.metadata.Namespace.fromName(namespace));
            serviceClass = ?matlab.uiautomation.internal.interactors.services.InteractorLookupService;
            locatedServiceClasses = locator.locate(serviceClass);
            locatedServices = ServiceFactory.create(locatedServiceClasses);
            fulfill(locatedServices, liaison);
            
            cls = liaison.InteractorClass;
            % construct dialog interactor and call its method
            dialogInteractor = feval(str2func(cls.Name));
        end
    end
end

function bool = hasDisplay
bool = matlab.ui.internal.hasDisplay;
end

function bool = haveDisplayAndFigureEnabled
bool = hasDisplay && matlab.ui.internal.isFigureShowEnabled;
end

function bool = isValidHandle(container)
        bool = isa(container,'handle') && all(isvalid(container));
end

function hasValidAppContainerForLock(container)
    if ~hasDisplay
        me = MException( message('MATLAB:uiautomation:Driver:NoDisplay') );
        throwAsCaller(me);
    end

    if ~isscalar(container)
        me = MException(message('MATLAB:uiautomation:Driver:MustBeScalar'));
        throwAsCaller(me);
    end

    if ~isValidHandle(container)
        me = MException(message('MATLAB:uiautomation:Driver:MustBeValidHandle'));
        throwAsCaller(me);
    end
end

function hasValidFigureContainerForLock(container)
    if ~isArrayOfValidHGHandles(container)
        e = MException( message('MATLAB:uiautomation:Driver:MustBeValidHGHandle') );
        throwAsCaller(e);
    end
    
    if ~isa(container, 'matlab.ui.Figure') || ~all(arrayfun(@matlab.ui.internal.isUIFigure, container))
        me = MException( message('MATLAB:uiautomation:Driver:MustBeUIFigure') );
        throwAsCaller(me);
    end

    if ~haveDisplayAndFigureEnabled
        me = MException( message('MATLAB:uiautomation:Driver:NoDisplay') );
        throwAsCaller(me);
   end
end

function bool = isArrayOfValidHGHandles(H)
bool = isa(H,'handle') && all(ishghandle(H)) && all(isvalid(H));
end

function bool = isRootDescendant(H)
bool = ~isempty(ancestor(H, 'root'));
end

function bool = isTabDescendant(H)
    if isa(H, 'matlab.ui.container.Tab')
        bool = ancestor(H, 'uitab', 'toplevel') ~= H;
    else
        bool = ~all(arrayfun(@(h)isempty(ancestor(h, "uitab")), H));
    end
end

function bool = isParentTabSelected(H)
    for i = 1:numel(H)
        parentTab = ancestor(H(i), 'uitab');
        if isa(H(i), 'matlab.ui.container.Tab')
            parentTab = ancestor(ancestor(H(i), 'uitabgroup'), 'uitab');
        end

        % For the scenario where we have nested uitabgroups
        % Check if all higher level ancestor uitabs are selected before performing
        % gesture against target component
        while ~isempty(parentTab)
            parentTabGroup = parentTab.Parent;
            if ~isequal(parentTabGroup.SelectedTab, parentTab)
                bool = false;
                return;
            end
            parentTab = ancestor(parentTabGroup, 'uitab');
        end
    end

    bool = true;
end

% LocalWords:  toplevel uitabgroups uitabs uipress doublepress uidoublepress uichoose uidrag uitype
% LocalWords:  uihover uiscroll Interactor func uilock
