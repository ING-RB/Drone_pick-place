classdef FileImporter < handle
    %FILEIMPORTER Import content of a file into report Docbook.
    %   Creates a Docbook wrapper around file content.
    
    %    Copyright 2020-2023 Mathworks, Inc.
    
    methods (Static)
        function val = TEXT(); val = "text"; end
        function val = PARA_LB(); val = "para-lb"; end
        function val = PARA_EMPTYROW(); val = "para-emptyrow"; end
        function val = HONORSPACES(); val = "honorspaces"; end
        function val = FIXEDWIDTH; val = "fixedwidth"; end
        function val = DOCBOOK; val = "docbook"; end
        function val = EXTERNAL; val = "external"; end
        function val = CODE ; val = "code_highlighted"; end
        
        
        function node = importFile(varargin)
            % node = importFile(importType,fileName,parentDocument)
            % node = importFile(importType,fileName,encoding,parentDocument)
            import rptgen.internal.docbook.*
            
            importType = varargin{1};
            fileName = varargin{2};
            if nargin > 3
                encoding = varargin{3};
                parentDocument = varargin{4};
            else
                encoding = FileImporter.DEFAULT_ENCODING;
                parentDocument = varargin{3};
            end
            
            switch (importType)
                case FileImporter.TEXT
                    node = FileImporter.importText(fileName, encoding, parentDocument);
                case FileImporter.PARA_LB
                    node = FileImporter.importLineDelimitedText(fileName, encoding, parentDocument);
                case FileImporter.PARA_EMPTYROW
                    node = FileImporter.importBlankLineDelimitedText(fileName, encoding, parentDocument);
                case FileImporter.HONORSPACES
                    node = FileImporter.importWrappedText(fileName, encoding, parentDocument, "literallayout");
                case FileImporter.FIXEDWIDTH
                    node = FileImporter.importWrappedText(fileName, encoding, parentDocument, "programlisting");
                case FileImporter.DOCBOOK
                    node = FileImporter.importDocBook(fileName, parentDocument);
                case FileImporter.EXTERNAL
                    node = FileImporter.importExternalFile(fileName, parentDocument);
                case FileImporter.CODE
                    %  Modified this class to read the file locally - using the CodeAsXML reader caused spurious line breaks to be inserted with Windows line breaks - GRA - 19-July-2009
                    node = CodeAsXML.xmlize(parentDocument, FileImporter.fileToCharArray(fileName, encoding));
                otherwise
                    % Type not found - noop
                    node = [];
            end
        end
        
        function df = importText(varargin)
            % node = importText(fileName,parentDocument)
            % node = importText(fileName,encoding, parentDocument)
            % Imports text from a file. Dumps unadorned text into the
            % document.
            import rptgen.internal.docbook.*
            import matlab.io.xml.dom.*
            
            fileName = varargin{1};
            if nargin > 2
                encoding = varargin{2};
                parentDocument = varargin{3};
            else
                encoding = FileImporter.DEFAULT_ENCODING;
                parentDocument = varargin{2};
            end
            
            try
                reader = fopen(fileName,"r",'native',encoding);
                df = createDocumentFragment(parentDocument);
                
                while true
                    thisLine = fgets(reader);
                    if ischar(thisLine)
                        appendChild(df,createTextNode(parentDocument, ...
                            thisLine));
                    else
                        break
                    end
                end
                fclose(reader);
            catch
                df = [];
            end
        end
        
        function df = importLineDelimitedText(varargin)
            % df = importLineDelimitedText(fileName,parentDocument)
            % df = importLineDelimitedText(fileName, encoding,parentDocument)
            % Imports from a text file.  Every \n denotes a new paragraph element.
            import rptgen.internal.docbook.*
            import matlab.io.xml.dom.*
            
            fileName = varargin{1};
            if nargin > 2
                encoding = varargin{2};
                parentDocument = varargin{3};
            else
                encoding = FileImporter.DEFAULT_ENCODING;
                parentDocument = varargin{2};
            end
            
            try
                reader = fopen(fileName,"r",'native',encoding);
                df = createDocumentFragment(parentDocument);
                
                while true
                    thisLine = fgetl(reader);
                    if ischar(thisLine)
                        if ~isempty(thisLine)
                            paraEl = createElement(parentDocument,"para");
                            appendChild(paraEl,createTextNode(parentDocument, ...
                                thisLine));
                            appendChild(df,paraEl);
                        end
                    else
                        break
                    end                   
                end
                fclose(reader);
            catch
                df = [];
            end
        end
        
        function df = importBlankLineDelimitedText(varargin)
            % df = importBlankLineDelimitedText(fileName parentDocument)
            % df = importBlankLineDelimitedText(fileName,encoding, parentDocument)
            % Imports from a text file.  Blank lines denote a new paragraph element.
            %  @deprecated  Should not be used directly, use importFile
            import rptgen.internal.docbook.*
            import matlab.io.xml.dom.*
            
            fileName = varargin{1};
            if nargin > 2
                encoding = varargin{2};
                parentDocument = varargin{3};
            else
                encoding = FileImporter.DEFAULT_ENCODING;
                parentDocument = varargin{2};
            end
            
            try
                reader = fopen(fileName,"r",'native',encoding);
                df = createDocumentFragment(parentDocument);
                paraEl = createElement(parentDocument,"para");                
                emptyParagraph = true;
                while true
                    thisLine = fgets(reader);
                    if ischar(thisLine)
                        if isempty(thisLine)
                            if ~emptyParagraph
                                appendChild(df,paraEl);
                                paraEl = createElement(parentDocument,"para");
                                emptyParagraph = true;
                            end
                        else
                            appendChild(paraEl,createTextNode(parentDocument,thisLine));
                            emptyParagraph=false;
                        end
                    else
                        break
                    end
                end
                if ~emptyParagraph
                    appendChild(df,paraEl);
                end
                fclose(reader);
            catch
                df = [];
            end
        end
        
        function wrapper = importWrappedText(varargin)
            % wrapper = importWrappedText(fileName,parentDocument,elementName)
            % wrapper = importWrappedText(fileName,encoding,parentDocument,elementName)
            % Imports text from a file and wraps it in element "elementName".
            % Sets the element to have xml:space="preserve"
            import rptgen.internal.docbook.*
            
            fileName = varargin{1};
            if nargin > 3
                encoding = varargin{2};
                parentDocument = varargin{3};
                elementName = varargin{4};
            else
                encoding = FileImporter.DEFAULT_ENCODING;
                parentDocument = varargin{2};
                elementName = varargin{4};
            end
            
            wrapper = createElement(parentDocument,elementName);
            appendChild(wrapper,FileImporter.importText(fileName, encoding, parentDocument));
            setAttribute(wrapper,"xml:space","preserve");
        end
        
        function node = importDocBook(fileName,parentDocument)
            % Imports a DocBook XML fragment from a file.
            import matlab.io.xml.dom.*
            newDocument = parseFile(Parser,fileName);
            node = importNode(parentDocument,getDocumentElement(newDocument));          
        end
        
        function importEl = importExternalFile(varargin)
            % parentDocument = importExternalFile(fileName,parentDocument)
            % Create a special marker (&lt;rptgen:importpost&gt;) which the stylesheets
            % know how to handle for either post-conversion document import or
            % during-conversion file linking.
            % parentDocument = importExternalFile(fileName,parentDocument,textLabel)
            % Allows control over the linked file name as displayed in the report.
            
            fileName = varargin{1};
            parentDocument = varargin{2};
            
            if nargin < 3
                % Create a backup text label in case importing doesn't happen
                [path,name,~] = fileparts(fileName);
                if ~isempty(name)
                    textLabel = name;
                else
                    textLabel = path;
                end
            else
                textLabel = varargin{3};
            end
            
            importEl = createElement(parentDocument,"rptgen:importpost");
            setAttribute(importEl,"xmlns:rptgen", ...
                "http://www.mathworks.com/namespace/rptgen/import/v1");
            
            if ~isempty(fileName) && strlength(fileName) > 0
                isAbsoluteFilePath = contains(fileName,":") ...
                    || startsWith(fileName,"/") ...
                    || startsWith(fileName,"\\");
                
                if isAbsoluteFilePath
                    % Display link as URN.  This allows better support for file paths with space
                    setAttribute(importEl,"url", rptgen.file2urn(fileName));
                else
                    setAttribute(importEl,"url", strrep(fileName,"\\", "/"));
                end
                
                % Used in FO stylsheet.  PDF links must not contain URIs
                setAttribute(importEl,"fileRef", strrep(fileName,"\", "/"));
            end
            
            appendChild(importEl,createTextNode(parentDocument,textLabel));
        end
        
        function fileImported = scanDocumentForImports(reportFile)
            % Searches the post-transform document for a special string sequence and
            % inlines the specified file.  Determines the importType of the document
            % based upon its extension.
            %
            % Returns whether or not at least one file was imported properly.
            %
            % Should not throw exceptions, but may send level 2 messages to GenerationDisplayClient
            import rptgen.internal.docbook.*
            import rptgen.internal.gui.*
            
            reportFileName = rptgen.findFile(reportFile);
            
            % We used to put the tmp file in the tmp directory, but renameTo doesn't
            % allow files to be renamed across filesystem boundaries.  For safety's sake,
            % just put the tmp file in the same dir as the original report file
            
            tmpFile = reportFileName + ".tmp";
            
            fileImported = false;
            try
                frRpt = fopen(reportFileName,"r",'native',"utf-8");
                fwTmp = fopen(tmpFile,"w",'native',"utf-8");
                type = FileImporter.findImportType(reportFile);
                [parentDir,~,~] = fileparts(reportFile);
                fileImported = FileImporter.scanDocumentForImportsImpl(...
                    frRpt,fwTmp,type,parentDir);
            catch ioE
                [~,name,ext] = fileparts(reportFile);
                GenerationDisplayClient.staticAddMessage("Could not import into file '" ...
                    + name + ext ...
                    + "' (post-conversion)",2);
                GenerationDisplayClient.staticAddMessage(ioE.message,5);
                fclose(frRpt);
                fclose(fwTmp);
            end
            
            
            if fileImported
                backupFile = reportFileName + ".bak";
                
                backupClear = true;
                if exist(backupFile,'file')
                    try
                        delete(backupFile);
                    catch
                        backupClear = false;
                    end
                    if ~backupClear
                        GenerationDisplayClient.staticAddMessage( ...
                            "Unable to delete" + " '" + ...
                            rptgen.findFile(backupFile) + "'",5);
                    end
                end
                
                if backupClear
                    copyfile(reportFile,backupFile);
                    delete(reportFile);
                else
                    % If the existing foo~ file could not be removed, just
                    % try to delete this file since it is just crowding the space
                    % that needs to be used by the newly imported-to file
                    GenerationDisplayClient.staticAddMessage( ...
                        "Unable to rename" + " '" + ...
                        rptgen.findFile(reportFile) ...
                        + "' to '" + rptgen.findFile(backupFile) ...
                        + "'.  Deleting instead.",5);
                    backupClear = true;
                    try
                        delete(reportFile);
                    catch
                        backupClear = false;
                    end
                    if ~backupClear
                        GenerationDisplayClient.staticAddMessage("Unable to delete" + " '" + reportFile.getAbsolutePath() + "'",5);
                    end
                end
                
                if backupClear
                    try
                        copyfile(tmpFile,reportFileName);
                        delete(tmpFile);
                    catch mE
                        backupClear = false;
                        GenerationDisplayClient.staticAddMessage(mE.message,5);
                    end
                end
                
                if ~backupClear
                    GenerationDisplayClient.staticAddMessage( ...
                        "Could not rename merged file '" ...
                        + rptgen.findFile(tmpFile) + "' to '" ...
                        + reportFileName + "'",2);
                else  % (!fileImported) - just delete the .tmp file
                    delete(backupFile);
                end
            else
                delete(tmpFile);
            end
        end
    end
    
    methods (Static, Access = private)
        
        function val = IMPORT_PRE(); val = "-rG-ImPoRt-BeGiN-"; end
        function val = IMPORT_END(); val = "-Rg-iMpOrT-eNd-"; end
        
        function val = POST_TYPE_HTML(); val = 1; end
        function val = POST_TYPE_RTF(); val  = 2; end
        
        function val = DEFAULT_ENCODING(); val = "utf-8"; end
        
        function type = findImportType(fileName)
            import rptgen.internal.docbook.*
            import rptgen.internal.output.*
            
            lowercaseName = lower(mlreportgen.utils.findFile(fileName));
            if endsWith(lowercaseName,".html")
                type = FileImporter.POST_TYPE_HTML;
            elseif endsWith(lowercaseName,".rtf")
                type = FileImporter.POST_TYPE_RTF;
            elseif endsWith(lowercaseName,lower(OutputFormat.getFileExtension(OutputFormat.FORMAT_HTML)))
                type = FileImporter.POST_TYPE_HTML;
            elseif (lowercaseName.endsWith(OutputFormat.getFileExtension(lower(OutputFormat.FORMAT_RTF97))))
                type = FileImporter.POST_TYPE_RTF;
            elseif endsWith(lowercaseName,lower(OutputFormat.getFileExtension(OutputFormat.FORMAT_DOC_RTF)))
                type = FileImporter.POST_TYPE_RTF;
            else
                type = 0;
            end
        end
        
        function importCompleted = scanDocumentForImportsImpl(fReader,fWriter,importType,baseDir)
            % importType can be POST_TYPE_RTF or POST_TYPE_HTML
            % Returns true if at least one external file imports properly
            % @param baseDir the base directory of the source file
            import rptgen.internal.docbook.*
            
            importCompleted = false;
            reader = fReader;
            writer = fWriter;
            
            lenPre = strlength(FileImporter.IMPORT_PRE);
            lenEnd = strlength(FileImporter.IMPORT_END);
            
            thisLine = fgetl(reader);
            % Fix for g2990980: updating the check to return the status
            % of the end-of-file indicator using MATLAB's feof API
            % instead of checking numeric value -1. When reading from a
            % file, checking a numeric value of -1 as an indicator for
            % end-of file is not robust as it fails if a file has newline
            % characters. For example, 
            % thisLine = fgetl(fid) reads a newline as a 0×0 empty char array
            % and checking whether an end-of-file is encountered using a
            % numeric value -1 does not work as expected.
            while ~feof(reader)
                idxImportPre = strfind(thisLine,FileImporter.IMPORT_PRE);
                if isempty(idxImportPre)
                    %fprintf("Printing normally: %s",thisLine);
                    fwrite(writer,thisLine);
                    thisLine = fgetl(reader);
                else
                    idxImportEnd = strfind(thisLine,FileImporter.IMPORT_END);
                    if idxImportEnd > idxImportPre
                        %fprintf("Found an import pair");
                        fwrite(writer,thisLine(1:idxImportPre-1));
                        importFileName = strtrim(thisLine(idxImportPre+lenPre:idxImportEnd-1));
                        
                        % Filename may be a Universal Resource Name
                        importFileName = rptgen.internal.tools.RgXmlUtils.urn2file(importFileName);
                        
                        % Get the full path, this also searches the MATLAB path
                        importFileNameFullPath = rptgen.findFile(importFileName);
                        if  ~isempty(importFileNameFullPath)
                            importFileName = importFileNameFullPath;
                        else
                            % May be relative, try looking from baseDir
                            importFileNameFullPath = rptgen.findFile(fullfile(baseDir,importFileName));
                            if  ~isempty(importFileNameFullPath)
                                importFileName = importFileNameFullPath;
                            end
                        end
                        
                        try
                            if importType == FileImporter.POST_TYPE_HTML
                                rptgen.internal.docbook.FileImporter.importHTML(importFileName,writer);
                            elseif importType == FileImporter.POST_TYPE_RTF
                                rptgen.internal.docbook.FileImporter.importRTF(importFileName,writer);
                            end
                            importCompleted = true;
                        catch importException
                            rptgen.internal.gui.GenerationDisplayClient.staticAddMessage("Could not import file '" ...
                                + importFileName ...
                                + "' (post-conversion)",2);
                            rptgen.internal.gui.GenerationDisplayClient.staticAddMessage(importException.message(),5);
                        end
                        thisLine = fgetl(reader);
                    else
                        %fprintf("Import pair straddles a line!");
                        newLine = fgetl(reader);
                        if newLine == -1
                            % we have reached the end of the file without finding a match
                            fwrite(writer,thisLine);
                            thisLine = newLine;
                        else
                            thisLine = [thisLine newLine]; %#ok<AGROW>
                        end
                    end
                end
            end
            fclose(reader);
            fclose(writer);
        end
        
        
        function importHTML(htmlFileName, targetFile)
            % Import an external HTML file into the document by inlining its entire text.
            
            % HTML's content model is sufficiently loose that we can get away
            % with no heavy-duty processing of the file.  To be strictly correct,
            % we should strip out <html>, <body>, and anything inside <head>.
            
            try
                reader = fopen(htmlFileName,"r",'native', "utf-8");
            catch
                return
            end
            
            thisLine = fgets(reader);
            while ~feof(reader)
                fwrite(targetFile,thisLine);
                thisLine = fgets(reader);
            end
            fclose(reader);
        end
        
        function importRTF(rtfFileName,targetFile)
            % Creates an INCLUDETEXT field in an existing RTF document
            % Example: {\field{\*\fldinst { INCLUDETEXT "s:\\\\dir\\\\secondary.rtf" \\c MSRTF }}}
            % Note that the RTF conversion itself will change
            % s:\dir\secondary.rtf into s:\\dir\\secondary.rtf
            % In here, we need to change the double-backslashes into quadruple-backslashes
            
            rtfFileUrn = char(rptgen.file2urn(rtfFileName));
            fwrite(targetFile,'{\field{\*\fldinst { INCLUDETEXT "');
            
            nChars = numel(rtfFileUrn);
            for i = 1:nChars
                currChar = rtfFileUrn(i);
                fwrite(targetFile,currChar);
                if strcmp(currChar,'\')
                    % Write char again!
                    fwrite(targetFile,currChar);
                end
            end
            fwrite(targetFile,'" \\c MSRTF }}}');
        end
        
        function chars = fileToCharArray(fileName,encoding)
            %  Reads contents of given file into a character array while replacing
            %  Windows line returns (\r\n) with simple line returns (\n)
            
            try
                reader = fopen(fileName,"r",'native', encoding);
            catch
                return
            end
            
            chars = fread(reader);
            chars = char(chars');
            fclose(reader);
        end
    end
    
end

