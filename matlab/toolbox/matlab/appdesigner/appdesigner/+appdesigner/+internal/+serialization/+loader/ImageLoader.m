classdef ImageLoader < appdesigner.internal.serialization.loader.interface.DecoratorLoader
    %IMAGELOADER A class to load apps containing images
    % We need to recalculate the ImageSource and Icon values 
    % in case the MLAPP file was moved.
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties (Access = private)
        FullFileName
    end

    methods
        
        function obj = ImageLoader(loader, fullFileName)
            obj@appdesigner.internal.serialization.loader.interface.DecoratorLoader(loader);
            obj.FullFileName = fullFileName;
        end
        
        function appData = load(obj)
            appData = obj.Loader.load();
            obj.recalculateImageProperty(appData, obj.FullFileName);
        end
    end
    
    methods (Access = 'private')
        
        function appData = recalculateImageProperty(~, olderAppData, fullFileName)
            % updates the ImageSource and Icon property values for 
            % all components containing those properties
            
            appData = olderAppData;
            components = findall(appData.components.UIFigure, '-property', 'ImageSource', '-or', '-property', 'Icon');
            
            % temporarily suppress the warning for invalid ImageSource 
            % values, since the ImageController throws this warning later
            previousWarning = warning('off', 'MATLAB:ui:Image:invalidIconNotInPath');
            cleanup = onCleanup(@()warning(previousWarning));
            
            for idx = 1:length(components)
                if (isprop(components(idx), 'DesignTimeProperties') && ~isfield(components(idx).DesignTimeProperties, 'ImageRelativePath'))
                    components(idx).DesignTimeProperties.ImageRelativePath = '';
                elseif (isprop(components(idx), 'DesignTimeProperties') && ~isempty(components(idx).DesignTimeProperties.ImageRelativePath))
                    filePath = fileparts(fullFileName);
                    imageRelativePath = components(idx).DesignTimeProperties.ImageRelativePath;
                    % update the relative path with the correct separator
                    % for the current OS
                    imageRelativePath = strrep(imageRelativePath, '\', '/');
                    fullPathToImage = fullfile(filePath, imageRelativePath);
                    components(idx).DesignTimeProperties.ImageRelativePath = imageRelativePath;
                    if (isprop(components(idx), 'ImageSource'))
                        % first, set the property to '' so that if the
                        % fullPathToImage is not a valid ImageSource, the
                        % ImageSource value does not point to the outdated
                        % absolute path
                        components(idx).ImageSource = '';
                        components(idx).ImageSource = fullPathToImage;
                    elseif (isprop(components(idx), 'Icon'))
                        % first, set the property to '' so that if the
                        % fullPathToImage is not a valid Icon, the
                        % Icon value does not point to the outdated
                        % absolute path
                        components(idx).Icon = '';
                        components(idx).Icon = fullPathToImage;
                    end
                end
            end
        end
    end
end
