package com.essaid.ccdh.model.excel.convert;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.csv.QuoteMode;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFCell;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Iterator;

public class ToCsv extends Converter {

    ToCsv(Options options) {
        super(options);
    }

    @Override
    void convert() throws IOException, InvalidFormatException {
        XSSFWorkbook wb = new XSSFWorkbook(modelFile.toFile());

        for (String name : SHEET_NAMES) {
            Sheet sheet = wb.getSheet(name);
            if (sheet != null) {
                writeCsv(sheet, getSheetSize(sheet));
            }
        }

        XSSFSheet sheet = wb.getSheet("concepts");
        int[] size = getSheetSize(sheet);
        System.out.println("Last row:" + sheet.getLastRowNum());

        System.out.println("Size x:" + size[0]);
        System.out.println("Size y:" + size[1]);
    }

    void writeCsv(Sheet sheet, int[] size) throws IOException {
        String name = sheet.getSheetName();
        FileWriter writer = new FileWriter(Paths.get(options.modelDir, name + ".csv").toFile());
        CSVPrinter printer = new CSVPrinter(writer, CSVFormat.DEFAULT.withQuoteMode(QuoteMode.ALL));

        for (int x = 0; x <= size[0]; ++x) {
            Row row = sheet.getRow(x);
            if (isNotEmpty(row, size[1])) {
                for (int y = 0; y <= size[1]; ++y) {
                    Cell cell = row.getCell(y);
                    if (cell == null) {
                        printer.print("");
                        continue;
                    }
                    CellType type = cell.getCellType();
                    System.out.println("X:" + x + "  Y:" + y);
                    System.out.println(type);
                    switch (type) {
                        case BLANK:
                            printer.print("");
                            break;
                        case FORMULA:
                        case STRING:
                            String val = cell.getStringCellValue().strip();
                            printer.print(val);
                            break;
                        default:
                            throw new IllegalStateException("");
                    }
                }
                printer.println();
            }
        }
        printer.close(true);
    }

    boolean isNotEmpty(Row row, int count) {
        if (row != null) {
            for (int i = 0; i <= count; ++i) {
                Cell cell = row.getCell(i);
                if (cell != null) {
                    if (!cell.getStringCellValue().strip().isEmpty()) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
}
