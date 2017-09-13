# Reconciliator

This is a ruby script written to reconcile financial data.

The results are outputted in an excel workbook with sheets for each transaction type.

## Usage

The bank and accounting data must have headings matching the sample files in the tests.

Run 
```
ruby app.rb /path/to/data
```

The script expects client-records.csv and bank-transactions.csv to be present in the data folder.

The results will be outputted in the same folder as an excel workbook.

