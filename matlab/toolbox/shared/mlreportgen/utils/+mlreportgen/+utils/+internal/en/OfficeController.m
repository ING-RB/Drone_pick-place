classdef OfficeController< handle
%mlreportgen.utils.internal.OfficeController  Office Controller
%   Abstract class for handling interactions between 
%   OfficeApp and OfficeDoc.
%
%   OfficeController properties:
%
%       Name            - Name of office application
%       FileExtensions  - Support office file extentions
%
%   OfficeController methods:
%
%       instance        - Return instance of OfficeController
%       start           - Start office application
%       load            - Load office document
%       open            - Open office application/document
%       close           - Close office application/document
%       closeAll        - Close all office documents
%       closeApp        - Close office application
%       closeDoc        - Close office document
%       show            - Show office application/document
%       hide            - Hide office application/document
%       filenames       - Return an array of opened filenames
%       isAvailable     - If Office application available
%       isStarted       - Office application started?
%       isLoaded        - Office document loaded?
%       app             - Return OfficeApp object
%       doc             - Return OfficeDoc object
%
%   See also WordController, PPTController

     
    %   Copyright 2018-2022 The MathWorks, Inc.

    methods
        function out=OfficeController
        end

        function out=app(~) %#ok<STOUT>
            %wordapp    Return App object
        end

        function out=close(~) %#ok<STOUT>
            %close  Close application/doc
        end

        function out=closeAll(~) %#ok<STOUT>
            %closeAll   Close all Word document files
        end

        function out=closeApp(~) %#ok<STOUT>
            %closeApp   Close application
        end

        function out=closeDoc(~) %#ok<STOUT>
            %closeDoc   Close doc
        end

        function out=doc(~) %#ok<STOUT>
            %worddoc	Return doc object
        end

        function out=filenames(~) %#ok<STOUT>
            %filenames  Return an array of opened filenames
        end

        function out=hide(~) %#ok<STOUT>
            %hide   Hide application/doc
        end

        function out=isLoaded(~) %#ok<STOUT>
            %isLoaded   Is doc loaded?
        end

        function out=isStarted(~) %#ok<STOUT>
            %isStarted  Application started?
        end

        function out=load(~) %#ok<STOUT>
            %load   Load doc
        end

        function out=open(~) %#ok<STOUT>
            %open   Open doc
        end

        function out=show(~) %#ok<STOUT>
            %show   Show application/doc
        end

        function out=start(~) %#ok<STOUT>
            %start  Start app
        end

    end
    properties
        FileExtensions;

        Name;

    end
end
