package com.essaid.ccdh.model.excel.convert;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.csv.QuoteMode;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Paths;
import java.util.*;

public class ToCsv extends Converter {

    ToCsv(Options options) throws IOException {
        super(options);
    }

    @Override
    void convert() throws IOException, InvalidFormatException {
        XSSFWorkbook wb = new XSSFWorkbook(excelFile);

        for (String name : SHEET_NAMES) {
            Sheet sheet = wb.getSheet(name);
            if (sheet != null) {
                writeCsv(sheet, getXYSheetSize(sheet), excelFile);
            }
        }

        XSSFSheet sheet = wb.getSheet("concepts");
        int[] size = getXYSheetSize(sheet);
    }

    void writeCsv(Sheet sheet, int[] size, File file) throws IOException {
        String sheetName = sheet.getSheetName();

        // find the key columns to have a consistent sort key
        List<Integer> headerIndexes = null;
        switch (sheetName) {

            case MODEL_SHEET:
            case PACKAGES_SHEET:
                headerIndexes = getHeaderIndexes(sheet.getRow(0), new String[]{H_NAME});
                break;
            case ELEMENTS_SHEET:
            case CONCEPTS_SHEET:
                headerIndexes = getHeaderIndexes(sheet.getRow(0), new String[]{H_PACKAGE, H_NAME});
                break;
            case STRUCTURES_SHEET:
                headerIndexes = getHeaderIndexes(sheet.getRow(0), new String[]{H_PACKAGE, H_NAME, H_ATTRIBUTE});
                break;
            default:
                throw new IllegalStateException("Sheet name not recognized:" + sheetName);
        }
        if (headerIndexes == null || headerIndexes.size() == 0) {
            throw new IllegalStateException("Could not find header indexes for sheet:" + sheetName);
        }


        File sheetFile = Paths.get(excelFile.getParent().toString(), fileSimpleName, sheetName + ".csv").toFile();
        sheetFile.getParentFile().mkdirs();

        Map<String, List<String>> rowMap = new TreeMap<>();

        for (int y = 1; y <= size[1]; ++y) {
            Row row = sheet.getRow(y);
            if(!isNotEmpty(row, size[0])){
                continue;
            }
            // build the key and add to the map
            String key = "";
            Iterator<Integer> headerIndexItr = headerIndexes.iterator();

            int index = 0;
            while (headerIndexItr.hasNext()) {
                String value = row.getCell(headerIndexItr.next()).getStringCellValue().strip();
                if (index == 2) {
                    // we have an attribute name, and we need to do some checking to keep sort working
                    // has to start with letter unless V_SELF, and it has to be lower case
                    if (!value.equals(V_SELF)) {
                        if (!Character.isLowerCase(value.charAt(0))) {
                            throw new IllegalStateException("Attribute name does not start with lower character. File:" +
                                    file.toString() + " and sheet name:" +
                                    sheetName + " and sructure: " + key + " and attribute:" + value);
                        }
                    }
                }
                key += value;
                if (headerIndexItr.hasNext()) key += ".";
                ++index;
            }

            List<String> rowList = new ArrayList<>();
            rowMap.put(key, rowList);

            if (isNotEmpty(row, size[1])) {
                for (int x = 0; x <= size[0]; ++x) {
                    Cell cell = row.getCell(x);
                    if (cell == null) {
                        rowList.add("");
                        continue;
                    }
                    CellType type = cell.getCellType();
                    switch (type) {
                        case BLANK:
                            rowList.add("");
                            break;
                        case FORMULA:
                        case STRING:
                            String val = cell.getStringCellValue().strip();
                            rowList.add(val);
                            break;
                        default:
                            throw new IllegalStateException("");
                    }
                }
            }
        }


        FileWriter writer = new FileWriter(sheetFile);
        CSVPrinter printer = new CSVPrinter(writer, CSVFormat.DEFAULT.withQuoteMode(QuoteMode.ALL));
        // header row
        Row headerRow = sheet.getRow(0);
        for(int i = 0; i < size[0]; ++i){
            printer.print(headerRow.getCell(i).getStringCellValue());
        }
        printer.println();
        // later rows
        for(Map.Entry<String, List<String>> rowEntry : rowMap.entrySet()){
            // TODO: comment out this stuff
            //System.out.println("Row with key: "+ rowEntry.getKey() + " and values: "+rowEntry.getValue());
            printer.printRecord(rowEntry.getValue());
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

    List<Integer> getHeaderIndexes(Row row, String[] headers) {
        List<Integer> list = new ArrayList<>();
        short lastCellNum = row.getLastCellNum();
        for (String header : headers) {
            for (int i = 0; i < lastCellNum; ++i) {
                Cell cell = row.getCell(i);
                if (cell != null) {
                    String value = cell.getStringCellValue().strip();
                    if (value.equals(header)) {
                        list.add(i);
                    }
                }
            }
        }

        return list;
    }

}
