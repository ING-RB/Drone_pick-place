classdef rptviewer< handle
%mlreportgen.utils.rptviewer	Report document viewer manager
%
%   Manages viewers by opening and closing viewers for a given FILENAME.
%
%   rptviewer methods:
%
%       open        - Open a viewer
%       close       - Close a viewer
%       isOpen      - Is file open in a viewer?
%       closeAll	- Close all opened viewers
%
%   Example:
%
%       % Open filename 
%       mlreportgen.utils.rptviewer.open(filename)
%       % Close filename
%       mlreportgen.utils.rptviewer.close(filename)    
%
%   See also word, powerpoint, WordDoc, PPTPres, PDFDoc, HTMLDoc, HTMXDoc

     
    %   Copyright 2017-2019 The MathWorks, Inc.

    methods
        function out=close(~) %#ok<STOUT>
            %close  Close a viewer
            %   mlreportgen.utils.rptviewer.close(FILENAME) closes the viewer for
            %   FILENAME.
        end

        function out=closeAll(~) %#ok<STOUT>
            %closeAll   Close all opened viewers
            %   mlreportgen.utils.rptviewer.closeAll() closes all viewers that
            %   were created.
        end

        function out=isOpen(~) %#ok<STOUT>
            %isOpen	Is file open in a viewer?
            %   tf = mlreportgen.utils.rptviewer.isOpen(FILENAME) returns true
            %   if FILENAME is assigned to a viewer and returns false otherwise.
        end

        function out=open(~) %#ok<STOUT>
            %open   Open a viewer
            %   mlreportgen.utils.rptviewer.open(FILENAME) opens FILENAME in an
            %   appropriate viewer.
        end

    end
end
