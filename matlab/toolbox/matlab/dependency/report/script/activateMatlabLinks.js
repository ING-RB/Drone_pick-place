/* Copyright 2020 The MathWorks, Inc. */
if (typeof(window.cefclient)!=="undefined") {
    let links = document.getElementsByClassName("matlab_link");
    for (let link of links) {
        link.style.display = "inline";
    }
}