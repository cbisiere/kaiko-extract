# kaiko-extract

This bash script allows to extract trade and order book data from [Kaiko](http://kaiko.com) zip files, for selected exchanges and currency pairs. 
Optionally, for each exchange and currency pair selected, daily data files can be concatenated into a single csv file.

## Usage

```
Usage: kaiko_extract.sh [-h] [-i directory] [-o directory] [-t type] 
    [-e exchanges] [-p pairs] [-c] [-z] [-m] [-v] [-d]

where:
    -h, --help           show this help text
    -i, --input-dir      directory where kaiko data are stored
                         (defaults to '.')
    -o, --output-dir     directory where extracted data will be stored
                         (defaults to '.')
    -t, --type           type of data: 'trades', 'book'
                         (defaults to 'trade')
    -e, --exchange       comma-separated list of exchange names
                         (e.g. 'Quoine,Yobit', default to '*')
    -p, --pairs          comma-separated list of currency pairs
                         (e.g. 'ETHUSD,ETHEUR', default to '*')
    -c, --concat-by-pair store data for the same exchange / currency-pair
                         in a single file
    -z, --zip            zip these exchange / currency-pair files
    -m, --manifest       create a manifest file for each exchange / currency
                         pair, containing the name of all the input files
    -v, --verbose        print feedback about what the script is doing
    -d, --debug          print debug information
```

## Example

Assuming Kaiko zip files are located in `$HOME/data/REPO/kaiko`, the following command extracts 
all ETHUSD and ETHEUR trade data for Quoine and Yobit. Trade records are grouped into individual exchange/pair csv files. 
For each exchange/pair, a manifest file is also produced.

```
./kaiko_extract.sh \
  --input-dir=$HOME/data/REPO/kaiko \
  --output-dir=. \
  --type trades \
  --exchange=Quoine,Yobit \
  --pair=ETHUSD,ETHEUR \
  --concat-by-pair \
  --zip \
  --manifest
```

This command creates the following files:

```
Quoine_ETHEUR_trades.csv.gz
Quoine_ETHEUR_trades.manifest
Quoine_ETHUSD_trades.csv.gz
Quoine_ETHUSD_trades.manifest
Yobit_ETHUSD_trades.csv.gz
Yobit_ETHUSD_trades.manifest
```

### Prerequisites

This script requires the following commands: GNU `getopt`, `unzip`, and `gunzip`. 
To compress exchange/pair csv files, `gzip` is also required.

On macOS, GNU getopt may be installed using [brew](https://brew.sh): 

```bash
brew install gnu-getopt
```

### Note on Kaiko zip files

A Kaiko trade file (e.g. `trades_Quoine.zip`) is organized as follows:

```
Quoine
├── BTCAUD
│   ├── 2016_10
│   │   ├── Quoine_BTCAUD_trades_2016_10_04.csv.gz
│   │   ├── Quoine_BTCAUD_trades_2016_10_05.csv.gz
│   │   ├── Quoine_BTCAUD_trades_2016_10_07.csv.gz
│   │   ├── Quoine_BTCAUD_trades_2016_10_10.csv.gz
│   │   ├── Quoine_BTCAUD_trades_2016_10_12.csv.gz
│   │   └── Quoine_BTCAUD_trades_2016_10_14.csv.gz
│   ├── 2016_11
...
```

An individual csv.gz trade file (e.g. `Quoine_BTCAUD_trades_2016_10_12.csv.gz`) contains:

```
id,exchange,symbol,date,price,amount,sell
4311670,qn,btcaud,1476263658000,847.16235,3,true
4311681,qn,btcaud,1476263861000,847.23241,3,true
4311683,qn,btcaud,1476263904000,847.11698,3.4,true
4311685,qn,btcaud,1476263975000,847.14883,3.19268018,true
...
```

A Kaiko book file (e.g. `ob_10_Bithumb.zip`) is organized as follows:

```
Bithumb
├── BCHKRW
│   ├── 2017_08
│   │   ├── Bithumb_BCHKRW_ob_10_2017_08_25.csv.gz
│   │   ├── Bithumb_BCHKRW_ob_10_2017_08_26.csv.gz
│   │   ├── Bithumb_BCHKRW_ob_10_2017_08_27.csv.gz
│   │   ├── Bithumb_BCHKRW_ob_10_2017_08_28.csv.gz
│   │   ├── Bithumb_BCHKRW_ob_10_2017_08_29.csv.gz
│   │   ├── Bithumb_BCHKRW_ob_10_2017_08_30.csv.gz
│   │   └── Bithumb_BCHKRW_ob_10_2017_08_31.csv.gz
...
```

An individual csv.gz book file (e.g. `Bithumb_BCHKRW_ob_10_2017_08_25.csv.gz`) contains:

```
date,type,price,amount
1503674940019,b,724600,0.05
1503674940019,b,724300,0.01
1503674940019,b,723700,4.9925
1503674940019,b,723400,23.8685
1503674940019,b,723100,0.0267
...
```

## Author

* **Christophe Bisière** 

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

