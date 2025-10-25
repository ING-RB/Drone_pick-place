classdef Comparison< handle & comparisons.internal.mixin.NonSerializable
%COMPARISON comparison object returned by visdiff.
%  A comparison contains the differences between the two files or folders
%  passed to visdiff. You can manipulate the comparison at the command
%  line, apply filters and publish comparison reports.
%
%  Comparison methods:
%    <a href="matlab:help comparisons.Comparison/publish">publish</a> - Publish comparison to report file
%    <a href="matlab:help comparisons.Comparison/filter">filter</a> - Filter comparison result
%
%  See also visdiff

 
% Copyright 2017-2022 The MathWorks, Inc.

    methods
    end
    methods (Abstract)
        %FILTER Filter comparison result
        %  FILTER(comparison, filter) applies the filter to the result of the
        %  comparison. Filtering is not supported for all comparison types.
        %  See visdiff documentation. Supported filters are:
        %
        %    'unfiltered' - Removes all filtering from the comparison
        %       'default' - Default filtering strategy for comparisons
        %
        %  EXAMPLE:
        %
        %    comparison = visdiff(filename1, filename2);
        %    filter(comparison, 'unfiltered');
        filter;

        %PUBLISH Publish comparison to report file
        %  PUBLISH(comparison) creates an HTML report from the comparison and
        %  saves it in the current folder as filename1_filename2.html
        %
        %  PUBLISH(comparison, format) publishes the comparison to the specified
        %  format. See the section on Name-Value pairs for a list of supported
        %  formats.
        %
        %  PUBLISH(comparison, Name, Value) publishes the comparison with options
        %  specified by one or more Name-Value pair arguments. Valid Name-Value
        %  pairs are as follows:
        %
        %  'Format' - The file format of the published report.
        %  
        %      'html' (default)   - single-file HTML Document
        %      'docx'             - Microsoft Word Document
        %      'pdf'              - PDF Document
        %  
        %  'Name' - The name of the report.
        %       
        %      A character vector or scalar string array. If you specify a file
        %      extension, then 'Format' is ignored.
        %      (default: filename1_filename2)
        %
        %  'OutputFolder' - Where to save the report.
        %
        %      A character vector or scalar string array.
        %      (default: Current Folder)
        %
        %  PUBLISH(comparison, options) uses the options structure to customize
        %  the report. The options structure fields and values correspond to the
        %  Name-Value pair arguments.
        %  
        %  file = PUBLISH(...) returns the path to the generated report.
        %  
        %  Example:
        %  
        %      outputFolder = tempdir;
        %      comparison = visdiff(filename1, filename2);
        %      file = publish(comparison, 'OutputFolder', outputFolder);
        %      web(file)
        publish;

    end
end
