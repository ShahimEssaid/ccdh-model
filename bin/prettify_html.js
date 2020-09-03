#!/usr/bin/env node

// validate number of arguments
if (process.argv.length < 3) {
    console.error("Missing argument #1: path to HTML file");
    process.exit(1);
}
var filePath = process.argv[2]
// Formatting configuration
var formattingOptions = {
    indent_char: '\t',
    indent_size: 1,
    unformatted: ['code', 'pre', 'em', 'strong'],
    ocd: true,
};
// Read contents of original file
var fs = require("fs");
fs.readFile(filePath, "utf8", function (err, fileContent) {
    if (err) {
        console.error("ERROR: " + err);
        process.exit(1);
    }
    // Prettify HTML
    var pretty = require('pretty');
    var prettifiedHtml = pretty(fileContent, formattingOptions)
    // Write pretty HTML back to file
    fs.writeFile(filePath, prettifiedHtml, (err) => {
        if (err) {
            console.error("ERROR: " + err);
            process.exit(1);
        }
    });
});

