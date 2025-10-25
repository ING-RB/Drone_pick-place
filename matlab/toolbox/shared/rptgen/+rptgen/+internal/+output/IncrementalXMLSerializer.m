classdef IncrementalXMLSerializer < handle
    %INCREMENTALXMLSERIALIZER Serialize a report's XML DOM.
    %   An instance of this class is invoked by a Chapter/Section
    %   component to output the XML DOM for that section as a file.
    %   As a final step in report generation, the
    %   rptgen.internal.document.EntityManager creates a root file
    %   with file entity references to the section files.
    %
    %   See also rptgen.internal.document.EntityManager
    
    %   Copyright 2020 The MathWorks, Inc.
    
    properties
        OwnerDoc
        Writer
        Serializer
        DocumentType
        RootElementWritten
        ContentWritten logical = false;
    end
    
    methods
        
        function obj = IncrementalXMLSerializer(ownerDoc, fileName, ...
                fileEncoding)
            import matlab.io.xml.dom.*
            
            % Create a writer that outputs strings to a file.
            obj.Writer = FileWriter(fileName, fileEncoding);
            
            % Create an XML DOM serializer that uses the file writer
            % to output the XML markup that it generates from DOM objects.
            % This allows the IncrementalSerializer to include its own
            % XML markup in the XML markup output stream.
            obj.Serializer = DOMWriter;
            
            obj.OwnerDoc = ownerDoc;
        end
        
        function writeXMLHeader(obj)
            try
                write(obj.Writer, ...
                    sprintf( '<?xml version="1.0" encoding="%s"?>\n', ...
                    obj.Writer.FileEncoding));
            catch ME
                rptgen.internal.gui.GenerationDisplayClient.staticAddMessageMultiLine(ME.message, 1);
            end
        end
        
        function tf = openRootElement(obj, docType, attributeValues)
            obj.DocumentType = string(docType);
            obj.RootElementWritten = ~(isempty(docType) || ...
                obj.DocumentType == "none" || obj.DocumentType == "ignore");
            
            tf = obj.RootElementWritten;
            if obj.RootElementWritten
                try
                    write(obj.Writer, "<");
                    write(obj.Writer, obj.DocumentType);
                    if ~isempty(attributeValues)
                        n = numel(attributeValues)/2;
                        for  i = 1:n
                            j = 2*i-1;
                            write(obj.Writer, " ");
                            write(obj.Writer, attributeValues{j});
                            write(obj.Writer, '="');
                            flush(obj.Writer);
                            j=j+1;
                            write(obj.Writer, attributeValues{j});
                            write(obj.Writer, '"');
                        end
                    end
                    write(obj.Writer, ">"+newline);
                catch ME
                    % We weren't able to write anything.  Something is seriously wrong.
                    % Don't insert this section into the report.  Close off the streams.
                    throw ME;
                end
            end
        end
        
        function closeRootElement(obj)
            % This will also implicitly close all open streams.  No more write operations can
            % take place on this serializer after closing.
            try
                if obj.RootElementWritten
                    write(obj.Writer, "</");
                    write(obj.Writer, obj.DocumentType);
                    write(obj.Writer, ">" + newline);
                end
            catch ME
                rptgen.internal.gui.GenerationDisplayClient.staticAddMessageMultiLine(ME.message,1)
            end
        end
        
        function tf = write(obj, node)
            import rptgen.internal.output.IncrementalXMLSerializer
            tf = false;
            if isempty(node)
                return
            end
            try
                switch class(node)
                    case {'matlab.io.xml.dom.Text', ...
                            'matlab.io.xml.dom.Element', ...
                            'matlab.io.xml.dom.EntityReference'}
                        tf = true;
                        obj.ContentWritten = true;
                    case 'matlab.io.xml.dom.DocumentFragment'
                        if IncrementalXMLSerializer.hasWritableContent(node)
                            tf = true;
                            obj.ContentWritten = true;
                        end
                    case {'matlab.io.xml.dom.ProcessingInstruction', ...
                            'matlab.io.xml.dom.Comment'}
                        tf = true;
                end
                write(obj.Serializer,node,obj.Writer);
            catch ME
                tf = false;
                rptgen.internal.gui.GenerationDisplayClient.staticAddMessageMultiLine(ME.message);
            end
        end
        
         
        function tf = writeText(obj,textVal)
            tf = false;
            if ~isempty(textVal)
                if ~isa(textVal, 'matlab.io.xml.dom.Text')
                    textNode = createTextNode(obj.OwnerDoc,textVal);
                end
                tf = write(obj,textNode);
            end
        end
        
        function tf = writeProcessingInstruction(obj, piName, piValue)
            tf = false;
            if ~isempty(piName) && ~isempty( piValue)
                % processing instructions need to be on a new line
                tf = write(obj, ...
                    createProcessingInstruction(obj.OwnerDoc, ...
                    piName, piValue));
                write(obj.Writer,newline);
            end
        end
        
        function tf = writeComment(obj, commentText)
            tf = false;
            if ~isempty(commentText)
                tf = write(obj,createComment(obj.OwnerDoc,commentText));
            end
        end
        
        function tf = wasContentWritten(obj)
            % @return true if any Element, Text, or DocumentFragment nodes were written
            %         using the "write" methods.
            tf = obj.ContentWritten;
        end
               
        function resetContentWritten(obj)
            % Sets the wasContentWritten flag to false.
            obj.ContentWritten = false;
        end
        
    end
    
    methods (Static,Access=private)
        
        function tf = hasWritableContent(node)
            % Returns true if there is at least one descendant that is not
            % a comment or a document fragment
            tf = false;
            n = node;
            while ~isempty(n)
                if ~isa(n,'matlab.io.xml.dom.Comment') && ...
                        ~isa(n,'matlab.io.xml.dom.DocumentFragment')
                    tf = true;
                    break
                else
                    if n.HasChildNodes
                        tf = rptgen.internal.output.IncrementalXMLSerializer.hasWritableContent(getFirstChild(n));
                    end
                end
                n = getNextSibling(n);
            end
            
        end
        
    end
    
end

