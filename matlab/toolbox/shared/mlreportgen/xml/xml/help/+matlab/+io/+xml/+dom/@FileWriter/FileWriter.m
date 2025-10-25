%matlab.io.xml.dom.FileWriter Defines a writer that creates a text file
%   writer = FileWriter(filePath) creates a writer that streams text to the
%   file specified by filePath, using UTF-8 character encoding.
%
%   writer = FileWriter(filePath,encoding) creates a writer that streams
%   text to the file specified by filePath, using the specified character
%   encoding. The filePath and encoding arguments may be a scalar
%   string or a character vector.
%
%   For local files, filePath can be the full or relative file path. For
%   example, to write to a file in the current folder:
%
%      writer = FileWriter("myFile.xml");
%
%   If the file is stored at a remote location, then filePath must
%   contain the full path of the file specified with the form:
%
%      scheme_name://path_to_file/my_file.ext
%
%   scheme_name can be one of the following values:
%      - s3    - Amazon S3
%      - wasb  - Windows Azure Blob Storage (unencrypted access)
%      - wasbs - Windows Azure Blob Storage (encrypted access)
%      - hdfs  - Hadoop Distributed File System
% 
%   For example, to write to a remote file from Amazon S3,
%   specify the full URL for the file:
%
%      writer = FileWriter("s3://bucketname/path_to_file/myFile.xml");
%
%   For more information on accessing remote data, see "Work with
%   Remote Data" in the documentation.
%
%   Note: Use this writer with a DOMWriter to mix serialized XML output
%   with output from other text sources.
%
%   Note: Delete this writer to close the file that it creates.
%
%   FileWriter methods:
%       write - Stream text to a file
%       flush - Flush writer's character buffer
%       close - Close writer
%
%    FileWriter properties:
%       FileEncoding - Encoding of text output, e.g., UTF-8
%
%    See also matlab.io.xml.dom.DOMWriter  

%    Copyright 2020-2021 MathWorks, Inc.
%    Built-in class

%{
properties
     %FileEncoding Character encoding of output file
     %    The value of this read-only property is the character encoding,
     %    e.g., UTF-8, of the file produced by this writer.
     %
     %    Note: the constructor used to create this writer determines the
     %    character encoding of the file that it creates.
     FileEncoding;
end
%}