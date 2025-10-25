function varargout=web(varargin)
    %WEB Open Web site or file in Web browser.
    %   WEB opens an empty MATLAB Web browser.
    %
    %   WEB URL displays the page specified by URL in the MATLAB Web browser.
    %   If URL is an external site, the page opens in your system browser. If
    %   any MATLAB Web browsers are already open, it displays the page in the
    %   browser that was used last. If URL is located inside the installed 
    %   documentation, the page displays in the MATLAB Help browser instead of
    %   the MATLAB Web browser.
    %
    %   The WEB command accepts a valid URL such as a web site address, a full 
    %   path to a file, or a relative path to a file (using URL within the 
    %   current folder if it exists there). 
    %
    %   WEB URL -NEW displays the page specified by URL in a new MATLAB Web
    %   browser. This syntax does not apply when the page opens in your system 
    %   browser.
    %
    %   WEB URL -NOTOOLBAR displays the page specified by URL in a MATLAB 
    %   Web browser that does not include the toolbar and address field. If any
    %   MATLAB Web browsers are already open, also use the -new option.
    %   Otherwise, the page displays in the browser that was used last, 
    %   regardless of its toolbar status.
    %
    %   WEB URL -NOADDRESSBOX displays the page specified by URL in a MATLAB
    %   Web browser that does not include the address field. If any MATLAB Web
    %   browsers are already open, also use the -new option. Otherwise the page
    %   displays in the browser that was used last, regardless of its address
    %   field status.
    %
    %   WEB URL -BROWSER displays the page specified by URL in your system 
    %   Web browser. URL can be in any form that the browser supports. 
    %   On Microsoft Windows and Apple Macintosh platforms, the system Web 
    %   browser is determined by the operating system. On UNIX platforms, 
    %   the default system Web browser for MATLAB is Mozilla Firefox. To 
    %   specify a different browser, use MATLAB Web preferences.
    %
    %   STAT = WEB(...) returns the status of the WEB command in the
    %   variable STAT. STAT = 0 indicates successful execution. STAT = 1
    %   indicates that the browser was not found. STAT = 2 indicates that the
    %   browser was found, but could not be launched.
    %
    %   [STAT, BROWSER] = WEB(...) returns the status, and a handle to the last
    %   active browser. If the page opens in a system browser, the WEB command 
    %   returns an empty handle.
    %
    %   [STAT, BROWSER, URL] = WEB(...) returns the status, a handle to the last
    %   active browser, and the URL of the current location. If the page opens 
    %   in a system browser, the WEB command returns an empty handle and URL.
    %
    %   Examples:
    %      web https://www.mathworks.com 
    %         loads the MathWorks Web site home page in your system browser. 
    %      
    %      web file:///disk/dir1/dir2/foo.html
    %         opens the file foo.html in the MATLAB Web browser.
    %
    %      web mydir/myfile.html 
    %         opens myfile.html in the MATLAB Web browser, where
    %      mydir is in the current folder.
    %
    %      web(['file:///' which('foo.html')])
    %         opens foo.html if the file is in a folder on the search path or
    %         in the current folder for MATLAB.
    %
    %      web('text://<html><h1>Hello World</h1></html>') 
    %         displays the HTML-formatted text Hello World.
    %    
    %      web('mydir/myfile.html', '-new', '-notoolbar') 
    %         opens myfile.html in a new MATLAB Web
    %         browser that does not include a toolbar or address field.
    %
    %      web file:///disk/dir1/foo.html -browser
    %         opens the file foo.html in the system Web browser.
    %
    %      web mailto:email_address 
    %         uses the system browser's default email application to send a
    %         message to email_address.
    %
    %      [stat,h1]=web('mydir/myfile.html'); 
    %         opens myfile.html in a MATLAB Web browser. Use close(h1) to
    %         close the browser window.
    
    %   Copyright 1984-2021 The MathWorks, Inc.

    [location, flags] = parseInputs(varargin{:});
    
    browser = [];
    if startsWith(location, "matlab:")
        matlabCmd = extractAfter(location, "matlab:" + asManyOfPattern("/"));
        evalin("caller", matlabCmd);
        location = '';
        success = true;
    elseif checkDemoRedirect(location)
        success = true;
    else
        launcher = matlab.internal.web.WebCommandBrowserLauncher(location, flags, nargout == 0);
        launcher.openBrowser;
        
        success = launcher.Success;
        browser = launcher.Browser;
        location = launcher.LoadUrl;
        if ~success && ~isempty(launcher.Message)
            displayWarningMessage(launcher.Message, launcher.hasFlag("-display"));
        end
    end

    if nargout
        if success
            varargout{1} = 0;
        else
            varargout{1} = 1;
        end
        varargout{2} = browser;
                
        if ~any(cellfun(@isstring, varargin))
            if isempty(location)
                location = '';
            else
                location = char(location);
            end
        end
        varargout{3} = location;
    end
end

function [location, flags] = parseInputs(varargin)
    location = string.empty;
    flags = string.empty;
    if ~isempty(varargin)
        [varargin{:}] = convertCharsToStrings(varargin{:});
        try
            inputs = cellfun(@strip, varargin);
        catch e
            throwAsCaller(e);
        end

        inputs(inputs == "") = [];

        flagPositions = startsWith(inputs, "-");
        flags = inputs(flagPositions);

        nonflags = inputs(~flagPositions);
        if ~isempty(nonflags)
            location = nonflags(1);
        end
    end
end

function redirect = checkDemoRedirect(location)
    % Note that checkForDemoRedirect does not accept string inputs.
    [redirect,mapfile,topic] = matlab.internal.help.checkForDemoRedirect(char(location));
    if redirect
        helpview(mapfile,topic);
    end
end

function displayWarningMessage(message, warnInDialog)
    if warnInDialog
        warndlg(getString(message), getString(message('MATLAB:web:DialogTitleWarning')));
    else
        warning(message);
    end
end
