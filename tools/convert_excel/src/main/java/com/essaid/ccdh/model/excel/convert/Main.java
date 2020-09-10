package com.essaid.ccdh.model.excel.convert;


import com.beust.jcommander.JCommander;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;

import java.io.IOException;

public class Main {
    public static void main(String[] args) throws IOException, InvalidFormatException {
        Options options = new Options();
        JCommander.newBuilder().addObject(options).build().parse(args);

        switch (options.direction) {
            case Options.CSV:
                new ToCsv(options).convert();
                break;
            case Options.EXCEL:
                new ToExcel(options).convert();
                break;
            default:
                throw new IllegalStateException("Unexpected value: " + options.direction);
        }

    }
}
