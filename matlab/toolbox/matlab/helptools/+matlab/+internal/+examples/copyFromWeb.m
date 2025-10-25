function copied = copyFromWeb(component, folder, file, target, compressed)
%

%   Copyright 2022-2023 The MathWorks, Inc.

    release = string(matlab.internal.doc.getDocCenterRelease());

    [~,~,ext] = fileparts(file);
    if strcmpi(ext,".mlx")
	folder = fullfile(folder, replace(computer('arch'),"maca64","maci64"));
    end

    webPath = strrep(fullfile("help","releases",release,"exampledata",component,folder,file),"\","/");

    domain = matlab.internal.doc.getDocCenterDomain;
    if ~endsWith(domain,"/")
        domain = domain + "/";
    end
    url = domain + webPath;

    if compressed
        sf = target;
        url = url + ".zip";
        target = sf + ".zip";
    end

    options = weboptions('Timeout', 20);	
    result = websave(target, url, options);
    copied = endsWith(target,getFileName(result));
    if copied
        if compressed
            unzip(target,sf);
            delete(target);
            target = sf;
        end
        chmodR(target);
    else
        delete(result);
    end

function chmodR(filename)
    fileattrib(filename,"+w");
    if isfolder(filename)
        listing = dir(filename);
        for i = 1:numel(listing)
            str = listing(i).name;
            if ~strcmp(str,".") && ~strcmp(str,"..")
                chmodR(fullfile(filename,listing(i).name));
            end
        end
    end
end

function fileName = getFileName(filename)
    [~,name,ext] = fileparts(filename);
    fileName = strcat(name,ext);
end

end

