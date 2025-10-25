% Uses readstruct in import the XML fdata from an old style deployment PRJ 
% and replaces all occurances of the PROJECT_ROOT macro
function prjStruct = readPRJStruct(prjFileIn)

    [f, name, ext] = fileparts(prjFileIn); 
    
    f = matlab.internal.deployment.makePathAbsolute(f);

    if isempty(ext)
        % Name only so use '.prj'
        ext = '.prj';
    end
    prjFile = fullfile(f, strcat(name,ext));

    prjStruct = readstruct(prjFile, 'FileType', 'xml', 'DetectTypes', 0).configuration;

    % Remove the PROJECT_PATH macro from the struct
    projectRoot = fileparts(prjFile);
    if isempty(projectRoot)
        % The PRJ was passed in as a file name only, so the project root
        % should be "."
        projectRoot = ".";
    else
        projectRoot = string(projectRoot);
    end
    
    prjStruct = resolvePRJPathInStruct(prjStruct);  

    % Replace all occurances of PROJECT_ROOT macro and unify filesep
    function pstruct = resolvePRJPathInStruct(pstruct)
        fields = fieldnames(pstruct);
        for j=1:length(pstruct)
            for i=1:length(fields)
                val = pstruct(j).(fields{i});
                % Due to the structure of the PRJ and the behaviro of
                % readstruct, sometimes these nested structs come across as
                % sparse struct arrays.  In those cases there are a number
                % of missing elements that we should just skip over
                if ~isa(pstruct(j).(fields{i}),'missing')
                    if isstruct(val)
                        pstruct(j).(fields{i}) = resolvePRJPathInStruct(val);
                    else
                        % We need to make sure that we don't break the
                        % closing tag on XML since there are multiple
                        % places that we insert XML in as a param value
                        pstruct(j).(fields{i}) = ...
                            strrep(...
                                strrep(...
                                    strrep(...
                                        strrep(...
                                            strrep(val,"${PROJECT_ROOT}", projectRoot), ...
                                            "${MATLAB_ROOT}", matlabroot), ...
                                        "\", filesep), ...
                                    "/",filesep), ...
                                "\>","/>");
                    end
                end
            end
        end
    end 

end