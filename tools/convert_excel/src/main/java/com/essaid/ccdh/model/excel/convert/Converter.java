package com.essaid.ccdh.model.excel.convert;

import org.apache.poi.openxml4j.exceptions.InvalidFormatException;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;

import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

public abstract class Converter {

    static final String[] SHEET_NAMES = {"model", "packages", "concepts", "elements", "structures"};
    final Path excelFilePath;
    final Path csvDirPath;
    String fileSimpleName;
    Options options;

    Converter(Options options) {
        this.options = options;
        excelFilePath = Paths.get(options.file);
        fileSimpleName = excelFilePath.toFile().getName();
        int index = fileSimpleName.indexOf('.');
        if (index >= 0){
            fileSimpleName = fileSimpleName.substring(0,index);
        }
        csvDirPath = Paths.get(excelFilePath.getParent().toString(), fileSimpleName);
        System.out.println("");
    }

    abstract void convert() throws IOException, InvalidFormatException;

    protected int[] getSheetSize(Sheet sheet) {
        int[] size = {0, 0};
        int lastRowNum = sheet.getLastRowNum();

        for (int x = 0; x <= lastRowNum; ++x) {
            Row row = sheet.getRow(x);
            if (row == null) continue;
            boolean keep = false;
            int lastCellNum = row.getLastCellNum();
            for (int y = 0; y < lastCellNum; ++y) {
                Cell cell = row.getCell(y);
                if (cell == null) continue;
                String rawValue = cell.getStringCellValue().strip();
                if (rawValue != null && !rawValue.isEmpty()) {
                    size[0] = x;
                    if (size[1] < y) size[1] = y;
                }
                CellType type = cell.getCellType();
                switch (type) {
                    case _NONE:
                        break;
                    case BLANK:
                        break;
                    case BOOLEAN:
                        break;
                    case ERROR:
                        break;
                    case FORMULA:
                        break;
                    case NUMERIC:
                        break;
                    case STRING:
                        break;
                    default:
                        break;
                }
            }
        }
        return size;
    }
}
