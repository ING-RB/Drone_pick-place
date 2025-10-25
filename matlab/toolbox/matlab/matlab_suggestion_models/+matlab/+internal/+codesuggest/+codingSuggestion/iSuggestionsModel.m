classdef (Abstract) iSuggestionsModel < handle
    %ISUGGESTIONMODEL is an interface for implementing a model for the suggestion model
    
    methods (Access = public)
        
        %GETSUGGESTIONS Get the expected suggestion for the suggestion model
        [suggestion, confidence] = getSuggestions(this, featureQueue, leadingCharacters);
        
        %EQ Operator '==' overload for checking object equivalence 
        tf = eq(this, inputModel);

    end

    methods (Access = private)
        
        %TOKENIZEANDCLASSIFY Generate ranked predictions and confidence scores.
        scores = tokenizeAndClassify(this, featureQueue);        
        
        %GETSCORES Get prediction scores for input embeddings
        scores = getScores(this, xEmbeddings);

    end

end

