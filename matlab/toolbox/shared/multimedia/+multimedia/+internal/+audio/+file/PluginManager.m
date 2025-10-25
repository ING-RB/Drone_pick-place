classdef PluginManager < handle
    %PLUGINMANAGER Manage audio file plugins and plugin paths
    %   PluginManager manages a set of audio file I/O 
    %   asyncio device, converter, and filter plugins
    %   and their capabilities.
    %
 
    %   Authors: NH, DT
    %   Copyright 2012-2020 The MathWorks, Inc.
 
    %   IMPLEMENTATION NOTES
    %   PluginManager is a singleton who's lifetime manages the lifetime
    %   of a BI2 file (matlab.internal.audioPluginManager). This BI2 file holds 
    %   an instance of a C++ audio::File::PluginManager.
    %
    %   Note that the use of ~ for the obj parameter in most of the methods
    %   is done on purpose. Most of the methods in this class defer
    %   directly to a BI2 file without using obj.  These methods could
    %   be static, but we want to bind the lifetime of the BI2 data
    %   to the lifetime of this class, so the Singleton pattern was chosen.
    
    properties (Constant, GetAccess='public')
        ErrorPrefix = 'multimedia:audiofile:';
    end
    
    properties (GetAccess='public', SetAccess='private')
        PluginPath       % Full Path to the audio file I/O device plugins
        MLConverter      % Fully qualified path to the MATLAB converter 
        SLConverter      % Fully qualified path to the Simulink converter
        TransformFilter  % FUlly qualified path to the Audio Transform filter
    end
    
    properties (Dependent, GetAccess='public', SetAccess='private')
        ReadableFileTypes   % Cell array of file extensions readable by the plugins
        WriteableFileTypes  % Cell array of file extensions writable by the plugins
    end
    
    
    methods (Access='public')
        function pluginPath = getPluginForRead(~, fileToRead)
            % Filter out unsupported files
            PluginManager.errorIfUnsupportedFile(fileToRead);
            
            % Given a path to an audio file, return the audio file I/O
            % asyncio device plugin to use for reading this file.
            pluginPath = matlab.internal.audioPluginManager('getPluginForRead',fileToRead);
            
            import multimedia.internal.audio.file.PluginManager;
            PluginManager.handlePluginError(pluginPath);
        end
        
        function pluginPath = getPluginForWrite(~,fileToWrite)
            % Given a path to an audio file to write  return the audio file I/O
            % asyncio device plugin to use for writing this type file.
            pluginPath = matlab.internal.audioPluginManager('getPluginForWrite',fileToWrite);

            import multimedia.internal.audio.file.PluginManager;
            PluginManager.handlePluginError(pluginPath);
        end
    end
    
    methods (Static)
        function newException = convertPluginException( exception, identifierBase )
            % Given an exception with an identifier that begins with 
            % PluginManager.ErrorPrefix, convert the identifier of that 
            % exception to an identifier beginning with IdentifierBase.  
            % This is useful for translating exceptions thrown from the 
            % PluginManager into exceptions with an identifier for your 
            % product.
            % 
            % For example:
            %
            %   import multimedia.internal.audio.file.PluginManager;
            %   try 
            %      PluginManager.Instance.getPluginForRead('myfile.wav')
            %   catch exception
            %      % Translate exception for use in audiovideo
            %      exception = PluginManager.convertPluginException(exception, ...
            %          'MATLAB:audiovideo:audioread');
            %      throw(exception);
            %   end
            %
            % NOTE: Exceptions thrown by PluginManager are fully 
            % translated, so clients of this code do NOT need to add 
            % error IDs in their own message catalogs.
            %

            import multimedia.internal.audio.file.PluginManager;
            
            if isempty(strfind(exception.identifier, ...
                    PluginManager.ErrorPrefix))
                
                % Exception is not a 'PluginException' 
                % just pass it back.
                newException = exception;
                return;
            end
            
            % For a plugin exception, the message field contains the value
            % to be filled into the error message hole.
            % Currently, plugin exceptions support only one argument
            if ~isempty(exception.message)
                exception = MException( ...
                                        message( exception.identifier, ...
                                                 exception.message ) );
            else
                exception = MException( ...
                                        message(exception.identifier) );
            end
            
            newException = PluginManager.replacePluginExceptionPrefix(exception, identifierBase);
        end
        
        function newException = replacePluginExceptionPrefix(exception, identifierBase)
            % Given a fully constructed exception that beings with
            % PluginManager.ErrorPrefix, convert the identifier of that 
            % exception to an identifier beginning with IdentifierBase.
            % No message catalog is performed to populate an missing holes
            % in the message unlike the convertPluginException method
            
            import multimedia.internal.audio.file.PluginManager;
            
            if isempty(strfind(exception.identifier, ...
                    PluginManager.ErrorPrefix))
                
                % Exception is not a 'PluginException' 
                % just pass it back.
                newException = exception;
                return;
            end
            
            % Replace the prefix of the plugin exception with the
            % appropriate one from the caller.
            idpartindices = strfind(exception.identifier,':');
            
            lastpart = exception.identifier(idpartindices(end)+1:end);
            newid = [identifierBase ':' lastpart];
            newException = MException(newid, exception.message);
        end
    end
    
    methods % Custom get methods for properties
        
        function fileTypes = get.ReadableFileTypes(~)
            fileTypes = matlab.internal.audioPluginManager('getReadableFileTypes');
            
            import multimedia.internal.audio.file.PluginManager;
            PluginManager.handlePluginError(fileTypes);
        end
        
        function fileTypes = get.WriteableFileTypes(~)
            fileTypes = matlab.internal.audioPluginManager('getWriteableFileTypes');

            import multimedia.internal.audio.file.PluginManager;
            PluginManager.handlePluginError(fileTypes);
        end
        
        function delete(~)
            matlab.internal.audioPluginManager('destroyPluginManager');
        end
    end
    
    methods (Access = 'private')
        function obj = PluginManager
            basePath = toolboxdir(fullfile( ...
                'shared','multimedia',...
                'bin',computer('arch')));
            
            % Initialize plugin paths
            % toolboxdir() above prefixed correctly if deployed.
            obj.PluginPath = fullfile(basePath,'audio');
            obj.MLConverter = fullfile(basePath,'audiomlconverter');
            obj.SLConverter = fullfile(basePath,'audioslconverter');
            obj.TransformFilter = fullfile(basePath,'audiotransformfilter');
            
            %initialize the underlying plugin manager
            matlab.internal.audioPluginManager( 'initializePluginManager', ...
                                   obj.PluginPath, obj.MLConverter, ...
                                   obj.SLConverter, obj.TransformFilter );
        end

    end
    
    methods(Static, Access='private')
        
        function handlePluginError(err)
            if ~isstruct(err)
                return;
            end
            
            import multimedia.internal.audio.file.PluginManager;
            
            % Special case to handle the case when one or more expected
            % plugins are not loaded possibly due to missing third party
            % dependencies.
            
            % Check for the libsndfile case. This is a cross-platform
            % plugin.
            if strcmp(err.Name, 'PluginTypeNotLoaded') && strcmp(err.What, 'CrossPlatform')
                err.Name = 'PluginRequirement';
                err.What = 'libsndfile';
            elseif strcmp(err.Name, 'PluginTypeNotLoaded')
                if ispc
                    err.Name = 'PluginRequirement';
                    err.What = 'Microsoft(R) Media Foundation';
                elseif ~ismac
                    err.Name = 'PluginRequirementAndHigher';
                    err.What = 'Gstreamer 1.0';
                else
                    assert(false, 'Audio Toolbox always available on Mac OS X');
                end
            end
            
            errID = [PluginManager.ErrorPrefix err.Name];
            messageArgs = {errID};
            if (~isempty(err.What))
                messageArgs{end+1} = err.What;
            end
            
            msgObj = message(messageArgs{:});
            
            % An error occurred, throw this as an MException
            throwAsCaller(MException(errID, msgObj.getString)); 
        end
        
        function errorIfUnsupportedFile(fileToRead)           
            import multimedia.internal.audio.file.PluginManager;
            
            [~, ~, fileExt] = fileparts(fileToRead);
            
            % Remove the leading '.' 
            fileExt = fileExt(2:end);            
            
            % Filter out files. See g1375943 for additional information
            PluginManager.errorIfFile(fileExt, mexext);
            
            % Filter out shared libraries. See g2151380 for additional information
            sharedLibExt = feature('GetSharedLibExt');
            % Remove the leading '.'
            sharedLibExt = sharedLibExt(2:end);
            PluginManager.errorIfFile(fileExt, sharedLibExt);
            
            % Filter out pcap files. See g2214323 for additional information
            pcapLibExt = 'pcap';
            PluginManager.errorIfFile(fileExt, pcapLibExt);            
        end
        
        function errorIfFile(fileExt, ext)          
            import multimedia.internal.audio.file.PluginManager;
            if strcmpi(fileExt, ext)
                msgObj = message( [PluginManager.ErrorPrefix, 'FileTypeNotSupported'] );
                throwAsCaller( MException(msgObj.Identifier, getString(msgObj)) );
            end
            
        end
    end
    
    methods(Static, Access='public')
        function instance = getInstance(~)
            % Revert back to using a constant property once g911313 is
            % fixed
            persistent localInstance;
            if isempty(localInstance)
                localInstance = multimedia.internal.audio.file.PluginManager();
            end
            instance = localInstance;
        end
    end
    
   
end

