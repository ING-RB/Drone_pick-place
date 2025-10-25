classdef URLUtils < handle & matlab.ui.internal.componentframework.services.core.identification.IdentificationService
    methods (Static)
        function webForDeployedWebApps(htmlFile)
            % helper to open URLs in Deployed Web Apps Mode
            % Accepts the following:
            %   MATLAB: links
            %   Simply handled by client:
            %     URL - https://www.mathworks.com
            %     MailTo - mailto:email_address
            %   Served by connector
            %     FullFile Path - /foo/bar/mydir/myfile.html
            %     File - which('foo.pdf')
            if isempty(htmlFile)
                warning(message('MATLAB:web:NoURL'));
                return;
            end
            
            % Handle matlab: protocol by passing the command to evalin.
            if startsWith(htmlFile, 'matlab:')
                evalin('caller', htmlFile(8:end));
                return;
            end
            
            url = matlab.ui.internal.URLUtils.parseURL(htmlFile);
            
            % Send URL to deployed web app figure's URLService
            hUIFigure = findall(groot, 'Type', 'figure');
            id = hUIFigure.getId();
            message.publish(['/gbt/figure/URLService/' id], url);
        end
        
        function url = parseURL(htmlFile, downloadable)  
            if(nargin == 1)
                % True unless specified
                downloadable = true;
            end
            
            % Handle URLs
            if (matlab.ui.internal.URLUtils.isURL(htmlFile) || (contains(htmlFile,':') && ~isfile(htmlFile)))
                url = htmlFile;
                return;
            end
            
            % Else handle as file
            % If the file is on MATLAB's search path, get the real filename.
            fullpath = which(htmlFile);
            if isempty(fullpath)
                if isfile(htmlFile)
                    % It is a relative or fullfile path to file 
                    % try relative
                    fullpath = fullfile(pwd,htmlFile);
                    if ~isfile(fullpath)                        
                        fullpath = htmlFile;
                    end                
                else
                    % probably a URL without protocol. add explicit http://
                    url = ['http://' htmlFile];                    
                    return;
                end
            end
            
            % Serve the file using a downloadable static connector URL
            url = matlab.ui.internal.URLUtils.getURLToUserFile(fullpath, downloadable);
        end               
        
        function result = isURL(htmlString)
            % Determines if a string is a (likely) a URL, by looking at its
            % prefixes            
            
            result = startsWith(htmlString, ["www", "http://","https://","ftp://","mailto:","tel:"],'IgnoreCase',true);
        end
        
        function url = getURLToUserFile (fileName, downloadable)
            % getURLToUserFile is a utility that provides a connector based
            % static http path to a given file/folder
            % It optimizes the http routes to return the same routing URL for
            % multiple calls to the same folder.
            
            persistent pathMap;
            if isempty(pathMap)
                pathMap = containers.Map;
            end
            
            if (nargin ~= 2)
                downloadable = false;
            end
           
            % Expected to be a full file path to a file or folder
            folderName = fileName;
            name = '';
            ext = '';
            
            % Find Folder if input is a file.
            if ~isfolder(fileName)
                [folderName,name,ext] = fileparts(fileName);
                % If the file name contains '%' or '#', encode them. First
                % make sure that 'fileName' is still the original file path
                if isfile(fileName)
                    name = strrep(name, '%', '%25');
                    name = strrep(name, '#', '%23');
                end
            end
            if folderName(end) ~= filesep
                folderName = [folderName, filesep];
            end
            
            % g2627897 - Wait for the connector to start
            connector.ensureServiceOn;

            % Create new or access existing http path to given folder.
            if (pathMap.isKey(folderName))
                httpPath = pathMap(folderName);
            else
                httpPath = connector.addStaticContentOnPath(char(matlab.lang.internal.uuid()), folderName);
                pathMap(folderName) = httpPath;
            end
            
            url = [httpPath '/' name ext];
            if (downloadable)
                % Construct url for download
                url = matlab.ui.internal.URLUtils.applyNonceAndCSRFTokenToDownloadURL(url);
            end
        end
        
        % Function to construct download url by prefixing '/download' keyword
        % and appending nonce & csrf token
        % Input: url (url to construct for download)
        % Output: downloadURL (constructed download url)
        %
        % Example: 
        % url = '/static/4mF134oy/1b276cfd-a153-47cd-be9a-79106a62d02a/peppers.png'
        % downloadURL = '/download/static/4mF134oy/1b276cfd-a153-47cd-be9a-
        %        79106a62d02a/peppers.png?snc=Q2KAJA&csrfToken=EJ1RQTLZBT'
        function downloadURL = applyNonceAndCSRFTokenToDownloadURL(url)
            
            % construct URL for download
            downloadURL = ['/download', url, '?snc=',connector.newNonce(), ...
                '&csrfToken=',connector.internal.getCsrfToken()];
        end
    end
end

