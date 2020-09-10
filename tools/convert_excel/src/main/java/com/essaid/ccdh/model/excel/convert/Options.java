package com.essaid.ccdh.model.excel.convert;

import com.beust.jcommander.Parameter;

public class Options {

    public static final String CSV = "csv";
    public static final String EXCEL = "excel";

    @Parameter(names = "--file")
    String file;

    @Parameter(names = "--direction")
    String direction;
}
