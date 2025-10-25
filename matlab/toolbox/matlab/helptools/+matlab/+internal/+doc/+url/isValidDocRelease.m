function valid = isValidDocRelease(release)
    arguments
        release (1,1) string
    end
    valid = matches(release, "R" + digitsPattern(4) + ("a"|"b"));
end