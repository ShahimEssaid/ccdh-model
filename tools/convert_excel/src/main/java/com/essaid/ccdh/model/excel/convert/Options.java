package com.essaid.ccdh.model.excel.convert;

import com.beust.jcommander.Parameter;

public class Options {

    @Parameter(names = "--file")
    String file;

    @Parameter(names = "--direction" )
    String direction;
}
