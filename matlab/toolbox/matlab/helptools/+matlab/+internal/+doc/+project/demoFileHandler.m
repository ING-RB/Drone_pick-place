classdef (Hidden) demoFileHandler < matlab.internal.doc.project.demoFileHandlerFactory
    %  MATLAB.INTERNAL.DOC.PROJECT.DEMOFILEHANDLER

    %   Copyright 2020 The MathWorks, Inc.

    properties
        Helploc;
        DemoFile;
        BackupFile;
    end
    
    methods
        function obj = demoFileHandler(helploc)
            if isstring(helploc)
                helploc = char(helploc);
            end            
            obj.Helploc = helploc;
            obj.DemoFile = fullfile(obj.Helploc, 'demos.xml');
            obj.BackupFile = fullfile(obj.Helploc, 'demos_bak.xml');
        end

        function loc_exists = locationExists(this) 
            loc_exists = exist(this.Helploc,'file');
        end        
        
        function file_exists = fileExists(this) 
            file_exists = exist(this.DemoFile,'file');
        end   
        
        function backupDemoFile(this)
            copyfile(this.DemoFile, this.BackupFile);
        end    
        
        function str = readDemoFile(this)
            str = fileread(this.DemoFile);
        end
        
        function writeDemoFile(this, newStr)
            fid = fopen(this.DemoFile,'w');
            fprintf(fid, '%s', newStr);
            fclose(fid);                
        end
    end
end

