classdef HTMLViewer < handle
%HTMLViewer  Represents a handle to an HTML Viewer tab
%   The matlab.htmlviewer.HTMLViewer class represents a handle to an HTML
%   tab open in the HTML Viewer.
%
%   V = htmlviewer(...) returns a handle to the active HTML Viewer tab.
%
%   HTMLViewer properties:
%       Input       - Last specified input for the HTML Viewer tab
%       Visible     - Whether the contents of the HTML Viewer tab are
%                     visible
%       Title       - Title of the HTMLViewer shown in the Tab header
%
%   HTMLViewer methods:
%       getHTMLText - Get the current contents of the HTML Viewer tab
%       close       - Close the HTML Viewer tab and delete the handle
%
%   When a tab in the HTML Viewer is closed, the handle to that tab is
%   deleted immediately.
%
%   See also HANDLE, HTMLVIEWER.

%   Copyright 2021-2025 The MathWorks, Inc.
    properties (Access = public)
        %Input  Last specified input for the HTML Viewer tab
        %   This property returns a string containing the last specified
        %   input for the HTML Viewer tab. If the tab was opened without
        %   specifying an input, this property returns an empty string.
        %
        %   Set the Input property to change the page displayed in the HTML
        %   Viewer tab. Specify Input as a string or character vector
        %   containing the full or partial path to a local HTML file, or
        %   HTML-formatted text using the 'text://' URL scheme. For
        %   example: "text://<html><h1>Hello!</h1></html>".
        %
        %   Note:
        %
        %   If the back and forward buttons were used to navigate away from
        %   the specified page, the page displayed in the HTML Viewer tab
        %   might not match the last specified input.
        Input

        %Visible  Whether the contents of the HTML Viewer tab are visible
        %   This property returns TRUE if the contents of the HTML Viewer
        %   tab are visible and FALSE otherwise.
        %
        %   Set this property to FALSE to hide the contents of the HTML
        %   Viewer tab and show a blank page instead. Set this property to
        %   TRUE to show the contents of the HTML Viewer tab and bring
        %   focus to the tab.
        Visible

    end

    properties (GetAccess = public, SetAccess = public, Hidden)
        Title
    end

    properties (GetAccess = public, SetAccess = private, Hidden)
        getCurrentLocation
        isVisible
        isShowing
        getHtmlText
    end

    properties (GetAccess = public, SetAccess = private, Hidden, SetObservable)
        IsOpen = false
    end

    properties (Access = private, Hidden)
        NewTab
        ShowToolbar
        WebHandle
        IsTextHTMLInput
        ViewerID
        RequestID
        FileName
        FilePath
        HTMLPagePath
        MetaData
        FirstPageAdded
    end

    methods
        function close(obj)
            %CLOSE  Close the HTML Viewer tab and delete the handle
            %   CLOSE(v) closes the HTML Viewer tab and deletes the handle
            %   v. If no other HTML Viewer tabs are open, CLOSE also closes
            %   the HTML Viewer.
            obj.getHTMLViewerManagerInstance().close(obj.ViewerID);
            % Invalidate viewer handle on close.
            obj.delete;
        end

        function htmlText = getHTMLText(obj)
            %getHTMLText  Get the current contents of the HTML Viewer tab
            %   htmlText = getHTMLText(v) returns a string containing the
            %   current contents of the HTML Viewer tab specified by v.
            htmlText = string(obj.getHTMLViewerManagerInstance().getHTMLText(obj.ViewerID));
        end
    end
    % Property custom set/get implementation.
    methods
        function set.Input(obj, htmlInput)
            arguments
                obj
                htmlInput {mustBeTextScalar}
            end
            obj.Input = string(obj.getHTMLViewerManagerInstance().validateInput(htmlInput));
            obj.updateHTMLViewer();
        end
        function set.Title(obj, htmlTitle)
            arguments
                obj
                htmlTitle (1,1) string {mustBeTextScalar} = ""
            end
            obj.Title = htmlTitle;
            obj.getHTMLViewerManagerInstance().setTitle(obj.ViewerID, htmlTitle); %#ok<MCSUP>
        end
        function title = get.Title(obj)
            title = string(obj.getHTMLViewerManagerInstance().getTitle(obj.ViewerID));
        end

        function visible = get.Visible(obj)
            visible = obj.Visible;
        end

        function set.Visible(obj, value)
            arguments
                obj
                value (1,1) logical {mustBeNumericOrLogical}
            end
            obj.Visible = value;
            obj.getHTMLViewerManagerInstance().setVisibility(obj.ViewerID, value); %#ok<MCSUP>
        end
        % The below methods are added for pass-through from web to
        % HTMLViewer
        function loc = get.getCurrentLocation(obj)
            loc = obj.Input;
        end

        function visible = get.isVisible(obj)
            visible = obj.Visible;
        end

        function isShown = get.isShowing(obj)
            isShown = isequal(obj,matlab.htmlviewer.internal.getActiveWindow());
        end

        function html = get.getHtmlText(obj)
            html = obj.getHTMLText;
        end
    end

    methods(Hidden)
        % The below methods are added for pass-through from web to
        % HTMLViewer
        function hide(obj)
            obj.Visible = 0;
        end

        function show(obj)
            obj.Visible = 1;
        end

        function setHtmlText(obj, htmlInput)
            obj.Input = htmlInput;
        end

        function setCurrentLocation(obj, location)
            obj.Input = location;
        end

        function requestFocus(obj)
            obj.Visible = true;
        end
    end

    methods(Static, Hidden)
        function htmlManagerInstance = getHTMLViewerManagerInstance()
            htmlManagerInstance =  matlab.htmlviewer.internal.HTMLViewerManager.getInstance();
        end
    end 
    methods (Hidden)
        function obj = HTMLViewer(options)
            obj.parseInputs(options);
        end

        function open(obj)
            payload = struct(...
                'ViewerID', obj.ViewerID, ...
                'RequestID', obj.RequestID, ...
                'Input', obj.Input, ...
                'FileName', obj.FileName, ...
                'FilePath', obj.FilePath, ...
                'HTMLPagePath', obj.HTMLPagePath, ...
                'NewTab', obj.NewTab, ...
                'ShowToolbar', obj.ShowToolbar, ...
                'IsTextHTMLInput', obj.IsTextHTMLInput, ...
                'MetaData', obj.MetaData);
            obj.getHTMLViewerManagerInstance().requestHTMLPageOpen(payload);
            obj.updateOnOpen();
        end

        function updateInputArguments(obj, options)
            options.ViewerID = obj.ViewerID;
            obj.parseInputs(options);
        end

        function updateOnClose(obj)
            obj.Visible = false;
            if obj.IsOpen
                obj.IsOpen = false;
            end
        end

        function status = isTabOpen(obj)
            status = obj.IsOpen;
        end
    end

    methods (Access = private)
        function parseInputs(obj, options)
            obj.ViewerID = options.ViewerID;
            obj.RequestID = options.RequestID;
            obj.FileName = options.FileName;
            obj.FilePath = options.FilePath;
            obj.HTMLPagePath = options.HTMLPagePath;
            obj.NewTab = options.NewTab;
            obj.ShowToolbar = options.ShowToolbar;
            obj.IsTextHTMLInput = options.IsTextHTMLInput;
        end

        function updateHTMLViewer(obj)
            htmlViewerInstance = obj.getHTMLViewerManagerInstance();
            % In MATLAB Online for workflows involving loading local HTML
            % files 'MetaData' will hold the static file path and
            % 'HTMLPagePath' will hold the file content. In other workflows
            % 'MetaData' will be an empty string.
            [obj.FileName, obj.HTMLPagePath, obj.IsTextHTMLInput, obj.MetaData, obj.FilePath] = htmlViewerInstance.addHTMLPageLocationToSecureList(obj.Input);
            obj.assignRequestID();
            obj.open();
        end
        
        function assignRequestID(obj)
            if isempty(obj.FirstPageAdded) % object initialized
                if obj.getHTMLViewerManagerInstance().isInputBlank(obj.Input)
                    obj.FirstPageAdded = false;
                else
                    obj.FirstPageAdded = true;
                end
                obj.RequestID = string(obj.getHTMLViewerManagerInstance().createUUID());
            elseif isequal(obj.FirstPageAdded, false)
                obj.FirstPageAdded = true;
                % Reuse the Request ID since first page was empty
            else
                obj.RequestID = string(obj.getHTMLViewerManagerInstance().createUUID());
            end
        end

        function updateOnOpen(obj)
            obj.Visible = true;
            obj.IsOpen = true;
        end
    end

end
