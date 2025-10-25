classdef FilePath
    %FilePath Summary of this class goes here
    %   FilePath represents a path to a file and properties
    %   about that path.  FilePath will not error when given filenames
    %   that do not exist, or have paths that are malformed, but will
    %   simply reflect these issues via FilePath's properties.
    %

    % Author: Nick Haddad
    % Copyright 2016-2022 The MathWorks, Inc.

    properties (SetAccess='private')
        Path       % The path to the file as provided by the caller, including the file name
        ParentPath % Path of the files parent directory as provided by the caller
    end

    properties (Dependent, SetAccess='private')
        % absolute path to the file. 
        % Empty ([]) if the file's containing folder does not exist
        % on disk.
        Absolute  
    end
    
    properties (SetAccess='private')
        Extension  % Extension of the file path
    end
    
    properties (Dependent, SetAccess='private')
        Exists    % true if the the file exists, false otherwise.  
        Readable  % true if the file readable, false otherwise.
        Writeable % true if the file is writeable, false otherwise.
    end
    
    
    methods
        function obj = FilePath(filename)
            % Construct a FilePath given FILENAME, an absolute or relative 
            % path to a file.  The file does not have to exist on disk
            % and can include folders that do not exists in the path
            obj.Path = filename;
            
            [obj.ParentPath, ~, obj.Extension] = fileparts(filename);
        end
        
        function exists = get.Exists(obj)
           [exists, info] = fileattrib(obj.Path);
           
           if ~exists
               return;
           end
           
           exists = exists && ~info.directory;
        end
        
        function readable = get.Readable(obj)
           if ~obj.Exists
               readable = false;
               return; % file does not exist
           end
           
           % Check if the file has read permissions
           % by opening the file for reading.
           fid = matlab.internal.fopen(obj.Path, 'r');
           if (fid ~= -1)
               fclose(fid);
           end
           
           readable = (fid ~= -1);
        end
        
        function writeable = get.Writeable(obj)
            filename = obj.Absolute;
            if isempty(filename)
                writeable = false;
                return;
            end
            
            % Test that the file can actually be created.
            % Open it in append mode so that any existing file is not
            % destroyed.
            fileExisted = obj.Exists;
            fid = matlab.internal.fopen(filename, 'a');
            
            writeable = (fid ~= -1);
            
            if (fid ~= -1)
               fclose(fid);
            end
            
            if (~fileExisted && (fid ~= -1))
                delete(filename);
            end
        end
        
        
        function absolutePath = get.Absolute(obj)
            filename = obj.Path;

            % Determine if file exists 
            if (~obj.Exists)
                % File does not exist

                % Break down the path using fileparts
                % Many MATLAB functions assume that any slashes in a file name
                % are really the filesep for the current platform.
                filename = regexprep(obj.Path, '[\/\\]', filesep);
                [pathstr, baseFile, extProvided ] = fileparts(filename);
                
                % An empty pathstr from fileparts means we're in the pwd and need to 
                % resolve the path using folderResolver.
                % (Note this check for empty string will work on both char and string)
                if (pathstr == "")
                    import matlab.unittest.internal.folderResolver;
                    pathstr = folderResolver(".");
                end

                % Now we have a path, so let's see if it actually exists 

                % Path does not exist
                if exist(pathstr,'dir') ~= 7
                    % We can get here if we pass in a filename with a '\' character
                    % which is valid on Linux and Mac.
                    % Check if the file can be opened using fopen.
                    % If the file can be opened, then we have a valid filename
                    % See g1838355 for details
                    fid = matlab.internal.fopen(obj.Path,'w');
                    if fid ~= -1
                        absolutePath = obj.Path;
                        fclose(fid);
                        delete(obj.Path);
                        return;
                    end
                    % Otherwise, we have a non-existent folder in the parent path, so 
                    % return an empty absolute path 
                    absolutePath = [];
                    return;
                end
                
                % Path does exist -- get its fully qualified path
                [isPathExist, pathInfo] = fileattrib(pathstr);
                if isPathExist
                    pathstr = pathInfo.Name;
                end
                
                % Rebuild the fully qualified path as char if it's a string
                absolutePath = fullfile(pathstr,[char(baseFile) char(extProvided)]);

                % Call the builtin to return Unicode compatible absolute path
                absolutePath = matlab.internal.mmGetAbsolutePath(absolutePath);

                % Return string if original filename was string 
                if isstring(filename)
                    absolutePath = string(absolutePath);
                end

            % Else the file DOES already exist
            else
                % get the file attributes
                [status,info] = fileattrib(filename);
                
                if status
                    absolutePath = info.Name;
                    if isstring(filename)
                        absolutePath = string(absolutePath);
                    end
                else
                    absolutePath = filename;
                end
            end 
        end
        
        function obj = set.Extension(obj,ext)
            obj.Extension = ext;
                   
            % strip any leading '.' separators
            % the handy erase function works on both strings and chars
            if strncmp(obj.Extension,'.',1)
                obj.Extension = erase(obj.Extension,'.');
            end
        end
    end
    
end

