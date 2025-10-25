classdef PluginManager < handle
    %PLUGINMANAGER Manage video file plugins and plugin paths
    %   PluginManager manages a set of video file I/O asyncio device and
    %   converter and their capabilities.
 
    %   Authors: Dinesh Iyer
    %   Copyright 2017-2020 The MathWorks, Inc.
 
    %   IMPLEMENTATION NOTES
    %   PluginManager is a singleton who's lifetime manages the lifetime
    %   of a BI2 file (matlab.internal.videoPluginManager). This BI2 function holds an
    %   instance of a C++ PluginManager.
    %
    %   Note that the use of ~ for the obj parameter in most of the methods
    %   is done on purpose. Most of the methods in this class defer
    %   directly to a BI2 without using obj.  These methods could
    %   be static, but we want to bind the lifetime of the BI2 data with
    %   to the lifetime of this class, so the Singleton pattern was chosen.
    
    properties (Constant, GetAccess='public')
        ErrorPrefix = 'multimedia:videofile:';
    end
    
    properties (GetAccess='public', SetAccess='private')
        PluginPath       % Full Path to the video file I/O device plugins
        MLConverter      % Fully qualified path to the MATLAB converter 
        SLConverter      % Fully qualified path to the Simulink converter
        CoderConverter   % Fully qualified path to the Coder converter
        NullPlugin       % Full qualified path to the Null Plugin
    end
    
    properties (Dependent, GetAccess='public', SetAccess='private')
        ReadableFileTypes   % Cell array of file extensions readable by the plugins
    end
    
    
    methods (Access='public')
        function [devicePluginPath, tsPluginPath, tsInitOptions] = getPluginForRead(~, fileToRead)            
            % Filter out unsupported files
            PluginManager.errorIfUnsupportedFile(fileToRead);
            
            % Given a path to an video file, return the video file I/O
            % asyncio device plugin to use for reading this file.
            devicePluginPath = matlab.internal.videoPluginManager('getPluginForRead',fileToRead);
            
            import matlab.internal.video.PluginManager;
            PluginManager.handlePluginError(devicePluginPath);
            
            % If a valid device plugin was found, then determine the
            % timestamp plugin to be used and any options when creating the
            % Timestamp channel.
            [tsPluginPath, tsInitOptions] = PluginManager.determineTimeStampPlugin(devicePluginPath);
        end
        
        function devicePluginPaths = getAllPluginsForRead(~)
            % Return the path to all device plugins available on the system
            % for reading.
            devicePluginPaths = matlab.internal.videoPluginManager('getAllPluginsForRead');
           
            import matlab.internal.video.PluginManager;
            PluginManager.handlePluginError(devicePluginPaths);
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
            %   import matlab.internal.video.PluginManager;
            %   try 
            %      PluginManager.Instance.getPluginForRead('myfile.avi')
            %   catch exception
            %      % Translate exception for use in audiovideo
            %      exception = PluginManager.convertPluginException(exception, ...
            %          'MATLAB:audiovideo:VideoReader');
            %      throw(exception);
            %   end
            %
            % NOTE: Exceptions thrown by PluginManager are fully 
            % translated, so clients of this code do NOT need to add 
            % error IDs in their own message catalogs.
            %

            import matlab.internal.video.PluginManager;
            
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
            
            import matlab.internal.video.PluginManager;
            
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
        
        function [tsPluginPath, tsInitOptions] = determineTimeStampPlugin(devicePluginPath)
            % The Motion JPEG AVI and Motion JPEG2000 plugins do not have
            % an equivalent time stamp plugin as these plugins do not
            % support variable frame-rate files.
            tsInitOptions = struct();
            if contains(devicePluginPath, 'mj2000') || ...
                    contains(devicePluginPath, 'mjpegavi')
                tsPluginPath = '';
                return;
            end
            
            % The Media Foundation and DirectShow plugins use the same
            % shared library as both the device and the time stamp plugins.
            if contains(devicePluginPath, 'mfreader') || ...
                    contains(devicePluginPath, 'directshow')
                tsPluginPath = devicePluginPath;
                tsInitOptions.PluginMode = 'Counting';
                % This only applies for Media Foundation. Ignored by
                % DirectShow
                tsInitOptions.UseHardwareAcceleration = matlab.internal.video.isHardwareAccelerationUsed();
                return;
            end
            
            % Check if the plugin is either the Gstreamer or AVFoundation
            % plugin. These plugins have the sequence 'gst' and 'avf'
            % respectively.
            devicePluginTypes = {'gst', 'avf'};
            devicePluginTypeSelected = cellfun( @(x) contains(devicePluginPath, x), devicePluginTypes );
            
            if ~any(devicePluginTypeSelected)
                % The test plugin will not be shipped and so this code i.e.
                % TRUE condition will not be hit in shipping code.
                if contains(devicePluginPath, 'videotest')
                    tsPluginPath = insertAfter( devicePluginPath, ...
                                                'failread', ...
                                                'ts' );
                    return;
                else
                    assert(false, 'Unsupported Device Plugin Name');
                end
            end
                
            devicePluginTypeSelected = devicePluginTypes{ devicePluginTypeSelected };
            
            tsPluginPath = insertAfter(devicePluginPath, devicePluginTypeSelected, 'timestamp');
        end
    end
    
    methods % Custom get methods for properties
        
        function fileTypes = get.ReadableFileTypes(~)
            fileTypes = matlab.internal.videoPluginManager('getReadableFileTypes');
            
            import matlab.internal.video.PluginManager;
            PluginManager.handlePluginError(fileTypes);
        end
        
        function delete(~)
            matlab.internal.videoPluginManager('destroyPluginManager');
        end
    end
    
    methods (Access = 'private')
        function obj = PluginManager
            basePath = toolboxdir(fullfile( ...
                'shared','multimedia',...
                'bin',computer('arch')));
            
            % Initialize plugin paths
            % toolboxdir() above prefixed correctly if deployed.
            % This is being done to return the full path to the shared
            % libraries for easy PackNGo.
            sharedLibExt = feature('GetSharedLibExt');
            if ispc
                sharedLibPrefix = '';
            else
                sharedLibPrefix = 'libmw';
            end
            obj.PluginPath = fullfile(basePath,'video');
            obj.MLConverter = fullfile(obj.PluginPath, [sharedLibPrefix 'videoreadermlconverter' sharedLibExt]);
            obj.SLConverter = fullfile(obj.PluginPath, [sharedLibPrefix 'videoreaderslconverter' sharedLibExt]);
            obj.CoderConverter = fullfile(obj.PluginPath, [sharedLibPrefix 'videoreadercoderconverter' sharedLibExt]);
            obj.NullPlugin = fullfile(obj.PluginPath, [sharedLibPrefix 'videofilenullreaderplugin' sharedLibExt]);
                        
            %initialize the underlying plugin manager
            matlab.internal.videoPluginManager( 'initializePluginManager', ...
                                   obj.PluginPath, obj.MLConverter, ...
                                   obj.SLConverter );
        end

    end
    
    methods(Static, Access='private')
        
        function handlePluginError(err)
            if ~isstruct(err)
                return;
            end
            
            import matlab.internal.video.PluginManager;
            
            % Special case to handle the case when one or more expected
            % plugins are not loaded possibly due to missing third party
            % dependencies.
            if strcmp(err.Name, 'PluginTypeNotLoaded')
                if ispc
                    err.Name = 'PluginRequirement';
                    err.What = 'Microsoft(R) Media Foundation/DirectShow';
                elseif ~ismac
                    err.Name = 'PluginRequirementAndHigher';
                    err.What = 'Gstreamer 1.0';
                else
                    assert(false, 'AVFoundation is always available on Mac OS X');
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
            import matlab.internal.video.PluginManager;
            
            [~, ~, fileExt] = fileparts(fileToRead);
            
            % Remove the leading '.' 
            fileExt = fileExt(2:end);            
            
            % Filter out MEX files. See g1375943 for additional information
            PluginManager.errorIfFile(fileExt, mexext);
            
            % Filter out pcap files. See g2214323 for additional information
            pcapLibExt = 'pcap';
            PluginManager.errorIfFile(fileExt, pcapLibExt);            
        end
        
        function errorIfFile(fileExt, ext)          
            import matlab.internal.video.PluginManager;
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
                localInstance = matlab.internal.video.PluginManager();
            end
            instance = localInstance;
        end
    end
    
   
end

