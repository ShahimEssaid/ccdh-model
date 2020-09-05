package com.essaid.ccdh.model.excel.convert;

import com.beust.jcommander.Parameter;

public class Options {

    @Parameter(names = "--model-path")
    String modelDir;

    @Parameter(names = "--direction" )
    String direction;
}
