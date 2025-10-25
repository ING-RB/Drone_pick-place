function findDocRoot() {
    var docRootMatches = document.location.href.match(/^.*\/help(\/releases\/R20\d\d[ab])?(\/prereleases\/R20\d\d[ab])?/);
    return docRootMatches.length > 0 ? docRootMatches[0] : "/help";
}