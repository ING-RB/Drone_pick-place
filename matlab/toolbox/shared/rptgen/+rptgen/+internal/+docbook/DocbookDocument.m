classdef DocbookDocument < matlab.io.xml.dom.Document
    %DocbookDocument Create an XML document of type DocBook
    %    obj = DocbookDocument() creates a document with a root node
    %    named "book".
    %    obj = DocbookDocument(rootName) creates a document with a root
    %    node named rootName.
    %
    %    DocbookDocument methods:
    
    %    Copyright 2020-2025 Mathworks, Inc.

    methods (Static)
        function v = PUBLIC_ID
            v = "-//OASIS//DTD DocBook XML V4.2//EN";
        end
        
        function systemID = SYSTEM_ID
            systemID = fullfile(matlabroot, 'sys/namespace/docbook/v4/dtd/docbookx.dtd');
            systemID = rptgen.internal.docbook.DocbookDocument.toURL(systemID);
        end

    end
    
    methods (Static,Access=private)
        
        function v = COMMENT_END
            v = "//EN'>";
        end
        
        function v = COMMENT_START
            v = "<!DOCTYPE";
        end
        
        
        function v = EL_TITLE
            v = "title";
        end

        function url = toURL(filepath)
            url = strrep(filepath,'\','/');
            url = strrep(url,' ','%20');
            if ispc
                url = ['file:/' url];
            else
                url = ['file://' url];
            end
        end
        
    end
    
    methods 
        
        function obj = DocbookDocument(rootName)
            import matlab.io.xml.dom.*
            
            if nargin < 1
                rootName = 'book';
            end
            
            systemID = fullfile(matlabroot, 'sys/namespace/docbook/v4/dtd/docbookx.dtd');
            systemID = rptgen.internal.docbook.DocbookDocument.toURL(systemID);
                      
            obj@matlab.io.xml.dom.Document(rootName, rootName,'',systemID);
        end
        
        function elem = createElement(obj, tagName, content)
            %createElement Creat an element and its content
            %   Detailed explanation goes here
            elem = createElement@matlab.io.xml.dom.Document(obj, tagName); 
            if nargin == 3
                appendChild(elem, createTextNode(obj, content));
            end
        end
  
        
    end
    
    methods (Static)
        
        function titleEl = setTitle(sectionNode, newTitle)
            import matlab.io.xml.dom.*
            
            persistent EL_TITLE
            
            if isempty(EL_TITLE)
                EL_TITLE = 'title';
            end
            
            if isa(sectionNode, 'matlab.io.xml.dom.Document')
                d = sectionNode;
                sectionNode = getDocumentElement(d);
            else
                d = getOwnerDocument(sectionNode);
            end
            
            if ~isa(newTitle, 'matlab.io.xml.dom.Node')
                newTitle = createTextNode(d, newTitle);
            end
            
            titleEl = matlab.io.xml.dom.Document.findElementShallow(sectionNode, EL_TITLE);
            
            if isempty(titleEl)
                %Create a title if one does not exist
                titleEl = createElement(d, EL_TITLE);
                insertBefore(sectionNode,titleEl, sectionNode.getFirstChild());
            else
                % Remove existing children
                existingChild = getFirstChild(titleEl);
                while ~isempty(existingChild)
                    removeChild(titleEl, existingChild);
                    existingChild = getFirstChild(titleEl);
                end
            end
            appendChild(titleEl, newTitle);
        end
        

     function fileChanged = enableDoctype(fileName, isEnabled)
     % Comments or uncomments the doctype from a serialized file.
     %
     % @param fileName = The name of the file to be changed
     % @param isEnabled = uncomments when true, comments when false
     % @returns whether or not the doctype was found and changed
     
        import rptgen.internal.docbook.DocbookDocument

        fileChanged = false;
        try 
            xmlFile = fopen(fileName,"r+",'native','utf-8');
        catch 
            return
        end

        try 
            commentStartIdx = 0;
            lineCount = 0; % If the doctype is not in the first 8 lines, it's not there at all
            while commentStartIdx < 1 && lineCount < 8 
                theLine = fgets(xmlFile);
                if ~isempty(theLine)
                    commentStartIdx = strfind(theLine,DocbookDocument.COMMENT_START);
                    if isempty(commentStartIdx)
                        commentStartIdx = 0;
                    end
                end
                
                if commentStartIdx > 0 
                    commentEndIdx = strfind(theLine(commentStartIdx:end),DocbookDocument.COMMENT_END);
                    if isempty(commentEndIdx)
                        commentEndIdx = 0;
                    end
                    
                    if (commentEndIdx > 0)
                        fseek(xmlFile,commentStartIdx-5,'bof');
                        if isEnabled
                            fwrite(xmlFile,'    ');
                        else
                            fwrite(xmlFile,'<!--');
                        end
                        fseek(xmlFile,commentEndIdx + strlength(DocbookDocument.COMMENT_END)-1,'cof');
                        if isEnabled
                            fwrite(xmlFile,'   ');
                        else
                            fwrite(xmlFile,'-->');
                        end
                        fileChanged = true;
                    end
                end
                lineCount = lineCount+1;
            end
            fclose(xmlFile);      
        catch ex
            rptgen.internal.gui.GenerationDisplayClient.staticAddMessage("Can not parse XML source file for document type.",2);
            rptgen.internal.gui.GenerationDisplayClient.staticAddMessage(ex.message,5);
            fclose(xmlFile);
        end
        
     end
        
    end
    
     methods (Static, Access=private)
         
         function childNode = findElementShallow(parentNode, elName)
             % Finds an element in a node that has the given name           
             childNode = getFirstChild(parentNode);
             while ~isempty(childNode)
                 if isa(childNode, 'matlab.io.xml.dom.Element') && ...
                         getNodeName(childNode) == string(elName)
                     return
                 end
                 childNode = getNextSibling(childNode);
             end
             childNode = [];
         end
    
     end
end

