classdef OfficeDoc< handle
%mlreportgen.utils.Office  Wraps an Office document 
%
%   Abstract base class for WordDoc and PPTPres
%
%   OfficeDoc properties:
%
%       FileName            - Full path to document file
%       FileExtensions      - Supported document file extensions
%
%   OfficeDoc methods:
%
%       show                - Show document
%       hide                - Hide document
%       close               - Close document
%       save                - Save document
%       print               - Print document
%       exportToPDF         - Export to PDF file
%       isOpen              - Is document open?
%       isReadOnly          - Is document readonly?
%       isSaved             - Is document saved?
%       isVisible           - Is document visible?
%       netobj              - Return a NET object
%       createNETObj        - Construct NET object
%       controller          - Get OfficeController
%
%   See also WordDoc, PPTPres

     
    %   Copyright 2018-2021 The MathWorks, Inc.

    methods
        function out=OfficeDoc
        end

        function out=clearNETObj(~) %#ok<STOUT>
        end

        function out=delete(~) %#ok<STOUT>
            %delete Delete OfficeDoc
            %   delete(officeDoc) closes Office document and deletes OfficeDoc object
        end

        function out=executeWithRetries(~) %#ok<STOUT>
        end

        function out=flush(~) %#ok<STOUT>
        end

        function out=isOpen(~) %#ok<STOUT>
            %isOpen	Is Office document open?
            %   tf = isOpen(officeDoc) returns true if Office document is opened and
            %   returns false if Office document is closed.
        end

        function out=netobj(~) %#ok<STOUT>
            %netobj     Return a NET object
            %   netObj = netobj(officeDoc) returns NET object.  If office
            %   document is closed, then throws an error.
        end

        function out=print(~) %#ok<STOUT>
            %print  Print Office document
            %   print(officeDoc) prints Office document.
        end

        function out=resetNETObj(~) %#ok<STOUT>
        end

        function out=save(~) %#ok<STOUT>
            %save	Save Office document
            %   save(officeDoc) saves Office document.
        end

    end
    properties
        FileName;

    end
end
