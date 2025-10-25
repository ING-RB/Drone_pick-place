classdef word< handle
%mlreportgen.utils.word  Word interface
%
%   word methods:
%
%	start       - Start Word
%   load        - Load a Word document file
%   open        - Open a Word document file
%   close       - Close Word application/document file
%   closeAll    - Close all Word document files
%   show        - Show Word application/document file
%   hide        - Hide Word application/document file
%   filenames   - Return an array of opened filenames
%   isAvailable - Word available for use?
%   isStarted   - Word started?
%   isLoaded    - Word document file loaded?
%   wordapp     - Return WordApp object
%   worddoc     - Return WordDoc object
%
%   See also WordDoc, WordApp, docview

     
    %   Copyright 2018-2024 The MathWorks, Inc.

    methods
        function out=word
        end

        function out=close(~) %#ok<STOUT>
            %mlreportgen.utils.word.close    Close Word application/document
            %   tf = mlreportgen.utils.word.close() closes Word application 
            %   only if there are no unsaved Word documents. Returns true 
            %   if Word application is closed and returns false if Word 
            %   application is opened.
            %
            %   tf = mlreportgen.utils.word.close(true) closes Word application 
            %   only if there are no unsaved Word documents or there are no Word
            %   documents opened outside of MATLAB. Returns true if Word application 
            %   is closed and returns false if Word application is opened.
            %
            %   tf = mlreportgen.utils.word.close(false) closes Word application 
            %   even if there are unsaved Word documents and if there are Word 
            %   documents opened outside of MATLAB. Returns true if Word application 
            %   is closed and returns false if Word application is opened.
            %
            %   tf = mlreportgen.utils.word.close(FILENAME) closes Word document 
            %   FILENAME only if there are no unsaved changes. Hides word 
            %   application if there are no other opened Word documents. Returns 
            %   true if Word document is closed and returns false if Word document
            %   is opened. 
            %
            %   tf = mlreportgen.utils.word.close(FILENAME, true) closes Word 
            %   document FILENAME only if there are no unsaved changes. Hides word 
            %   application if there are no other opened Word documents. Returns 
            %   true if Word document is closed and returns false if Word document 
            %   is opened. 
            %
            %   tf = mlreportgen.utils.word.close(FILENAME, false) closes Word
            %   document FILENAME even if there are unsaved changes. Hides word 
            %   application if there are no other opened Word documents. Returns 
            %   true if Word document is closed and returns false if Word document
            %   is opened. 
            %
            %   See also WordDoc, WordApp
        end

        function out=closeAll(~) %#ok<STOUT>
            %mlreportgen.utils.word.closeAll Close all Word document files
            %   tf = mlreportgen.utils.word.closeAll() closes all Word document files
            %   and hides the Word application. Returns true all Word document files
            %   are closed and false if any Word document files are opened. 
            %
            %   tf = mlreportgen.utils.word.closeAll(true) closes all Word 
            %   documents files only if there are no unsaved changes. Hides word 
            %   application if there are no other opened Word documents. Returns 
            %   true if all Word document files are closed and returns false if 
            %   any Word document are opened.
            %
            %   tf = mlreportgen.utils.word.closeAll(false) closes Word
            %   document files even if there are unsaved changes. Hides word 
            %   application if there are no other opened Word documents. Returns 
            %   true if all Word document files are closed and returns false if 
            %   any Word document are opened.
            %
            %   See also WordDoc, WordApp
        end

        function out=filenames(~) %#ok<STOUT>
            %mlreportgen.utils.word.filenames	Return an array of opened filenames
            %   FILES = mlreportgen.utils.word.filenames() returns a string array of
            %   Word document filenames.
            %
            %   See also WordDoc, WordApp
        end

        function out=hide(~) %#ok<STOUT>
            %mlreportgen.utils.word.hide    Hide Word application/document file
            %   WordApp = mlreportgen.utils.word.hide() hides Word application by 
            %   making it invisible and returns the WordApp object.
            %
            %   WordDoc = mlreportgen.utils.word.hide(FILENAME) hides Word document
            %   FILENAME by making it invisible and returns the WordDoc object.
            %
            %   See also WordDoc, WordApp
        end

        function out=isAvailable(~) %#ok<STOUT>
            %mlreportgen.utils.word.isAvailable	Word available for use?
            %   tf = mlreportgen.utils.word.isAvailable() returns true if Word
            %   is available for use and returns false if Word is not available
            %   for use.
            %
            %   See also WordApp
        end

        function out=isLoaded(~) %#ok<STOUT>
            %mlreportgen.utils.word.isLoaded	Is Word document loaded?
            %   tf = mlreportgen.utils.word.isLoaded(FILENAME) returns true if 
            %   Word document FILENAME is loaded and returns false if Word 
            %   document FILENAME is not loaded.
            %
            %   See also WordDoc
        end

        function out=isStarted(~) %#ok<STOUT>
            %mlreportgen.utils.word.isStarted   Word started?
            %   tf = mlreportgen.utils.word.isStarted() returns true if Word has
            %   been started and returns false, if Word has not been started.
            %
            %   See also WordApp
        end

        function out=load(~) %#ok<STOUT>
            %mlreportgen.utils.word.load	Load a Word document file
            %   WordDoc = mlreportgen.utils.word.load(FILENAME) loads Word document
            %   FILENAME and returns a WordDoc object.
            %
            %   See also WordDoc
        end

        function out=open(~) %#ok<STOUT>
            %mlreportgen.utils.word.open    Open Word document file
            %   WordDoc = mlreportgen.utils.word.open(FILENAME) loads Word 
            %   document FILENAME, makes it visible, and returns a WordDoc 
            %   object.
            %
            %   See also WordDoc
        end

        function out=show(~) %#ok<STOUT>
            %mlreportgen.utils.word.show    Show Word application/document file
            %   WordApp = mlreportgen.utils.word.show() shows Word by making
            %   it visible and returns the WordApp object.
            %
            %   WordDoc = mlreportgen.utils.word.show(FILENAME) shows Word document
            %   FILENAME by making it visible and returns the WordDoc object.
            %
            %   See also WordDoc, WordApp
        end

        function out=start(~) %#ok<STOUT>
            %mlreportgen.utils.word.start	Start Word
            %   WordApp = mlreportgen.utils.word.start() starts Word if it has
            %   not been started already, and returns the WordApp object.  Word
            %   will be invisible.
            %
            %   See also WordApp
        end

        function out=wordapp(~) %#ok<STOUT>
            %mlreportgen.utils.word.wordapp     Return WordApp object
            %   wordApp = mlreportgen.utils.word.wordapp() returns a WordApp object
            %   if Word is not started, then throw an error.
            %
            %   See also WordApp
        end

        function out=worddoc(~) %#ok<STOUT>
            %mlreportgen.utils.word.worddoc     Return WordDoc object
            %   wordDoc = mlreportgen.utils.word.worddoc(FILENAME) returns a
            %   WordDoc object that wraps FILENAME.  If FILENAME is not opened,
            %   then throw an error.
            %
            %   See also WordDoc
        end

    end
end
