/*
 * printablereport.js
 * Defines utility functions to create a static printable version of the report.
 *
 * Copyright 2018-2022 The MathWorks, Inc.
 */

/* eslint-disable no-unused-vars */
/* eslint-disable no-undef */
'use strict';

var saveAs = (function () {
    var matlabSaveAs = 'comparisons.internal.web.saveAs';

    function toBase64DataURL (img) {
    // Create an empty canvas element
        var canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;

        // Copy the image contents to the canvas
        var context = canvas.getContext('2d');
        context.drawImage(img, 0, 0);

        // Get the data-URL formatted image
        return canvas.toDataURL('image/png');
    }

    function deepClone (elem) {
        return elem.cloneNode(true);
    }

    function getHTMLToSave () {
        var elementsToRemove =
      ['#leftText', '#rightText', 'script', 'iframe', '#MessageServiceManager'];
        var attributesToRemove = ['onload', 'onclick', 'href'];
        var classesToRemove = ['action', 'merge', 'compare', 'selected'];
        var headItemsToClone = ['meta', 'title', 'style[type*="text/css"]'];

        // Reconstruct the new body
        var newBody = deepClone(document.body);

        elementsToRemove.forEach(function (element) {
            newBody.querySelectorAll(element).forEach(function (elem) { elem.remove(); });
        });
        attributesToRemove.forEach(function (attribute) {
            newBody.querySelectorAll('*[' + attribute + ']').forEach(function (elem) { elem.removeAttribute(attribute); });
        });
        classesToRemove.forEach(function (clazz) {
            newBody.querySelectorAll('.' + clazz).forEach(function (elem) { elem.classList.remove(clazz); });
        });
        newBody.querySelectorAll('img').forEach(function (elem) { elem.src = toBase64DataURL(elem); });

        // Reconstruct the new head
        var newHead = document.createElement('head');
        headItemsToClone.forEach(function (item) {
            document.querySelectorAll(item).forEach(function (elem) {
                newHead.append(deepClone(elem));
            });
        });

        // Reconstruct the new tree
        var newDoc = document.createElement('html');
        newDoc.append(newHead);
        newDoc.append(newBody);

        return '<!DOCTYPE html>' + newDoc.outerHTML;
    }

    function write (filename, contents) {
        var feval = window.MATLAB.feval;
        feval(matlabSaveAs, [ filename, contents ], 0);
    }

    return function (filename) {
        var html = getHTMLToSave();
        write(filename, html);
    };
}());
