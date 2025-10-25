classdef PDFDoc< handle
%mlreportgen.utils.PDFDoc  Wraps a PDF file for viewing
%
%   h = mlreportgen.utils.PDFDoc(FILENAME) creates a PDF Doc object for
%   FILENAME. PDFDoc is not visible on construction.  To make it visible,
%   call the "show" method.
%
%   PDFDoc properties
%
%       FileName    - Full path to a PDF file
%
%   PDFDoc methods:
%
%       show        - Show PDF file
%       hide        - Hide PDF file
%       isVisible   - Is PDF file visible?

     
    %   Copyright 2017-2022 The MathWorks, Inc.

    methods
        function out=PDFDoc
        end

        function out=close(~) %#ok<STOUT>
            %close  Close PDF file
            %   close(pdfDoc) closes PDF file.  PDFDoc cannot be
            %   reopened.  A new PDFDoc must be created.
        end

        function out=delete(~) %#ok<STOUT>
        end

        function out=hide(~) %#ok<STOUT>
            %open Hide PDF file
            %    hide(pdfDoc) hides PDF file by making it invisible.
        end

        function out=isOpen(~) %#ok<STOUT>
            %isOpen    Is PDF file opened?
            %   tf = isOpen(pdfDoc) returns true if pdfDoc has not
            %   been closed and false if pdfDoc is closed.
        end

        function out=isVisible(~) %#ok<STOUT>
            %isVisible Is PDF file visible?
            %   tf = isVisible(pdfDoc) returns true if visible and returns
            %   false if invisible.
        end

        function out=show(~) %#ok<STOUT>
            %open Show PDF file
            %    show(pdfDoc) shows PDF file by making it visible.
        end

    end
    properties
        FileName;

    end
end
