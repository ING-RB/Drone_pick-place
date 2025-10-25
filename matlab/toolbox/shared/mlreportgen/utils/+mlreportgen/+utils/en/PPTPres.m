classdef PPTPres< mlreportgen.utils.internal.OfficeDoc
%mlreportgen.utils.PPTPres  Wraps a PowerPoint presentation file
%
%   mlreportgen.utils.PPTPres(FILENAME) wraps FILENAME in a Powerpoint
%   presentation. There can be only one PPTPres for FILENAME.
%
%   PPTPres properties:
%
%       FileName    - Full path to Powerpoint presentation
%
%   PPTPres methods:
%
%       show            - Show Powerpoint presentation
%       hide            - Hide Powerpoint presentation
%       close           - Close Powerpoint presentation
%       save            - Save Powerpoint presentation
%       print           - Print Powerpoint presentation
%       exportToPDF     - Export to PDF file
%       isOpen          - Is Powerpoint presentation open?
%       isReadOnly      - Is Powerpoint presentation readonly?
%       isSaved         - Is Powerpoint presentation saved?
%       isVisible       - Is Powerpoint presentation visible?
%       netobj          - Return a NET Powerpoint presentation object
%
%   Reference:
%
%       https://docs.microsoft.com/en-us/office/vba/api/overview/powerpoint
%
%   See also PPTApp, powerpoint, pptview

     
    %   Copyright 2017-2021 The MathWorks, Inc.

    methods
        function out=PPTPres
            %PPTPres    Construct a PPTPres
            %   pptPres = mlreportgen.utils.PPTPres(FILENAME) constructs a
            %   PPTPres object that wraps FILENAME Powerpoint presentation. If 
            %   there are other PPTPres object that wraps FILENAME, then throws 
            %   an error.
        end

        function out=close(~) %#ok<STOUT>
            %close Closes PowerPoint presentation
            %   close(pptPres) closes PowerPoint presentation (PPT) file 
            %   wrapped by pptPres.
        end

        function out=controller(~) %#ok<STOUT>
        end

        function out=createNETObj(~) %#ok<STOUT>
        end

        function out=exportToPDF(~) %#ok<STOUT>
            %exportToPDF    Export to PDF file
            %   pdfFullPath = exportToPDF(pptPres) exports Powerpoint presentation 
            %   to a PDF file with the same name as the Powerpoint presentation and 
            %   returns the PDF full file path.
            %
            %   pdfFullPath = exportToPDF(pptPres, pdfFileName) exports Powerpoint 
            %   presentation to a PDF file using pdfFileName as the name and 
            %   returns the PDF full file path.
        end

        function out=flushNETObj(~) %#ok<STOUT>
        end

        function out=hide(~) %#ok<STOUT>
            %hide   Hide Powerpoint presentation
            %   hide(pptPres) hides Powerpoint presentation by minimizing it.  
            %   Powerpoint NET API does not allow for Powerpoint to become 
            %   invisible after it has been visible.
        end

        function out=isReadOnly(~) %#ok<STOUT>
            %isReadOnly Is Powerpoint presentation read only?
            %   tf = isReadOnly(pptPres) returns true if Powerpoint presentation
            %   is read only and returns false if Powerpoint presentation is 
            %   writable.
        end

        function out=isSaved(~) %#ok<STOUT>
            %isReadOnly Is Powerpoint presentation saved?
            %   tf = isSaved(pptPres) returns true if Powerpoint presentation
            %   is saved and returns false if Powerpoint presentation is 
            %   not saved.
        end

        function out=isVisible(~) %#ok<STOUT>
            %isVisible  Is Powerpoint presentation visible?
            %   tf = isVisible(pptPres) returns true if visible and returns
            %   false if invisible/minimize.
        end

        function out=show(~) %#ok<STOUT>
            %show   Show PowerPoint presentation
            %   show(pptPres) shows the PowerPoint presentation by making it
            %   visible.
        end

    end
end
