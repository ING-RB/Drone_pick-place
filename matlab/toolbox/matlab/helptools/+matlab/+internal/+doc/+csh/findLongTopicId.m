function mappings = findLongTopicId(helptargets, topicId)
    mappings = struct.empty;
    fields = string(fieldnames(helptargets));
    
    % Trim enough characters off to make sure we find every topic ID that
    % could be a potential match. Topic IDs with the same leading
    % <namelengthmax> characters will be assigned unique suffixes 
    % (e.g. _1, _2, etc.); we need to make sure we match fields containing 
    % those suffixes.
    prefix = extractBefore(matlab.lang.makeValidName(topicId), namelengthmax-6);
    fields = fields(startsWith(fields, prefix));
    
    for i = 1:length(fields)
        fm = helptargets.(fields(i));
        if ~isempty(fm) && isfield(fm, "id") && fm(1).id == topicId
            mappings = fm;
            return;
        end
    end
end