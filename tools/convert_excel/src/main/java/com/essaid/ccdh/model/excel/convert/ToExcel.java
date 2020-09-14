package com.essaid.ccdh.model.excel.convert;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVParser;
import org.apache.commons.csv.CSVRecord;
import org.apache.commons.csv.QuoteMode;
import org.apache.poi.EmptyFileException;
import org.apache.poi.common.usermodel.HyperlinkType;
import org.apache.poi.openxml4j.exceptions.InvalidFormatException;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.*;

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


        XSSFCellStyle defaultStyle = wb.createCellStyle();
        defaultStyle.setWrapText(true);
        defaultStyle.setDataFormat(BuiltinFormats.getBuiltinFormat("text"));


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
                writeSheet(wb, sheet, csvFile, defaultStyle);
                ++order;
            }

        }
        excelFile.getParentFile().mkdirs();
        wb.write(new FileOutputStream(excelFile));

    }

    private void writeSheet(XSSFWorkbook wb, Sheet sheet, File csvFile, XSSFCellStyle defaultStyle) throws IOException {
        XSSFCreationHelper creationHelper = wb.getCreationHelper();

        int maxCellIndex = 0;
        CSVParser csvParser = new CSVParser(new FileReader(csvFile), CSVFormat.DEFAULT.withQuoteMode(QuoteMode.ALL));
        List<CSVRecord> csvRecords = csvParser.getRecords();
        int cols = 0;
        for (CSVRecord record : csvRecords) {
            if (record.size() > cols) cols = record.size();
        }

        for (int i = 0; i < cols; ++i) {
            sheet.setDefaultColumnStyle(i, defaultStyle);
        }

        int row = 0;
        for (CSVRecord csvRecord : csvRecords) {
            Iterator<String> csvRecordIterator = csvRecord.iterator();
            Row sheetRow = sheet.createRow(row);
            int cellIndex = 0;
            while (csvRecordIterator.hasNext()) {
                String val = csvRecordIterator.next();
                Cell cell = sheetRow.createCell(cellIndex++, CellType.STRING);
                cell.setCellValue(val);
                if (val.startsWith("http")) {
                    XSSFHyperlink hyperlink = creationHelper.createHyperlink(HyperlinkType.URL);
                    hyperlink.setAddress(val);
                    cell.setHyperlink(hyperlink);
                }
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
