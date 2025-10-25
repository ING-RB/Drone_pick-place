classdef EntityManager < handle
    %ENTITYMANAGER Add section references to report XML.
    %   The Report Explorer generates each report section as a separate
    %   XML file. An instance of this class adds the sections to the 
    %   root XML file as file entity references.
    
    %   Copyright 2022-2023 Mathworks, Inc.
    
    properties
        URLEncode logical = false;
    end

    properties (Access=private)
        
        EntityList string = string.empty(0,2);
        
    end

    methods
        function obj = EntityManager()
        end
        
        
        function str = toString(obj)
            str = "";
            sz = size(obj.EntityList);
            nEntities = sz(1);
            for i = 1:nEntities
                str = str + "[";
                str = str + obj.EntityList(i,1);
                str = str + " ";
                str = str + obj.EntityList(i,2);
                str = str + "]";
            end
            
        end
        
        
        function addEntityDefinition(obj,entityRef,fileLocation)
            obj.EntityList(end+1,1) = string(entityRef);
            obj.EntityList(end,2) = string(fileLocation); 
%               obj.EntityList = [obj.EntityList; ...
%                   [string(entityRef) string(fileLocation]];
        end
        
        function nEntities = size(obj)
            % Returns the number of entities stored
            sz = size(obj.EntityList);
            nEntities = sz(1);
        end


     function writeFile(obj,fileName, docType, fileEncoding)     
         % Write the entities out as an XML header to file fileName.
         % If fileName.xfrag exists, it will be concatenated byte-for-byte onto the end of fileName.
         %
         % @param fileName
         % @param docType
         % @param fileEncoding
         %/
         import rptgen.internal.docbook.DocbookDocument
         
         if isempty(fileEncoding), fileEncoding = "utf-8"; end
         if isempty(docType), docType = "book"; end
         
         try
             fid = fopen(fileName, 'w', 'n', 'UTF-8');
         catch ME
             rptgen.internal.gui.GenerationDisplayClient.staticAddMessage("File '" + fileName + "' not writable.",2);
             rptgen.internal.gui.GenerationDisplayClient.staticAddMessage(ME.message,5);
             return
         end
         
         try
             
             fprintf(fid,'<?xml version="1.0\" encoding="%s"?>\n', ...
                 fileEncoding);
             fprintf(fid,'<!DOCTYPE %s ',docType);
             fprintf(fid,'PUBLIC "%s" ',DocbookDocument.PUBLIC_ID);
             
             % The C++ version of the Report Explorer uses libxslt to 
             % transform XML DocBook files to HTML and FO. The libxml 
             % parser used by the transformer to parse the xml input 
             % cannot handle file entity paths with spaces. The
             % spaces must be encoded as '%20' strings. See
             % https://gitlab.gnome.org/GNOME/libxml2/-/issues/287.
             sysID = DocbookDocument.SYSTEM_ID;
             sysID = strrep(sysID,' ','%20');

             fprintf(fid,'"%s"',sysID);
             
             nEntities = size(obj);
             if nEntities > 0
                 fprintf(fid,' [\n');
                 for i=1:nEntities
                     fprintf(fid,"<!ENTITY %s ",obj.EntityList(i,1));
                     systemID = obj.EntityList(i,2);
                     if obj.URLEncode
                         systemID = mlreportgen.utils.urlencode(systemID);
                     end
                     fprintf(fid,' SYSTEM "%s">\n',systemID);
                 end
                 fprintf(fid,']');
             end
             fprintf(fid,'>\n');             
             rptgen.internal.docbook.EntityManager.catFiles(fileName,fid);
             fclose(fid);
         catch ME
             rptgen.internal.gui.GenerationDisplayClient.staticAddMessage("Unable to write entity header.",2);
             rptgen.internal.gui.GenerationDisplayClient.staticAddMessage(ME.message,5);
             try
                 fclose(fid);
             catch ME
                 rptgen.internal.gui.GenerationDisplayClient.staticAddMessage("Unable to close header file.",2);
                 rptgen.internal.gui.GenerationDisplayClient.staticAddMessage(ME.message,5);
             end
         end
     end
     
    end

    methods (Static,Access=private)

        function catFiles(fileName, fidOut)
            % Performs a byte-by-byte concatenation of
            % the file-being-created (fileName) with "file-being-created.xfrag"
            %
            % If file.xfrag does not exist, noop
            %
            % @param fileName
            % @param os the OutputStream for file-being-created
            % @throws IOException
            %/
            
            xFragment = fileName + ".xfrag";
            if exist(xFragment,'file')
                inputStr = fileread(xFragment);
                fprintf(fidOut,'%s',inputStr);
            end
            delete(xFragment);
        end
end

end

