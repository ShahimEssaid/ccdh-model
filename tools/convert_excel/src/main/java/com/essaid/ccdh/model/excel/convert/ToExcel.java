package com.essaid.ccdh.model.excel.convert;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import org.apache.commons.csv.QuoteMode;
import org.apache.poi.EmptyFileException;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import javax.swing.*;
import java.io.*;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Iterator;
import java.util.List;

public class ToExcel extends Converter {

    ToExcel(Options options) throws IOException {
        super(options);
    }

    @Override
    void convert() throws IOException, InvalidFormatException {
        XSSFWorkbook wb = null;
        if (excelFile.exists()) {
            try {
                wb = new XSSFWorkbook(new FileInputStream(excelFile));
            } catch (EmptyFileException e) {
                excelFile.delete();
                wb = new XSSFWorkbook();
            }
        } else {
            wb = new XSSFWorkbook();
        }

        int order = 0;
        for (String name : SHEET_NAMES) {
            File csvFile = Paths.get(csvDirPath.toString(), name + ".csv").toFile();
            if (csvFile.exists()) {
                int index = wb.getSheetIndex(name);
                if (index > -1) {
                    wb.removeSheetAt(index);
                }
                Sheet sheet = wb.createSheet(name);
                wb.setSheetOrder(name, order);
                writeSheet(sheet, csvFile);
                ++order;
            }

        }
        excelFile.getParentFile().mkdirs();
        wb.write(new FileOutputStream(excelFile));

    }

    private void writeSheet(Sheet sheet, File csvFile) throws IOException {


        CSVParser csvParser = new CSVParser(new FileReader(csvFile), CSVFormat.DEFAULT.withQuoteMode(QuoteMode.ALL));
        List<CSVRecord> csvRecords = csvParser.getRecords();
        int row = 0;
        for (CSVRecord csvRecord : csvRecords) {
            Iterator<String> csvRecordIterator = csvRecord.iterator();
            Row sheetRow = sheet.createRow(row);
            int cellIndex = 0;
            while (csvRecordIterator.hasNext()) {
                String val = csvRecordIterator.next();
                Cell cell = sheetRow.createCell(cellIndex++, CellType.STRING);
                cell.setCellValue(val);
            }
            row++;
        }
    sheet.createFreezePane(0,1);
    }
}
