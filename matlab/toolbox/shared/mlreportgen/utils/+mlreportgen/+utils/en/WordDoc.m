classdef WordDoc< mlreportgen.utils.internal.OfficeDoc
%mlreportgen.utils.WordDoc  Wraps a Word document
%
%   mlreportgen.utils.WordDoc(FILENAME) wraps FILENAME in a Word document.
%   There can only be one WordDoc for FILENAME.
%
%   WordDoc properties:
%
%       FileName    - Full path to Word document file
%
%   WordDoc methods:
%
%       show                - Show Word document
%       hide                - Hide Word document
%       close               - Close Word document
%       save                - Save Word document
%       update              - Update Word document fields
%       print               - Print Word document
%       saveAsDoc           - Save as DOC file
%       saveAsText          - Save as text file
%       exportToPDF         - Export to PDF file
%       unlinkFields        - Unlink subdocuments
%       unlinkSubdocuments  - Unlink subdocuments
%       isOpen              - Is Word document open?
%       isReadOnly          - Is Word document readonly?
%       isSaved             - Is Word document saved?
%       isVisible           - Is Word document visible?
%       netobj              - Return a NET Word document object
%
%   Reference:
%
%       https://docs.microsoft.com/en-us/office/vba/api/overview/word
%
%   See also WordApp, word, docview

     
    %   Copyright 2017-2023 The MathWorks, Inc.

    methods
        function out=WordDoc
            %WordDoc    Construct a WordDoc
            %   wordDoc = mlreportgen.utils.WordDoc(FILENAME) constructs a
            %   WordDoc object that wraps FILENAME Word document. If there are
            %   other WordDoc object that wraps FILENAME, then throws an error.
        end

        function out=close(~) %#ok<STOUT>
            %close  Close Word document
            %   tf = close(wordDoc) closes Word document only if there are no unsaved
            %   changes. Returns true if Word document is closed and false if Word
            %   document is opened.
            %
            %   tf = close(wordDoc,true) closes Word document only if there are no 
            %   unsaved changes. Returns true if Word document is closed and false if 
            %   Word document is opened.
            %
            %   tf = close(wordDoc,false) closes Word document even if there are 
            %   unsaved changes. Returns true if Word document is closed and false if 
            %   Word document is opened.
        end

        function out=controller(~) %#ok<STOUT>
        end

        function out=createNETObj(~) %#ok<STOUT>
        end

        function out=exportToPDF(~) %#ok<STOUT>
            %exportToPDF    Export to PDF file
            %   pdfFullPath = exportToPDF(wordDoc) exports Word document to a
            %   PDF file with the same name as the Word document and returns the
            %   PDF full file path.
            %
            %   pdfFullPath = exportToPDF(wordDoc,pdfFileName) exports Word document 
            %   to a PDF file using pdfFileName as the name and returns the PDF full
            %   file path.
        end

        function out=flushNETObj(~) %#ok<STOUT>
        end

        function out=hide(~) %#ok<STOUT>
            %hide   Hide Word document
            %   hide(wordDoc) hides Word document by making it invisible.
        end

        function out=isReadOnly(~) %#ok<STOUT>
            %isReadOnly	Is Word document read only?
            %   tf = isReadOnly(wordDoc) returns true if Word document is read only 
            %   and returns false if Word document is writable.
        end

        function out=isSaved(~) %#ok<STOUT>
            %isReadOnly Is Word document saved?
            %   tf = isSaved(wordDoc) returns true if Word document is saved
            %   and returns false if Word document is not saved.
        end

        function out=isVisible(~) %#ok<STOUT>
            %isVisible  Is Word document visible?
            %   tf = isVisible(wordDoc) returns true if visible and returns
            %   false otherwise
        end

        function out=print(~) %#ok<STOUT>
            %print  Print Word document
            %   print(wordDoc) prints the specified Word document and 
            %   does not scale the contents to fit to A4 or 8.5 by 11 
            %   paper sizes.
            %
            %   print(wordDoc,ScaleToFitPaper=true) prints the
            %   specified Word document and scales the contents to 
            %   fit to A4 or 8.5 by 11 paper sizes.
            %
            %   print(wordDoc,ScaleToFitPaper=false) prints the
            %   specified Word document and does not scale the contents to 
            %   fit to A4 or 8.5 by 11 paper sizes.
        end

        function out=saveAsDoc(~) %#ok<STOUT>
            %saveAsDoc    Save as DOC file
            %   docFullPath = saveAsDoc(wordDoc) saves Word document as a DOC
            %   file with the same name as the Word document.
            %
            %   docFullPath = saveAsDoc(wordDoc,docFileName) saves Word 
            %   document as a DOC file using docFileName as the name and returns
            %   the DOC full file path.
        end

        function out=saveAsText(~) %#ok<STOUT>
            %saveAsPDF    Save as Text file
            %   textFullPath = saveAsText(wordDoc) saves Word document as a
            %   text file with the same name as the Word document and returns the
            %   text full file path.
            %
            %   textFullPath = saveAsText(wordDoc,textFileName) saves Word document 
            %   as a text file using textFileName as the name and returns the text full
            %   file path.
        end

        function out=show(~) %#ok<STOUT>
            %show   Show Word document
            %   show(wordDoc) shows Word document by making it visible.
        end

        function out=unlinkFields(~) %#ok<STOUT>
            %unlinkFields   Remove links from fields
            %   unlinkFields(wordDoc) Remove links from all fields.
            %
            %   unlinkFields(wordDoc,fieldType1) Remove links from all instances of 
            %   fieldType1 fields.
            %
            %   unlinkFields(wordDoc,fieldType1,fieldType2) Remove links from all 
            %   instances of both fieldType1 and fieldType2 fields.
            %
            %   Reference:
            %
            %       https://msdn.microsoft.com/en-us/vba/word-vba/articles/wdfieldtype-enumeration-word
        end

        function out=unlinkSubdocuments(~) %#ok<STOUT>
            %unlinkSubdocuments	Unlink subdocuments
            %   unlinkSubdocuments(wordDoc) unlink subdocuments by removing all 
            %   subdocument links and copy them into the master document.
            %   
            %   unlinkSubdocuments(wordDoc,Show=true) shows the Word Document
            %   before unlink subdocuments. The Show option is true by
            %   default.
            %
            %   unlinkSubdocuments(wordDoc,Show=false) do not show the Word 
            %   Document before unlink subdocuments.  Warning.  MS Word may 
            %   appear hung if any modal dialogs are opened.
        end

        function out=update(~) %#ok<STOUT>
            %update Update Word document fields
            %   update(wordDoc) updates Word document fields.
            %
            %   update(wordDoc,true) force update Word document fields.
            %
            %   update(wordDoc,false,Show=true) do not force update Word
            %   document and show MS Word while updating Word document fields.
            %   The Show option is true by default.
            %
            %   update(wordDoc,false,Show=false) do not force update Word
            %   document and do not show MS Word while updating Word document 
            %   fields. Warning! MS Word may appear hung if any modal 
            %   dialogs are opened.
        end

    end
end
