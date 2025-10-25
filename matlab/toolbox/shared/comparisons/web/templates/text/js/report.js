/*
 * report.js
 * Javascript functions to support navigation and highlighting in
 * text file comparison reports.
 *
 * Getting the root window is browser dependent.  On some platforms the
 * parent of root is the window, and window.window is window.
 * On other browsers, parent can be undefined.
 *
 * Copyright 2009-2022 The MathWorks, Inc.
 */

/* eslint-disable no-undef */
/* eslint-disable no-unused-vars */
/* eslint-disable camelcase */

function getRootWindow () {
    if (parent) {
        return parent.window;
    } else {
        return window;
    }
}

// Returns true if the current renderer is ICE browser.
function ice () {
    return navigator.__ice_version;
}

// Variable LEFT_FILE must be defined (as a string) in the page which
// includes this file.
function openleft (lineNumber) {
    var rootWindow = getRootWindow();
    rootWindow.sendMessage('openfile', { Side: 'Left', Line: lineNumber });
}

// Variable RIGHT_FILE must be defined (as a string) in the page which
// includes this file.
function openright (lineNumber) {
    var rootWindow = getRootWindow();
    rootWindow.sendMessage('openfile', { Side: 'Right', Line: lineNumber });
}

function openLeftFile () {
    var rootWindow = getRootWindow();
    rootWindow.sendMessage('openfile', { Side: 'Left', Line: -1 });
}

function openRightFile () {
    var rootWindow = getRootWindow();
    rootWindow.sendMessage('openfile', { Side: 'Right', Line: -1 });
}

// Scrolls to the element with the specified "id" property and highlights it.
function scroll (section_id) {
    var section = document.getElementById(section_id);
    setcurrent(section, true);
}

// The currently highlighted node.
var CURRENT_SECTION = null;

function select (section_id) {
    var section = document.getElementById(section_id);
    setcurrent(section, false);
}

// Scrolls to the specified node and highlights it.
// Highlighting occurs only for nodes which have an "id" property starting
//  with the string "diff".
function setcurrent (section, do_scroll) {
    if (CURRENT_SECTION != null) {
        CURRENT_SECTION.classList.remove('selected');
    }

    if (section != null) {
        CURRENT_SECTION = section;
        if (section.id.substring(0, 4) === 'diff') {
            // Don't highlight "top" or "bottom"
            CURRENT_SECTION.classList.add('selected');
        }
        if (do_scroll) {
            scrollToMakeVisible(CURRENT_SECTION);
        }
    } else {
        CURRENT_SECTION = null;
    }
}

// Variable LAST_DIFF_ID must be defined in the page which includes this
// file.  It is a string of the form "diffX", where X is a number, and is the
// highest number of "diff" tag that appears within the body of the page.
// This tells us where to go if the user clicks the "Previous" button when
// already at the top.

// Navigates to the next change in the diff report.
// This is done by incrementing the number in the current section, which
// is assumed to have an "id" string of the form "diff99".
function goNext () {
    if (CURRENT_SECTION != null) {
        var id = CURRENT_SECTION.id;
        if (id === LAST_DIFF_ID) {
            scroll('diff0');
        } else {
            val = parseInt(id.substring(4));
            var newid = 'diff' + (val + 1);
            scroll(newid);
        }
    } else {
    // No current section.  Navigate to the first section.
        scroll('diff0');
    }
}

// Navigates to the previous change in the diff report, using the same
// approach as goNext().
function goPrevious () {
    if (CURRENT_SECTION != null) {
        var id = CURRENT_SECTION.id;
        var val = parseInt(id.substring(4));
        if (val > 0) {
            var newid = 'diff' + (val - 1);
            scroll(newid);
            return;
        }
    }
    // We didn't manage to go up.  Go to the bottom instead.
    scroll(LAST_DIFF_ID);
}

// Makes the specified node visible on the screen, positioning
// it 15% of the way down the window.
function scrollToMakeVisible (section) {
    function scrollTop (top) {
        var win = getRootWindow();
        var x = win.scrollX; // do not scroll horizontally
        win.scrollTo(x, top);
    }

    var windowSize = getRootWindow().innerHeight;
    // Scroll so that the "current" diff starts 15% of the way down
    // the screen.
    var elementOffset = section.getBoundingClientRect().top + getRootWindow().scrollY;
    var restFrameOffset = 0.15 * windowSize;
    scrollTop(elementOffset - restFrameOffset);
}
