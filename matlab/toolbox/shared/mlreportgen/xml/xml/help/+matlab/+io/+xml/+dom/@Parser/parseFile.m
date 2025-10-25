%parseFile Parse an XML file
%    doc = parseFile(thisParser,filePath) parses the specified file and
%    returns the result as a Document object. The filePath argument may be
%    a string scalar or a character vector. This method throws an error if
%    it encounters a markup error in the file being parsed. To continue
%    parsing in the face of errors, configure the parser to use a custom
%    error handler. In this case, the parser may return an invalid
%    document.
%
%    For local files, filePath can be the full or relative file path. For
%    example, to parse a file in the current folder:
%
%       doc = parseFile(thisParser,"myFile.xml");
%
%    If the file is stored at a remote location, then filePath must
%    contain the full path of the file specified with the form:
%
%       scheme_name://path_to_file/my_file.ext
%
%    scheme_name can be one of the following values:
%       - s3    - Amazon S3
%       - wasb  - Windows Azure Blob Storage (unencrypted access)
%       - wasbs - Windows Azure Blob Storage (encrypted access)
%       - hdfs  - Hadoop Distributed File System
% 
%    For example, to parse a remote file from Amazon S3,
%    specify the full URL for the file:
%
%       doc = parseFile(thisParser,"s3://bucketname/path_to_file/myFile.xml");
%
%    For more information on accessing remote data, see "Work with
%    Remote Data" in the documentation.
%
%    Note: The XML markup to be parsed must declare only one top-level
%    element, which may be preceded or followed by a comment or processing
%    instruction. If the markup declares more than one top-level element,
%    the parser throws an error after processing the first element. The
%    parser gives "comment or processing instruction expected" as the
%    reason for the error.
%
%    Note: By default the parser does not support parsing a document that
%    specifies a document type definition (DTD). If the document to be
%    parsed specifies a DTD, the parser throws an error and exits. This is
%    done to prevent infecting the local system with a virus posing as a
%    DTD. If you need to use a DTD, you can enable the parser to process
%    DTDs with the AllowDoctype option of the parser configuration.
%    However, it is recommended that this option be enabled only for DTDs
%    that reference trusted sources.
%
%    See also matlab.io.xml.dom.Document,
%    matlab.io.xml.dom.Parser.parseString,
%    matlab.io.xml.dom.Parser.Configuration,
%    matlab.io.xml.dom.EntityResolver,
%    matlab.io.xml.dom.ParseErrorHandler

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in function.