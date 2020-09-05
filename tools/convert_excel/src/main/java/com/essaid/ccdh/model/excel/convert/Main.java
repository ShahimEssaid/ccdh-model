package com.essaid.ccdh.model.excel.convert;


import com.beust.jcommander.JCommander;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;

import java.io.IOException;

public class Main {
    public static void main(String[] args) throws IOException, InvalidFormatException {
        Options options = new Options();
        JCommander.newBuilder().addObject(options).build().parse(args);
        ToCsv toCsv = new ToCsv(options);
        toCsv.convert();
    }
}
