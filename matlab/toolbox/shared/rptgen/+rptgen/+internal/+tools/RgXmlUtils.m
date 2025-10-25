classdef RgXmlUtils <handle
    %RGXMLUTILS XML utilities
    %   Provides a set of XML methods usefule for report generation.
    
    %   Copyright 2020 Mathworks, Inc.
    
    methods (Static)
        
        function txt = getNodeText(n)
            % Utility method
            % Returns the content of all Text nodes inside the Node.
            % Recurses into all other nodes.
            %
            % Not called from MATLAB as of 18 feb 2005.
            
            txt = getNodeText(n);
        end
        
        
        
        function getNodeTextStripWhitespace(n, b)
            % Utility method
            % Appends the content of all (recursive) text nodes inside
            % the Node.  Carriage returns are stripped from all Text.
            %
            % Not called from MATLAB as of 18 feb 2005.
            %
            b = string(b);
            if isempty(n)
                % noop
            elseif isa(n,'matlab.io.xml.dom.Text')
                s = getData(n);
                s = char(s);
                s = strrep(s,newline,' ');
                s = string(trim(strrep(s,char(9)," ")));
                b = b + s; %#ok<NASGU>
            else
                n = getFirstChild(n);
                while ~isempty(n)
                    getNodeTextStripWhitespace(n,b);
                    b = b + " "; % string trimming requires an extra space here to prevent run-together
                    n = getNextSibling(n);
                end
            end
        end
        
        function out = file2urn(fileName)
            % Utility method.  Converts string filename to a URN.
            %
            % @param   fileName
            % @return  Universal Resource Name
            %Note: backslash escapes to "\\"!
            
            out = rptgen.file2urn(fileName);
        end
        
        function out = urn2file(fileName)
            % Utility method.  Converts string URN to a filename.
            %
            % @param   fileName
            % @return  Universal Resource Name
            
            out = rptgen.urn2file(fileName);
            
        end
        
        function out = findFile(fileName)
            % Utility method.  Converts file to fullpath
            %
            % @param   fileName
            % @return  Universal Resource Name
            out = rptgen.findFile(fileName);
        end
        
        function out = getToolboxDir(name)
            out = toolboxdir(name);
        end
        
        function removeAllChildren(parentNode)
            % Utility method.  Removes all children from parent node.
            % @param parentNode
            childNode = getFirstChild(parentNode);
            while ~isempty(childNode)
                removeChild( parentNode,childNode);
                childNode = getFirstChild(parentNode);
            end
        end
        
        
        
        
        function elem = findFirstElementByTagName(thisNode, tagName)
            % Utility method.
            % Returns null if the element does not exist as an immediate child
            %
            % Not called from MATLAB as of 18 feb 2005.
            %
            % @param thisNode
            % @return The first child element whose tag name matches tagName
            if isempty(thisNode)
                elem = [];
            else
                elem = findNextElementByTagName(getFirstChild(thisNode), tagName);
            end
        end
        
        
        
        
        function elem = findNextElementByTagName(n,tagName)
            % Utility method.  Finds a sibling element with the tag name.
            % Returns null if one was not found.
            %
            % Note that looking for tag names is case-insensitive.  This is technically
            % not kosher with the XML spec, but I am using this method to parse old
            % SGML files as well as newer XML files and want the same code to work for both.
            if isempty(tagName); elem = []; return; end
            
            while ~isempty(n)
                if isa(n,'matlab.io.xml.dom.Element') && ...
                        getTagName(n) == string(tagName)
                    break
                else
                    n = getNextSibling(n);
                end
            end
            elem = n;
        end
                
        function newEl = createElement(d,tagName,data)
            % @param d the parent document to use
            % @param tagName
            % @param data
            % @return An element with tagName and a single text node with string data
            newEl = createElement(d,tagName);
            appendChild(newEl,createTextNode(d,data));
        end
            
        function newEl = appendElement(n,tagName,data)
            % Creates a new Element and appends it to Node n
            % @param n
            % @param tagName the tag name of the new Element
            % @param data the string content of the new Element
            % @return the created element
            newEl = createElement(getOwnerDocument(n),tagName,data);
            appendChild(n,newEl);
        end
        
    end
end

