classdef AppDesignerWindowController < handle
    % AppDesignerWindowController manages starting and closing App Designer
    % window

    % Copyright 2015-2023 The MathWorks, Inc.

    properties (Access = public)
        % connection object to start the connector
        Connection

        % the BrowserController manage to start/close browser
        BrowserController
    end

    properties (Access = private)
        % the App Designer model
        AppDesignerModel
    end

    properties(Dependent, SetAccess = 'private')
        % Boolean to track wether or not the browser is still valid
        IsWindowValid;
    end

    methods
        function obj = AppDesignerWindowController(appDesignerModel, connection)

            narginchk(2,2);

            obj.AppDesignerModel = appDesignerModel;

            % Connection object to manage the URL for staring App Designer
            obj.Connection = connection;
        end

        function delete(obj)
            % cleanup the browser
            %
            % Make sure that the browser controller is created and valid
            % before trying to delete it
            %
            % In various scenarios, the browser may not have been started
            % or may have crashed
            if ~isempty(obj.BrowserController) && isvalid(obj.BrowserController)
                delete(obj.BrowserController);
            end
        end

        function startBrowser(obj, browserControllerFactory, nameValueArgs)
            % STARTBROWSER start App Designer client browser
            %
            %   browserControllerFactory: browser for launching App
            %       Designer
            %   nameValueArgs.Visible - logical to indicate if the browser
            %       should be launched visible or not (default = true)
            arguments
                obj
                browserControllerFactory
                nameValueArgs.Visible logical = true;
            end

            narginchk(2, 2);

            % ensure we have a fresh URL
            obj.Connection.refresh();

            % set initial Browser State and launch the client
            initialBrowserState.Title = message('MATLAB:appdesigner:appdesigner:AppDesigner').getString();
            initialBrowserState.URL = obj.Connection.AbsoluteUrlPath;
            initialBrowserState.Visible = nameValueArgs.Visible;

            % Pass preference group to browser controller to save browser
            % window postion/state when closing, to restore when launching
            % App Designer next time
            initialBrowserState.PrefGroup = 'appdesigner';

            try
                obj.BrowserController = browserControllerFactory.launch(initialBrowserState);
            catch e
                % Browser window, for example, CEF, fails to start, and
                % then clean up, instead of leaving it in a bad state
                obj.delete();
                rethrow(e);
            end

            % When the browser is launched, the AppDesigner registers a
            % close listener on the browser. Then when the browser is
            % closed, the delete() method in this class is called which
            % cleans up the browser instance.
            %
            % However, if when launching AppDesigner, the user closes
            % MATLAB very quickly, there is a chance the AppDesigner client
            % did not have a chance to notify server side to register the
            % listener. If this is the case, there will be asyncio errors
            % on the command as MATLAB is exiting because AppDesigner is
            % still holding on to the reference to the browser.
            %
            % To avoid these errors, here we add a temporary callback to
            % WindowClosing to let us know the browser is closed.  Do not
            % attempt to veto.
            %
            % This callback will be changed later after the browser is
            % closed
            obj.BrowserController.UserCloseRequestCallback = @(varargin) handleBrowserClosedBeforeClientLoaded(obj);

            % By default, if the browser is closed, close it
            %
            % This might be changed later based on the context of the close (a crash, a user close, etc..)
            obj.BrowserController.WindowClosedCallback = @(varargin) obj.handleWindowClosed();

            % Browser Process unexpectedly being deleted
            obj.BrowserController.addlistener('ObjectBeingDestroyed', @(varargin) handleWindowCrashed(obj));

            % When MATLAB crashes / exits in a forced way
            obj.BrowserController.WindowCrashedCallback = @(src, event) obj.handleWindowCrashed();

            % Observe when the window has finished loading
            %
            % When this happens, we are ready to sync up the server with
            % the client
            obj.BrowserController.WindowStartedCallback = @(varargin) handleWindowStarted(obj);
        end

        function bringToFront(obj)
            obj.BrowserController.bringToFront();
        end

        function requestToClose(obj)
            obj.bringToFront();
            obj.BrowserController.requestWindowClose();
        end

        function tf = get.IsWindowValid(obj)
            % Determines if the window is valid

            % By default, assume no
            tf = false;

            % If the browser controller is valid, then defer to asking it
            if ~isempty(obj.BrowserController) && isvalid(obj.BrowserController)
                tf = obj.BrowserController.IsBrowserValid;
            end
        end
    end

    methods (Access = private)

        function handleWindowStarted(obj)
            % Handles the window started

            % Unset UserCloseRequestCallback to let client side to manage
            % window closing, so that App Designer does not need to 
            % wait for matlab side free for closing
            obj.BrowserController.UserCloseRequestCallback = [];

            % When MATLAB is closed, in order to give users oppurtunity to
            % save dirty apps, handle MATLABClosing event from webwindow.
            % Only set this callback when browser is initialized properly,
            % otherwise client side Javascript won't be there to respond
            obj.BrowserController.MATLABCloseRequestCallback = @(varargin)obj.handleMATLABCloseRequestCallback();
        end

        function handleWindowClosed(obj)
            % This callback happens when:
            %
            % - the client has processed everything it needs to do and App
            % Designer is ready to close
            %
            %
            % This callback will:
            %
            % - delete this window controller

            delete(obj);
        end

        function handleMATLABCloseRequestCallback(obj)
            % This callback happens when:
            %
            % - the user tries to close MATLAB when App Designer is open
            %
            % This callback will:
            %
            % - tell the browser to send a close request to the client,
            % where the client can do the appropriate thing like save dirty
            % apps

            obj.BrowserController.bringToFront();
            obj.BrowserController.requestWindowCloseByExitMATLAB();

            % Set up CancelClosingCallback, so that when users reject to 
            % close App Designer, we can restore WindowClosedCallback to 
            % a normal one, and next time closing App Designer would not
            % exit MATLAB accidentally
            obj.BrowserController.CancelClosingCallback = @(varargin) obj.handleCancelClosing();
            obj.BrowserController.WindowClosedCallback = @(varargin) obj.handleMATLABClosed();
        end

        function handleCancelClosing(obj)
            % Restore callback to normal one for WindowClosedCallback, which 
            % would not exit MATLAB
            obj.BrowserController.CancelClosingCallback = [];
            obj.BrowserController.WindowClosedCallback = @(varargin) obj.handleWindowClosed();
        end

        function handleMATLABClosed(obj)
            % This callback happens when:
            %
            % - the client has processed everything it needs to do and
            % MATLAB is ready to close
            %
            % This callback will:
            %
            % - delete this window controller - exit MATLAB

            delete(obj);
            exit;
        end

        function handleBrowserClosedBeforeClientLoaded(obj)
            % This callback happens when:
            %
            % - the client window was opened, but quickly closed for some
            % reason
            %
            % This callback will:
            %
            % - delete this window controller explicitly. - It will not
            % wait for any closing requests, because likely the client is
            % not loaded and won't respond
            delete(obj);
        end

        function handleWindowCrashed(obj)
            % This callback happens when:
            %
            % - The window exits in a forced way and we do not have a
            % chance to prompt the user for saving work, such as the
            % browser process (ex: CEF) exits unexpectedly or is terminated
            % through the Task Manager.
            %
            % This callback will:
            %
            % - delete this window controller

            delete(obj);
        end

    end
end

