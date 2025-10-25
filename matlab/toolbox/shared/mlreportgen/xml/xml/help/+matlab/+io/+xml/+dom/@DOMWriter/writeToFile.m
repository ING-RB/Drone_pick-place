%writeToFile Serialize an XML DOM document to a file
%    writeToFile(thisWriter,domDoc,filePath) serializes the specified
%    document and stores the resulting XML markup, encoded as UTF-8, in a
%    file at the specified path. The file path argument may be a string
%    scalar or character vector and may contain non-ASCII characters.
%
%    writeToFile(thisWriter,domDoc,filePath,encoding) serializes the
%    specified document and stores the resulting XML markup, encoded as
%    specified, in a file at the specified path. The file path argument may
%    be a string scalar or character vector and may contain non-ASCII
%    characters.
%
%    For local files, filePath can be the full or relative file path. For
%    example, to write to a file in the current folder:
%
%       writeToFile(thisWriter,domDoc,"myFile.xml");
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
%    For example, to write to a remote file from Amazon S3,
%    specify the full URL for the file:
%
%       writeToFile(thisWriter,domDoc,"s3://bucketname/path_to_file/myFile.xml");
%
%    For more information on accessing remote data, see "Work with
%    Remote Data" in the documentation.
%
%    See also matlab.io.xml.dom.FileWriter,
%    matlab.io.xml.dom.DOMWriter.writeToString

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in function.