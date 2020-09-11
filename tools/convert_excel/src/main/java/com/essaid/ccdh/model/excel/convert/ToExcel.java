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
import org.apache.poi.xssf.usermodel.XSSFCellStyle;
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
                writeSheet(wb, sheet, csvFile);
                ++order;
            }

        }
        excelFile.getParentFile().mkdirs();
        wb.write(new FileOutputStream(excelFile));

    }

    private void writeSheet(XSSFWorkbook wb, Sheet sheet, File csvFile) throws IOException {

        int maxCellIndex = 0;
        CSVParser csvParser = new CSVParser(new FileReader(csvFile), CSVFormat.DEFAULT.withQuoteMode(QuoteMode.ALL));
        List<CSVRecord> csvRecords = csvParser.getRecords();
        int row = 0;
        for (CSVRecord csvRecord : csvRecords) {
            Iterator<String> csvRecordIterator = csvRecord.iterator();
            Row sheetRow = sheet.createRow(row);
            XSSFCellStyle cellStyle = wb.createCellStyle();
            cellStyle.setWrapText(true);
            sheetRow.setRowStyle(cellStyle);
            int cellIndex = 0;
            while (csvRecordIterator.hasNext()) {
                String val = csvRecordIterator.next();
                XSSFCellStyle sytle = wb.createCellStyle();
                sytle.setWrapText(true);
                Cell cell = sheetRow.createCell(cellIndex++, CellType.STRING);
                cell.setCellStyle(sytle);
                cell.setCellValue(val);
            }
            if (cellIndex > maxCellIndex) maxCellIndex = cellIndex;
            row++;
        }
        sheet.createFreezePane(0, 1);
        for (int i = 0; i < maxCellIndex; ++i) {
            sheet.autoSizeColumn(i);
            int colWidth = sheet.getColumnWidth(i);
            if (colWidth > 50 * 256)
                sheet.setColumnWidth(i, 50 * 256);
        }

    }
}
