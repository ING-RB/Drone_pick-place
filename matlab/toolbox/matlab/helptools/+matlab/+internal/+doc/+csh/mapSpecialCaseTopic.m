function relPath = mapSpecialCaseTopic(shortname, topicId)
    relPath = "";
    if shortname == "simulink"
        switch topicId
            case "while"
                relPath = "slref/whileiterator.html";
            case "discretepulsegenerator"
                relPath = "slref/pulsegenerator.html";
        end
    end
end

