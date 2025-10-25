classdef powerpoint< handle
%mlreportgen.utils.powerpoint  Powerpoint interface
%
%   powerpoint methods:
%
%	start       - Start Powerpoint
%   load        - Load a Powerpoint presentation
%   open        - Open a Powerpoint presentation
%   close       - Close Powerpoint application/presentation
%   closeAll    - Close all Powerpoint presentations
%   show        - Show Powerpoint application/presentation
%   hide        - Hide Powerpoint application/presentation
%   filenames   - Return an array of opened presentations
%   isAvailable - Powerpoint available for use?
%   isStarted   - Powerpoint started?
%   isLoaded    - Powerpoint presentation file loaded?
%   pptapp      - Return PPTApp object
%   pptpres     - Return PPTPres object
%
%   See also PPTPres, PPTApp, pptview

     
    %   Copyright 2018-2024 The MathWorks, Inc.

    methods
        function out=powerpoint
        end

        function out=close(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.close	Close Powerpoint application/presentation
            %   tf = mlreportgen.utils.powerpoint.close() closes Powerpoint
            %   application only if there are no unsaved Powerpoint presentations.
            %   Returns true if Powerpoint application is closed and returns false 
            %   if Powerpoint application is opened.
            %
            %   tf = mlreportgen.utils.powerpoint.close(true) closes Powerpoint 
            %   application only if there are no unsaved Powerpoint presentation 
            %   or there are no Powerpoint presentation opened outside of MATLAB. 
            %   Returns true if Powerpoint application is closed and returns false 
            %   if Powerpoint application is opened.
            %
            %   tf = mlreportgen.utils.powerpoint.close(false) closes Powerpoint
            %   application even if there are unsaved Powerpoint presentation 
            %   and if there are Powerpoint presentations opened outside of MATLAB. 
            %   Returns true if Powerpoint application is closed and returns false 
            %   if Powerpoint application is opened.
            %
            %   tf = mlreportgen.utils.powerpoint.close(FILENAME) closes Powerpoint
            %   presentation FILENAME only if there are no unsaved changes. Hides 
            %   Powerpoint application if there are no other opened Powerpoint
            %   presentations. Returns true if Powerpoint presentation is closed 
            %   and returns false if Powerpoint presentation is opened. 
            %
            %   tf = mlreportgen.utils.powerpoint.close(FILENAME, true) closes 
            %   Poweroint presentation FILENAME only if there are no unsaved 
            %   changes. Hides Powerpoint application if there are no other opened 
            %   Powerpoint presentations. Returns true if Powerpoint presentation
            %   is closed and returns false if Powerpoint presentation is opened. 
            %
            %   tf = mlreportgen.utils.powerpoint.close(FILENAME, false) closes
            %   Powerpoint presentation FILENAME even if there are unsaved changes. 
            %   Hides Powerpoint application if there are no other opened Powerpoint 
            %   presentations. Returns true if Powerpoint presentation is closed and 
            %   returns false if Powerpoint presentation is opened. 
            %
            %   See also PPTPres, PPTApp
        end

        function out=closeAll(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.closeAll	Close all Powerpoint presentation files
            %   tf = mlreportgen.utils.powerpoint.closeAll() closes all Powerpoint 
            %   presentation files and hides the Powerpoint application. Returns true 
            %   all Powerpoint presentation files are closed and false if any Powerpoint 
            %   presentation files are opened. 
            %
            %   tf = mlreportgen.utils.powerpoint.closeAll(true) closes all Powerpoint
            %   presentation files only if there are no unsaved changes. Hides 
            %   Powerpoint application if there are no other opened Powerpoint 
            %   presentations. Returns true if all Powerpoint presentation files are 
            %   closed and returns false if any Powerpoint presentations are opened.
            %
            %   tf = mlreportgen.utils.powerpoint.closeAll(false) closes all Powerpoint
            %   presentations even if there are unsaved changes. Hides Powerpoint
            %   application if there are no other opened Powerpoint presentations. 
            %   Returns true if all Powerpoint presentations are closed and returns 
            %   false if any Powerpoint presentations are opened.
            %
            %   See also PPTPres, PPTApp
        end

        function out=filenames(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.filenames	Return an array of opened presentation
            %   FILES = mlreportgen.utils.powerpoint.filenames() returns a string
            %   array of Powerpoint presentation filenames.
            %
            %   See also PPTPres, PPTApp
        end

        function out=hide(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.hide    Hide Powerpoint application/presentation
            %   PPTApp = mlreportgen.utils.powerpoint.hide() hides Powerpoint 
            %   application by making it invisible and returns the PPTApp 
            %   object.
            %
            %   PPTPres = mlreportgen.utils.powerpoint.hide(FILENAME) hides Powerpoint
            %   presentation FILENAME by making it invisible and returns the 
            %   PPTPres object.
            %
            %   See also PPTPres, PPTApp
        end

        function out=isAvailable(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.isAvailable     Powerpoint available for use?
            %   tf = mlreportgen.utils.powerpoint.isAvailable() returns true if 
            %   Powerpoint is available for use and returns false if Powerpoint 
            %   is not available for use.
            %
            %   See also PPTApp
        end

        function out=isLoaded(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.isLoaded	Is Powerpoint presentation loaded?
            %   tf = mlreportgen.utils.powerpoint.isLoaded(FILENAME) returns 
            %   true if Powerpoint presentation FILENAME is loaded and returns 
            %   false if Powerpoint presentation FILENAME is not loaded.
            %
            %   See also PPTPres
        end

        function out=isStarted(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.isStarted   Powerpoint started?
            %   tf = mlreportgen.utils.powerpoint.isStarted() returns true if 
            %   Powerpoint has been started and returns false, if Powerpoint 
            %   has not been started.
            %
            %   See also PPTApp
        end

        function out=load(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.load	Load a Powerpoint presentation
            %   PPTPres = mlreportgen.utils.powerpoint.load(FILENAME) loads 
            %   Powerpoint presentation FILENAME and returns a PPTPres object.
            %
            %   See also PPTPres
        end

        function out=open(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.open	Open Powerpoint presentation
            %   PPTPres = mlreportgen.utils.powerpoint.open(FILENAME) loads 
            %   Powerpoint presentation FILENAME, makes it visible, and 
            %   returns a PPTPres object.
            %
            %   See also PPTPres
        end

        function out=pptapp(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.pptapp     Return PPTApp object
            %   pptApp = mlreportgen.utils.powerpoint.pptapp() returns a 
            %   PPTApp object if Powerpoint is started, and throw an 
            %   error if Powerpoint is not started.
            %
            %   See also PPTApp
        end

        function out=pptpres(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.pptpres     Return PPTPres object
            %   pptPres = mlreportgen.utils.powerpoint.pptpres(FILENAME) 
            %   returns a PPTPres object that wraps FILENAME.  If FILENAME 
            %   is not opened, then throw an error.
            %
            %   See also PPTPres
        end

        function out=show(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.show    Show Powerpoint application/presentation
            %   PPTApp = mlreportgen.utils.powerpoint.show() shows Powerpoint
            %   by making it visible and returns the PPTApp object.
            %
            %   PPTPres = mlreportgen.utils.powerpoint.show(FILENAME) shows 
            %   Powerpoint presentation FILENAME by making it visible and 
            %   returns the PPTPres object.
            %
            %   See also PPTPres, PPTApp
        end

        function out=start(~) %#ok<STOUT>
            %mlreportgen.utils.powerpoint.start	Start Powerpoint
            %   pptApp = mlreportgen.utils.powerpoint.start() starts Powerpoint
            %   if it has not been started already, and returns the Powerpoint
            %   PPTApp object.  Powerpoint will be invisible.
            %
            %   See also PPTApp
        end

    end
end
