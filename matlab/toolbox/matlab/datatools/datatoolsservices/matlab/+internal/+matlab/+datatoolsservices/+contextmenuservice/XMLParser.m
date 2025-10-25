classdef XMLParser
    %XMLPARSER is a static class that parses an XML file and constructs a 'struct'
    % datatype with the XML attributes and Children. This parser ignores any
    % text/comments in the XML file and looks up MessageID in resource
    % catalog for translation.

    % Copyright 2019-2021 The MathWorks, Inc.

    methods(Static)
        function parsedXML = parseXML(fileName)
            parsedXML = struct;
            if exist(fileName, 'file')
                % Use the MATLAB XML parser to get the XML tree
                tree = parseFile(matlab.io.xml.dom.Parser, fileName);
                try
                    parsedXML = internal.matlab.datatoolsservices.contextmenuservice.XMLParser.parseChildNodes(tree);
                catch e
                    error(e);
                end
            end
        end

        function children = parseChildNodes(parentNode)
            % Recurse over node children.
            children = [];
            if parentNode.hasChildNodes
                childNodes = parentNode.getChildNodes;
                numChildNodes = childNodes.getLength;
                children = struct( ...
                    'Name', {}, 'Attributes', {}, ...
                    'Children', {});
                index = 1;
                for count = 1:numChildNodes
                    childNode = childNodes.item(count-1);
                    nodeName = childNode.getNodeName;
                    if (~strcmp(nodeName, '#text') && ~strcmp(nodeName, '#comment'))
                        children(index) = internal.matlab.datatoolsservices.contextmenuservice.XMLParser.makeStructFromNode(childNode);
                        index = index + 1;
                    end
                end
            end
        end

        function nodeStruct = makeStructFromNode(theNode)
            % Create structure of node info.
            nodeStruct = struct( ...
                'Name', theNode.getNodeName, ...
                'Attributes', internal.matlab.datatoolsservices.contextmenuservice.XMLParser.parseAttributes(theNode), ...
                'Children', internal.matlab.datatoolsservices.contextmenuservice.XMLParser.parseChildNodes(theNode));
        end

        function value = getMessageCatalogString(key)
            try
                value = getString(message(sprintf( ...
                    'MATLAB:codetools:contextmenus:%s', key)));
            catch
                value = key;
            end
        end

        function attributes = parseAttributes(theNode)
            % Create attributes structure.
            attributes = [];
            if theNode.hasAttributes
                theAttributes = theNode.getAttributes;
                numAttributes = theAttributes.getLength;
                attributes = struct;
                try
                    for count = 1:numAttributes
                        attrib = theAttributes.item(count-1);
                        attribName = attrib.getName;
                        attribVal = attrib.getValue;
                        if any(strcmpi(attribVal, {'true','false'}))
                            % Need str2num as it handles logical conversion
                            attribVal = str2num(lower(attribVal)); %#ok<ST2NM> 
                        end
                        if strcmpi(attribName, 'MessageID')
                            attribName = 'DisplayName';
                            attribVal = internal.matlab.datatoolsservices.contextmenuservice.XMLParser.getMessageCatalogString(attribVal);
                        end
                        attributes.(attribName) = attribVal;
                    end
                catch e
                    disp(e);
                end
            end
        end
    end
end

