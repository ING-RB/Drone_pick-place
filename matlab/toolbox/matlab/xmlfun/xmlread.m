function [parseResult,p] = xmlread(filename,varargin)
%XMLREAD  Parse an XML document and return a Document Object Model node.
%   DOMNODE = XMLREAD(FILENAME) reads a URL or file name in the input
%   argument FILENAME.  The function returns DOMNODE, a Document Object
%   Model (DOM) node representing the parsed document. The node can be
%   manipulated by using standard DOM functions.
%
%   DOMNODE = XMLREAD(FILENAME,'AllowDoctype',TF) errors if FILENAME
%   contains an XML DOCTYPE declaration and TF is false.
%
%   Note: A properly parsed document will display to the screen as
%
%     >> xDoc = xmlread(...)
%
%     xDoc =
%
%     [#document: null]
%
%   Example 1: All XML files have a single root element.  Some XML files declare a
%   preferred schema file as an attribute of this element.
%
%     xDoc = xmlread(fullfile(matlabroot,'toolbox/matlab/general/info.xml'));
%     xRoot = xDoc.getDocumentElement;
%     schemaURL = char(xRoot.getAttribute('xsi:noNamespaceSchemaLocation'))
%
%   Example 2: Each info.xml file on the MATLAB path contains several <listitem>
%   elements with a <label> and <callback> element. This script finds the callback
%   that corresponds to the label 'Plot Tools'.
%
%     infoLabel = 'Plot Tools';  infoCbk = '';  itemFound = false;
%     xDoc = xmlread(fullfile(matlabroot,'toolbox/matlab/general/info.xml'));
%
%     % Find a deep list of all <listitem> elements.
%     allListItems = xDoc.getElementsByTagName('listitem');
%
%     %Note that the item list index is zero-based.
%     for i=0:allListItems.getLength-1
%         thisListItem = allListItems.item(i);
%         childNode = thisListItem.getFirstChild;
%
%         while ~isempty(childNode)
%             %Filter out text, comments, and processing instructions.
%             if childNode.getNodeType == childNode.ELEMENT_NODE
%                 %Assume that each element has a single org.w3c.dom.Text child
%                 childText = char(childNode.getFirstChild.getData);
%                 switch char(childNode.getTagName)
%                     case 'label' ; itemFound = strcmp(childText,infoLabel);
%                     case 'callback' ; infoCbk = childText;
%                 end
%             end
%             childNode = childNode.getNextSibling;
%         end
%         if itemFound break; else infoCbk = ''; end
%     end
%     disp(sprintf('Item "%s" has a callback of "%s".',infoLabel,infoCbk))
%
%   See also XMLWRITE, XSLT.

%   Copyright 1984-2024 The MathWorks, Inc.

% Advanced use:
%   Note that FILENAME can also be an InputSource, File, or InputStream object
%   DOMNODE = XMLREAD(FILENAME,...,P,...) where P is a DocumentBuilder object
%   DOMNODE = XMLREAD(FILENAME,...,'-validating',...) will create a validating
%             parser if one was not provided.
%   DOMNODE = XMLREAD(FILENAME,...,ER,...) where ER is an EntityResolver will
%             will set the EntityResolver before parsing
%   DOMNODE = XMLREAD(FILENAME,...,EH,...) where EH is an ErrorHandler will
%             will set the ErrorHandler before parsing
%   [DOMNODE,P] = XMLREAD(FILENAME,...) will return a parser suitable for passing
%             back to XMLREAD for future parses.
%

import matlab.io.xml.internal.legacy.xmlLocGetParser
import matlab.io.xml.internal.legacy.xmlLocSetEntityResolver
import matlab.io.xml.internal.legacy.xmlLocSetErrorHandler
import matlab.io.xml.internal.legacy.xmlValidateFilename
import matlab.io.xml.internal.legacy.xmlstringinput

narginchk(1,Inf);
filename = convertStringsToChars(filename);
if nargin > 1
    [varargin{:}] = convertStringsToChars(varargin{:});
end

p = xmlLocGetParser(varargin);
xmlLocSetEntityResolver(p,varargin);
xmlLocSetErrorHandler(p,varargin);
validatedFilename = xmlValidateFilename(filename);

try
    parseResult = p.parse(validatedFilename);
catch ME
    % If trying to parse an XML document containing a DOCYTYPE declaration
    % with 'AllowDoctype' set to false, then throw an appropriate error
    % message.
    if isa(ME, 'matlab.exception.JavaException') && ...
            contains(char(ME.ExceptionObject.getLocalizedMessage), ...
            'http://apache.org/xml/features/disallow-doctype-decl')
        error(message('MATLAB:xmlread:DoctypeDisabled', filename));
    end
    rethrow(ME);
end

end