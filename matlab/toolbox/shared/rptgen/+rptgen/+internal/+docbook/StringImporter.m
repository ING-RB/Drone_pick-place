classdef StringImporter
    %STRINGIMPORTER Create a DocBook simplelist element
    %   This class comprises static methods that convert character arrays
    %   into a DocBook node that honors line feeds.
    %
    %   StringImporter methods:
    %
    %    importHonorLineBreaks     - Create simplelist from char array
    %    importHonorLineBreaksNull - Return [] from empty char array
    %    importHonorLineBreaksPara - Return empty para from ''
    
    %    Copyright 2017-2020 Mathworks, Inc.
    
    methods (Static)
        
        function node = importHonorLineBreaks(d, theString)
            % importHonorLineBreaks Create markup that honors line feeds
            % node = importHonorLineBreaks(doc,string) converts string
            % into a DocBook node that honors line feeds. The doc
            % argument is an instance of rptgen.internal.docbook.Document
            % class. The string argument is the char array to be converted
            % If string contains line feeds, this method returns a
            % DocBook simplelist where each item is a token in the input
            % string. If the string argument is not empty and does not
            % contain line feeds, this method returns a Text node
            % containing the string. If string is empty, this method
            % returns an empty DocumentFragment
            %
            % @param d the parent document
            % @param theString the string to be parsed.
            % @return
            %
            node = rptgen.internal.docbook.StringImporter.importHonorLineBreaksImpl(d,theString,false);
        end
        
        
        function node = importHonorLineBreaksNull(d, theString)
            % importHonorLineBreaksNull Convert empty string to []
            % result = importHonorLineBreaks(doc,string) returns [] if
            % string is an empty char array. Otherwise, it has the same
            % output as importHonorLineBreaks.
            node = rptgen.internal.docbook.StringImporter.importHonorLineBreaksImpl(d,theString,true);
        end
        
        
        function element = importHonorLineBreaksPara(d, theString)
            % importHonorLineBreaksPara Convert string to para
            % para = importHonorLineBreaksPara(doc,string) converts
            % string to a DocBook para element if string is empty or does
            % not contain line feeds. Otherwise, it converts string to
            % DocBook simplelist element.
            stringContent = rptgen.internal.docbook.StringImporter.importHonorLineBreaksImpl(d,theString,false);
            if isa(stringContent,'matlab.io.xml.dom.Element')
                element = stringContent;
            else
                paraEl = createElement(d, "para");
                appendChild(paraEl,stringContent);
                element = paraEl;
            end
        end
        
    end
    
    methods (Static, Access = private)
        
        function node = importHonorLineBreaksImpl(d, theString, okNull)
            node = [];
            if isempty(theString)
                if ~okNull
                    node = createDocumentFragment(d);
                end
            else
                theString = string(theString);
                lines = split(theString,newline);
                nLines = numel(lines);
                if nLines > 1
                    parentElement = createElement(d,"simplelist");
                    setAttribute(parentElement,"type","vert");
                    parentElement.setAttribute("columns","1");
                    
                    itemElement = createElement(d,"member");
                    appendChild(itemElement, ...
                        createTextNode(d,lines(1)));
                    appendChild(parentElement,itemElement);
                    for i = 2:nLines                       
                        % I'd be interested to see if there is more processing we
                        % can do here.  Honor spaces if the first char is space or tab?
                        itemElement = createElement(d,"member");
                        appendChild(itemElement, ...
                            createTextNode(d,lines(i)));
                        appendChild(parentElement, itemElement);
                    end
                    
                    node = parentElement;
                else
                    if okNull && isempty(lines(1))
                        node = [];
                    else
                        %Note that this will strip any trailing \n.  This is ok.
                        node = createTextNode(d,lines(1));
                    end
                end
            end
        end
    end
    
    
end

