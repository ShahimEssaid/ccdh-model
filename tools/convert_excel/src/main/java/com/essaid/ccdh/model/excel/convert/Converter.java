package com.essaid.ccdh.model.excel.convert;

import org.apache.poi.openxml4j.exceptions.InvalidFormatException;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

public abstract class Converter {

    static final String MODEL_SHEET = "model";
    static final String PACKAGES_SHEET = "packages";
    static final String CONCEPTS_SHEET = "concepts";
    static final String ELEMENTS_SHEET = "elements";
    static final String STRUCTURES_SHEET = "structures";
    static final String V_SELF = "_self_";

    static final String H_PACKAGE = "package";
    static final String H_NAME = "name";
    static final String H_ATTRIBUTE = "attribute";


    static final String[] SHEET_NAMES = {MODEL_SHEET, PACKAGES_SHEET, CONCEPTS_SHEET, ELEMENTS_SHEET, STRUCTURES_SHEET};
    final File excelFile;
    final Path csvDirPath;
    String fileSimpleName;
    Options options;

    Converter(Options options) throws IOException {
        this.options = options;
        excelFile = Paths.get(options.file).toFile().getCanonicalFile();
        fileSimpleName = excelFile.getName();
        int index = fileSimpleName.indexOf('.');
        if (index >= 0){
            fileSimpleName = fileSimpleName.substring(0,index);
        }
        csvDirPath = Paths.get(excelFile.getParent().toString(), fileSimpleName);
        System.out.println("");
    }

    abstract void convert() throws IOException, InvalidFormatException;

    protected int[] getXYSheetSize(Sheet sheet) {
        int[] size = {0, 0};
        int lastRowNum = sheet.getLastRowNum();

        for (int y = 0; y <= lastRowNum; ++y) {
            Row row = sheet.getRow(y);
            if (row == null) continue;
            boolean keep = false;
            int lastCellNum = row.getLastCellNum();
            for (int x = 0; x < lastCellNum; ++x) {
                Cell cell = row.getCell(x);
                if (cell == null) continue;
                String rawValue = cell.getStringCellValue().strip();
                if (rawValue != null && !rawValue.isEmpty()) {
                    size[1] = y;
                    if (size[0] < x) size[0] = x;
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
