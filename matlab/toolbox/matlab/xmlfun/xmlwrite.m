function varargout=xmlwrite(varargin)
%XMLWRITE  Serialize an XML Document Object Model node.
%   XMLWRITE(FILENAME,DOMNODE) serializes the DOMNODE to file FILENAME.
%
%   S = XMLWRITE(DOMNODE) returns the node tree as a character vector.
%
%   Example:
%   % Create a sample XML document.
%   docNode = com.mathworks.xml.XMLUtils.createDocument('root_element')
%   docRootNode = docNode.getDocumentElement;
%   docRootNode.setAttribute('attribute','attribute_value');
%   for i=1:20
%      thisElement = docNode.createElement('child_node');
%      thisElement.appendChild(docNode.createTextNode(sprintf('%i',i)));
%      docRootNode.appendChild(thisElement);
%   end
%   docNode.appendChild(docNode.createComment('this is a comment'));
%
%   % Save the sample XML document.
%   xmlFileName = [tempname,'.xml'];
%   xmlwrite(xmlFileName,docNode);
%   edit(xmlFileName);
%
%   See also XMLREAD, XSLT.

%   Copyright 1984-2016 The MathWorks, Inc.

%    Advanced use:
%       FILENAME can also be a URN, java.io.OutputStream or
%                java.io.Writer object
%       SOURCE can also be a SAX InputSource, JAXP Source,
%              InputStream, or Reader object

% This is the XML that the help example creates:
% <?xml version="1.0" encoding="UTF-8"?>
% <root_element>
%     <child_node>1</child_node>
%     <child_node>2</child_node>
%     <child_node>3</child_node>
%     <child_node>4</child_node>
%     ...
%     <child_node>18</child_node>
%     <child_node>19</child_node>
%     <child_node>20</child_node>
% </root_element>
% <!--this is a comment-->

import matlab.io.xml.internal.legacy.xmlstringinput

[varargin{:}] = convertStringsToChars(varargin{:});

returnString = false;
if length(varargin)==1
    returnString = true;
    result = java.io.StringWriter;
    source = varargin{1};
else
    result = varargin{1};
    if ischar(result)
        result = xmlstringinput(result,false);
        % This strips off the extra stuff in the resolved file.  Then,
        % we are going to use java to put it in the right form.
        if strncmp(result, 'file:', 5)
            result = regexprep(result, '^file:///(([a-zA-Z]:)|[\\/])','$1');
            result = strrep(result, 'file://', '');
            temp = java.io.File(result);
            result = char(temp.toURI());
        end
    elseif ~isa(result, 'java.io.Writer') && ~isa(result, 'java.io.OutputStream')
        error(message('MATLAB:xmlwrite:IncorrectFilenameType'));
    end

    source = varargin{2};
    if ischar(source)
        source = xmlstringinput(source,true);
    end
end

% call a helper function to write the XML file
xmlWriteHelper(result,source,varargin{1});

if returnString
    varargout{1}=char(result.toString);
else
    %this notifies the operating system of a file system change.  This
    %probably doesn't work if the user passed in the filename in the form
    %of file://filename, but it would probably be more trouble than it is
    %worth to resolve it.  It should be harmless in that case.
    if ischar(result) && strncmp(result, 'file:', 5)
        fschange(fileToDirectory(result));
    end
end

end

function final_name = fileToDirectory(orig_name)
% This is adequate to resolve the full path since the call above to xmlstringinput
% does not search the path when looking to write the file.
temp = fileparts(orig_name);
if isempty(temp)
    final_name = pwd;
else
    final_name = temp;
end
end

function xmlWriteHelper(output,node,origFilename)
% Use saxon 9b
tfProp = 'javax.xml.transform.TransformerFactory';
origTF = java.lang.System.getProperty(tfProp);
java.lang.System.setProperty( ...
    tfProp, 'net.sf.saxon.TransformerFactoryImpl');
cleanup = onCleanup(@()java.lang.System.setProperty(tfProp, origTF));

% read in XSLT to remove empty namespace attributes when root node of
% XML file contains a namespace attribute
dbFactory = javax.xml.parsers.DocumentBuilderFactory.newInstance();
dbFactory.setNamespaceAware(true);
db = dbFactory.newDocumentBuilder();
xslFile = getXSLHelper(db);
xsltSource = javax.xml.transform.dom.DOMSource(xslFile);

% create transformer
tfactory = javax.xml.transform.TransformerFactory.newInstance();
serializer = tfactory.newTransformer(xsltSource);

serializer.setOutputProperty( ...
    javax.xml.transform.OutputKeys.METHOD, 'xml');
serializer.setOutputProperty( ...
    javax.xml.transform.OutputKeys.INDENT, 'yes');
serializer.setOutputProperty( ...
    javax.xml.transform.OutputKeys.ENCODING, 'utf-8');

% construct source and result for transformer
xSource = javax.xml.transform.dom.DOMSource(node);
% doc = db.parse(xSource);
if isa(output,'java.io.StringWriter') || isa(output,'java.io.Writer') || ...
        isa(output,'java.io.OutputStream')
    % output is displayed to stdout or written to a stream
    xResult = javax.xml.transform.stream.StreamResult(output);
else
    % output is written to file
    newFile = java.io.File(origFilename);
    % create folders in the path if not already existing
    parent = newFile.getParentFile();
    if ~isempty(parent) && ~isfolder(string(parent.toString))
        try
            mkdir(string(parent.toString));
        catch ME
            throw(ME);
        end
    end
    newFile.createNewFile();
    fos = java.io.FileOutputStream(newFile,false);
    xResult = javax.xml.transform.stream.StreamResult(fos);
end

% set systemId and publicId properties for the transformer
if isa(node,'org.apache.xerces.dom.DocumentImpl')
    docNode = node.getDoctype();
    if ~isempty(docNode)
        systemId = docNode.getSystemId();
        publicId = docNode.getPublicId();
        if ~isempty(systemId)
            serializer.setOutputProperty(javax.xml.transform.OutputKeys.DOCTYPE_SYSTEM, systemId);
        end
        if ~isempty(publicId)
            serializer.setOutputProperty(javax.xml.transform.OutputKeys.DOCTYPE_PUBLIC, publicId);
        end
    end
end
% write out node
try
    serializer.transform(xSource, xResult);
    % close the stream if it was opened for writing
    if exist('fos','var')
        fos.close();
    end
catch ME
    if contains(ME.message,'java.io.FileNotFoundException') && contains(output,'~')
        error(message('MATLAB:xmlwrite:TildePathsNotSupported'));
    else
        throw(ME);
    end
end

end

function xslFile = getXSLHelper(db)
p = strrep(mfilename('fullpath'),mfilename,'');
xslFile = db.parse(fullfile(p,'removeEmptyNamespaceAttributes.xsl'));
end
